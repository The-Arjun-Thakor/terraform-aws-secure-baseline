provider "aws" {
  region = var.region

  default_tags {
    tags = local.common_tags
  }
}

data "aws_caller_identity" "current" {}

locals {
  name_prefix = "${var.project}-${var.environment}"

  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# Fail early with a clear message if the inputs are inconsistent.
resource "terraform_data" "input_validation" {
  lifecycle {
    precondition {
      condition     = length(var.availability_zones) == length(var.private_subnet_cidrs)
      error_message = "availability_zones and private_subnet_cidrs must have the same number of entries."
    }

    precondition {
      condition     = alltrue([for az in var.availability_zones : startswith(az, var.region)])
      error_message = "Every availability zone must belong to the selected region (for example eu-central-1a for eu-central-1)."
    }
  }
}

# Customer-managed key used to encrypt logs, log groups and the alarm topic.
module "kms" {
  source = "./modules/kms"

  name        = "${local.name_prefix}-logs"
  description = "Encrypts CloudTrail logs, CloudWatch log groups and SNS alarms for ${local.name_prefix}"
}

# Account-level hardening: password policy, MFA enforcement group,
# MFA-gated read-only auditor role, S3 public access block, EBS default encryption.
module "account_baseline" {
  source = "./modules/account_baseline"

  name_prefix         = local.name_prefix
  mfa_max_age_seconds = var.mfa_max_age_seconds
}

# Tamper-evident audit trail + detective alarms.
module "cloudtrail" {
  source = "./modules/cloudtrail"

  name_prefix         = local.name_prefix
  kms_key_arn         = module.kms.key_arn
  log_retention_days  = var.log_retention_days
  log_expiration_days = var.trail_log_expiration_days
  alarm_email         = var.alarm_email
}

# Private network with flow logs and no direct internet path.
module "network" {
  source = "./modules/network"

  name_prefix          = local.name_prefix
  vpc_cidr             = var.vpc_cidr
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
  kms_key_arn          = module.kms.key_arn
  log_retention_days   = var.log_retention_days
}

# Managed threat detection (analyses CloudTrail, VPC flow and DNS logs).
resource "aws_guardduty_detector" "this" {
  # checkov:skip=CKV2_AWS_3:Single-account baseline; the check expects an AWS Organizations-level GuardDuty configuration.

  count = var.enable_guardduty ? 1 : 0

  enable                       = true
  finding_publishing_frequency = "FIFTEEN_MINUTES"
}
