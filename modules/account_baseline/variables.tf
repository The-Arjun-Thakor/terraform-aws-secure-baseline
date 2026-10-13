variable "name_prefix" {
  description = "Prefix for resource names."
  type        = string
}

variable "mfa_max_age_seconds" {
  description = "Maximum age of the MFA authentication when assuming the auditor role."
  type        = number
}
