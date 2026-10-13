variable "region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "eu-central-1"
}

variable "project" {
  description = "Short project name. Used as a prefix for resource names (lowercase letters, digits, hyphens)."
  type        = string
  default     = "secure-baseline"

  validation {
    condition     = can(regex("^[a-z0-9-]{3,24}$", var.project))
    error_message = "project must be 3-24 characters: lowercase letters, digits and hyphens only."
  }
}

variable "environment" {
  description = "Environment name, e.g. dev, staging, prod."
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.20.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr must be a valid CIDR block."
  }
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets (one per availability zone). The VPC intentionally has no internet gateway."
  type        = list(string)
  default     = ["10.20.1.0/24", "10.20.2.0/24"]
}

variable "availability_zones" {
  description = "Availability zones for the private subnets, one per entry in private_subnet_cidrs. Set explicitly (not auto-discovered) so plans stay stable if AWS adds a new zone."
  type        = list(string)
  default     = ["eu-central-1a", "eu-central-1b"]
}

variable "log_retention_days" {
  description = "Retention in days for CloudWatch log groups. Must be a value CloudWatch supports (e.g. 90, 180, 365)."
  type        = number
  default     = 365
}

variable "trail_log_expiration_days" {
  description = "Days before CloudTrail log files in S3 are deleted (they move to Glacier after 90 days)."
  type        = number
  default     = 730

  validation {
    condition     = var.trail_log_expiration_days > 90
    error_message = "trail_log_expiration_days must be greater than 90 (the Glacier transition)."
  }
}

variable "mfa_max_age_seconds" {
  description = "Maximum age of the MFA authentication when assuming the auditor role."
  type        = number
  default     = 3600
}

variable "alarm_email" {
  description = "Optional e-mail address that receives security alarm notifications. Leave empty to create the alarms without a subscription."
  type        = string
  default     = ""
}

variable "enable_guardduty" {
  description = "Enable Amazon GuardDuty threat detection in this region (30-day free trial, then billed)."
  type        = bool
  default     = true
}
