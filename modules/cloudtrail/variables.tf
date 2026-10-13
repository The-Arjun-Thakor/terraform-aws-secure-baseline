variable "name_prefix" {
  description = "Prefix for resource names."
  type        = string
}

variable "kms_key_arn" {
  description = "KMS key used to encrypt the trail, the log bucket, the log group and the SNS topic."
  type        = string
}

variable "log_retention_days" {
  description = "CloudWatch log group retention in days."
  type        = number
}

variable "log_expiration_days" {
  description = "Days before CloudTrail files in S3 are deleted."
  type        = number
}

variable "alarm_email" {
  description = "Optional e-mail address subscribed to the alarm topic."
  type        = string
  default     = ""
}
