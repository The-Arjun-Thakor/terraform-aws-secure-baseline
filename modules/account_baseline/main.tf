data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
}

# ---------------------------------------------------------------------------
# Authentication hygiene
# ---------------------------------------------------------------------------
resource "aws_iam_account_password_policy" "this" {
  minimum_password_length        = 14
  require_lowercase_characters   = true
  require_uppercase_characters   = true
  require_numbers                = true
  require_symbols                = true
  allow_users_to_change_password = true
  max_password_age               = 90
  password_reuse_prevention      = 24
}

# Members of this group can sign in and set up MFA, but everything else is
# denied until they authenticate with MFA. Attach people to the group instead
# of attaching permissions directly to users.
data "aws_iam_policy_document" "require_mfa" {
  statement {
    sid    = "DenyAllExceptMfaSetupWhenNoMfa"
    effect = "Deny"

    not_actions = [
      "iam:ChangePassword",
      "iam:CreateVirtualMFADevice",
      "iam:EnableMFADevice",
      "iam:GetAccountPasswordPolicy",
      "iam:GetUser",
      "iam:ListMFADevices",
      "iam:ListVirtualMFADevices",
      "iam:ResyncMFADevice",
      "sts:GetSessionToken",
    ]

    resources = ["*"]

    condition {
      test     = "BoolIfExists"
      variable = "aws:MultiFactorAuthPresent"
      values   = ["false"]
    }
  }
}

resource "aws_iam_policy" "require_mfa" {
  name        = "${var.name_prefix}-require-mfa"
  description = "Denies all actions except MFA self-service when the session was not authenticated with MFA."
  policy      = data.aws_iam_policy_document.require_mfa.json
}

resource "aws_iam_group" "mfa_required" {
  name = "${var.name_prefix}-mfa-required"
}

resource "aws_iam_group_policy_attachment" "mfa_required" {
  group      = aws_iam_group.mfa_required.name
  policy_arn = aws_iam_policy.require_mfa.arn
}

# ---------------------------------------------------------------------------
# Least-privilege, MFA-gated read-only auditor role
# ---------------------------------------------------------------------------
data "aws_iam_policy_document" "auditor_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.account_id}:root"]
    }

    condition {
      test     = "Bool"
      variable = "aws:MultiFactorAuthPresent"
      values   = ["true"]
    }

    condition {
      test     = "NumericLessThan"
      variable = "aws:MultiFactorAuthAge"
      values   = [tostring(var.mfa_max_age_seconds)]
    }
  }
}

resource "aws_iam_role" "auditor" {
  name                 = "${var.name_prefix}-security-auditor"
  description          = "Read-only access for security reviews. Requires a recent MFA authentication."
  assume_role_policy   = data.aws_iam_policy_document.auditor_trust.json
  max_session_duration = 3600
}

resource "aws_iam_role_policy_attachment" "auditor_security_audit" {
  role       = aws_iam_role.auditor.name
  policy_arn = "arn:aws:iam::aws:policy/SecurityAudit"
}

# ---------------------------------------------------------------------------
# Account-wide guardrails
# ---------------------------------------------------------------------------
resource "aws_s3_account_public_access_block" "this" {
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Every new EBS volume in this region is encrypted, even if a user forgets.
resource "aws_ebs_encryption_by_default" "this" {
  enabled = true
}
