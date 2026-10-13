# Terraform AWS Secure Baseline

Infrastructure-as-code for a hardened AWS account foundation: encryption, audit logging, detective alarms, MFA enforcement, least-privilege access and a private network. The code is modular, scanned with **Checkov**, and ships with a **GitHub Actions** pipeline that checks formatting, validates the configuration and runs the security scan on every change.

## What it builds

```text
                        +---------------------------+
                        |  KMS key (rotation on)    |  encrypts everything below
                        +-------------+-------------+
                                      |
   +----------------------+-----------+------------+--------------------------+
   |                      |                        |                          |
+--v---------------+  +---v----------------+  +----v---------------+  +-------v--------+
| CloudTrail        |  | CloudWatch log     |  | SNS alarm topic    |  | VPC flow logs  |
| multi-region,     |->| group + 5 metric   |->| (optional e-mail)  |  | (encrypted)    |
| log validation    |  | filters + alarms   |  +--------------------+  +-------+--------+
+---------+---------+  +--------------------+                                  |
          |                                                          +---------v---------+
+---------v---------+      +-------------------------+               | Private VPC       |
| S3 log bucket     |      | Account baseline        |               | no internet GW    |
| private, versioned|      | password policy, MFA    |               | deny-all default  |
| TLS-only, lifecycle      | group, MFA-gated        |               | SG, S3 endpoint   |
| + access-log bucket      | auditor role, S3 public |               +-------------------+
+-------------------+      | block, EBS encryption   |
                           +-------------------------+
                  GuardDuty (optional) watches the account
```

| Module | Purpose |
|---|---|
| `modules/kms` | Customer-managed key with annual rotation and a tightly scoped key policy |
| `modules/cloudtrail` | Tamper-evident multi-region trail, hardened log buckets, 6 security alarms |
| `modules/account_baseline` | Password policy, MFA-enforcing group, MFA-gated read-only auditor role, S3 public-access block, EBS default encryption |
| `modules/network` | Private-only VPC, locked-down default security group, S3 gateway endpoint, encrypted flow logs |

See [`docs/SECURITY_DECISIONS.md`](docs/SECURITY_DECISIONS.md) for the reasoning behind each control and the scanner findings that were accepted on purpose.

## Verification status (read this)

| Check | Status |
|---|---|
| All `.tf` files parse as valid HCL | Done |
| Module inputs/outputs and variable references cross-checked | Done |
| **Checkov security scan** | **183 passed, 0 failed, 11 skipped** (each skip justified inline) |
| `terraform fmt`, `terraform validate`, `terraform plan` | **Not run by the author.** Terraform could not be installed where this was built. The CI workflow runs them on your first push. |

If CI reports a formatting difference, run `terraform fmt -recursive` and commit the result. If `terraform validate` reports an error, fix it and learn from it. That is normal workflow, and being able to talk about it is part of the value of the project.

## Prerequisites

- Terraform >= 1.5 and the AWS provider ~> 5.0
- For a real deployment: an AWS account (use a **sandbox account**, never one with production workloads) and credentials configured locally (`aws configure` or SSO)
- For scanning only: `pip install checkov`. No AWS account is needed.

## Usage

```bash
# 0. Scan without any AWS account
pip install checkov
checkov --config-file .checkov.yaml

# 1. Configure
cp terraform.tfvars.example terraform.tfvars   # edit region, AZs, alarm_email

# 2. Format, initialise, validate (no AWS credentials needed for these)
terraform fmt -recursive
terraform init
terraform validate

# 3. See exactly what would be created (reads your account, creates nothing)
terraform plan -out tfplan

# 4. Deploy (only if you want to - see cost note)
terraform apply tfplan

# 5. Clean up when finished
terraform destroy
```

**Cost note.** The KMS key, CloudTrail storage, CloudWatch logs/alarms and GuardDuty (after its 30-day trial) are billable, although usage in an empty sandbox is small. Set `enable_guardduty = false` to avoid GuardDuty charges. `terraform plan` is free and already demonstrates the project.

**Destroy note.** The log buckets are versioned, so `terraform destroy` fails while objects remain; empty the buckets first (including old versions). The KMS key is scheduled for deletion with a 30-day waiting period by design.

## Try the controls

After deploying to a sandbox you can prove they work:

- Assume the auditor role without MFA and observe the denial; then with MFA and observe success.
- Run `aws s3api put-bucket-acl ... --acl public-read` on any bucket and observe the account-level block.
- Check the CloudTrail bucket: `aws s3 ls` it, then try to read with a plain `http://` request and see the TLS-only policy deny it.
- Trigger the unauthorised-API-calls alarm by calling an action your user is not allowed to perform several times.

## Design choices worth explaining in an interview

- **Why explicit availability zones instead of auto-discovery?** A Checkov rule flagged that discovered zone lists can change when AWS adds a zone, which would reshuffle subnets and force replacement. Explicit values keep plans stable.
- **Why a bucket policy with `aws:SourceArn`?** It prevents the "confused deputy" problem: another account's CloudTrail cannot write into this bucket.
- **Why are some checks skipped?** Because blindly satisfying a scanner is not security. Every skip has a written justification.
- **What would you change for production?** Remote encrypted state, multi-account structure with SCPs, cross-region log replication, AWS Config and Security Hub, and least-privilege roles for the CI pipeline using OIDC instead of long-lived keys.

## Project structure

```text
main.tf  variables.tf  outputs.tf  versions.tf
modules/
  kms/  cloudtrail/  account_baseline/  network/
docs/SECURITY_DECISIONS.md
.checkov.yaml
.github/workflows/terraform-ci.yml
terraform.tfvars.example
```
