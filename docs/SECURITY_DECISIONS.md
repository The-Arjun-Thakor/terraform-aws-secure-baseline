# Security decisions

Why each control exists, which risk it addresses, and which scanner findings were accepted on purpose. Reviewers (and interviewers) usually care more about the *reasoning* than the code.

## Controls and the risks they address

| Control | Implementation | Risk addressed | ISO/IEC 27001:2022 Annex A theme |
|---|---|---|---|
| Customer-managed KMS key with rotation | `modules/kms` | Data at rest readable if storage is accessed; no control over key usage | 8.24 Use of cryptography |
| Multi-region CloudTrail with log-file validation | `modules/cloudtrail/trail.tf` | No audit trail; logs silently altered after an incident | 8.15 Logging |
| Log bucket: private, versioned, KMS-encrypted, TLS-only, lifecycle, access-logged | `modules/cloudtrail/storage.tf` | Log tampering/deletion, accidental public exposure, data in transit exposure | 8.15 Logging, 5.33 Protection of records |
| Metric-filter alarms (root use, unauthorised calls, console login without MFA, IAM policy changes, CloudTrail changes, S3 bucket policy changes) | `modules/cloudtrail/alarms.tf` | Compromise or misconfiguration goes unnoticed | 8.16 Monitoring activities |
| Password policy (14+ chars, rotation, reuse prevention) | `modules/account_baseline` | Weak or reused credentials | 8.5 Secure authentication |
| MFA-enforcing IAM group and MFA-gated auditor role | `modules/account_baseline` | Stolen password alone is enough to act in the account | 8.5 Secure authentication, 5.15 Access control |
| Read-only auditor role (AWS `SecurityAudit`) | `modules/account_baseline` | Reviewers using over-privileged accounts (least privilege) | 5.15 Access control, 8.2 Privileged access rights |
| Account-wide S3 public access block | `modules/account_baseline` | Accidentally public buckets | 8.3 Information access restriction |
| EBS encryption by default | `modules/account_baseline` | Unencrypted volumes and snapshots | 8.24 Use of cryptography |
| Private-only VPC, deny-all default security group, S3 gateway endpoint | `modules/network` | Unintended internet exposure, permissive default rules | 8.20 Networks security, 8.22 Segregation of networks |
| VPC flow logs to encrypted CloudWatch group | `modules/network` | No network visibility for investigations | 8.15 Logging, 8.16 Monitoring activities |
| GuardDuty | `main.tf` | Known-bad activity (credential abuse, C2 traffic) not detected | 8.16 Monitoring activities |

The mapping is an informal study aid, not a claim of ISO 27001 compliance or certification.

## Accepted scanner findings (documented skips)

No global suppressions are used. Each skip is next to the resource and carries a justification.

| Check | Where | Why it is accepted |
|---|---|---|
| CKV_AWS_109 / 111 / 356 | KMS key policy | A key policy must let the account root administer the key, otherwise the key can become unmanageable. In key policies, `Resource: "*"` means "this key", not every resource. |
| CKV_AWS_18 | S3 access-log bucket | It *is* the log destination; logging it into itself would be recursive. |
| CKV_AWS_145 | S3 access-log bucket | S3 server access log delivery only supports SSE-S3 (AES256), not SSE-KMS. |
| CKV_AWS_144 | Both S3 buckets | Cross-region replication adds cost and complexity beyond a demo baseline. **Production would likely want it** for log durability. |
| CKV2_AWS_62 | Both S3 buckets | Event notifications are not required here. |
| CKV_AWS_252 | CloudTrail | Per-file delivery notifications would produce a message about every 5 minutes. Detection is done with metric-filter alarms instead. |
| CKV2_AWS_3 | GuardDuty | The check expects an AWS Organizations-level configuration; this is a single-account baseline. |

## Deliberate limitations

- **Single account.** A real organisation would use AWS Organizations, Service Control Policies, a dedicated log-archive account and centralised Security Hub / Config.
- **No AWS Config, Security Hub or Inspector.** Natural next steps for configuration compliance and vulnerability management.
- **Local Terraform state.** Production needs a remote backend (S3 with encryption and locking) with restricted access, because state files can contain sensitive values.
- **No workloads.** The VPC has no compute; it shows the secure networking foundation only.
- **Cost.** KMS, CloudTrail storage, CloudWatch logs/alarms and GuardDuty (after its 30-day trial) are billable. Use `terraform plan` to learn at no cost; destroy test deployments.
