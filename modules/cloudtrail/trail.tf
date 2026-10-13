resource "aws_cloudwatch_log_group" "trail" {
  name              = "/aws/cloudtrail/${var.name_prefix}"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn
}

data "aws_iam_policy_document" "trail_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "trail_to_cloudwatch" {
  statement {
    effect    = "Allow"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.trail.arn}:*"]
  }
}

resource "aws_iam_role" "trail_to_cloudwatch" {
  name               = "${var.name_prefix}-cloudtrail-to-cloudwatch"
  assume_role_policy = data.aws_iam_policy_document.trail_assume.json
}

resource "aws_iam_role_policy" "trail_to_cloudwatch" {
  name   = "write-to-cloudwatch-logs"
  role   = aws_iam_role.trail_to_cloudwatch.id
  policy = data.aws_iam_policy_document.trail_to_cloudwatch.json
}

resource "aws_cloudtrail" "this" {
  # checkov:skip=CKV_AWS_252:Per-file delivery notifications would send a message about every 5 minutes. Detection is handled by metric-filter alarms (alarms.tf) instead.

  name                          = local.trail_name
  s3_bucket_name                = aws_s3_bucket.trail.id
  is_multi_region_trail         = true
  include_global_service_events = true
  enable_log_file_validation    = true
  kms_key_id                    = var.kms_key_arn
  cloud_watch_logs_group_arn    = "${aws_cloudwatch_log_group.trail.arn}:*"
  cloud_watch_logs_role_arn     = aws_iam_role.trail_to_cloudwatch.arn

  depends_on = [
    aws_s3_bucket_policy.trail,
    aws_iam_role_policy.trail_to_cloudwatch,
  ]
}
