variable "name_prefix" {
  description = "Prefix for resource names."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC."
  type        = string
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks of the private subnets."
  type        = list(string)
}

variable "availability_zones" {
  description = "Availability zones, one per private subnet CIDR."
  type        = list(string)
}

variable "kms_key_arn" {
  description = "KMS key used to encrypt the flow log group."
  type        = string
}

variable "log_retention_days" {
  description = "Retention in days for the flow log group."
  type        = number
}
