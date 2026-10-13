output "bucket_name" {
  description = "Name of the CloudTrail log bucket."
  value       = aws_s3_bucket.trail.id
}

output "trail_arn" {
  description = "ARN of the trail."
  value       = aws_cloudtrail.this.arn
}

output "alarm_topic_arn" {
  description = "ARN of the SNS topic that receives alarms."
  value       = aws_sns_topic.alarms.arn
}
