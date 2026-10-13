output "auditor_role_arn" {
  description = "ARN of the MFA-gated read-only auditor role."
  value       = aws_iam_role.auditor.arn
}

output "mfa_required_group_name" {
  description = "Name of the IAM group that enforces MFA."
  value       = aws_iam_group.mfa_required.name
}
