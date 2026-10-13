output "kms_key_arn" {
  description = "ARN of the customer-managed KMS key."
  value       = module.kms.key_arn
}

output "cloudtrail_bucket" {
  description = "S3 bucket that stores CloudTrail logs."
  value       = module.cloudtrail.bucket_name
}

output "cloudtrail_arn" {
  description = "ARN of the multi-region CloudTrail trail."
  value       = module.cloudtrail.trail_arn
}

output "alarm_topic_arn" {
  description = "SNS topic that receives security alarms."
  value       = module.cloudtrail.alarm_topic_arn
}

output "auditor_role_arn" {
  description = "Read-only auditor role. Can only be assumed with MFA."
  value       = module.account_baseline.auditor_role_arn
}

output "mfa_required_group" {
  description = "IAM group whose members are denied everything except MFA setup until they use MFA."
  value       = module.account_baseline.mfa_required_group_name
}

output "vpc_id" {
  description = "ID of the private VPC."
  value       = module.network.vpc_id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets."
  value       = module.network.private_subnet_ids
}
