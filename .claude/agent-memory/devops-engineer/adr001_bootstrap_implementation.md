---
name: ADR-001 Bootstrap Implementation
description: Implementation record for ADR-001 Terraform remote backend with S3 native locking (no DynamoDB) in infra/bootstrap/
type: project
---

## 2026-05-12 — Implementation: ADR-001 Terraform Remote Backend com S3 e Native State Locking (revision 2)

- Files generated: infra/bootstrap/backend.tf, providers.tf, variables.tf, outputs.tf, locals.tf, s3.tf, s3.versioning.tf, s3.encryption.tf, s3.public-access-block.tf, s3.lifecycle-rules.tf, terraform.tfvars
- ADR implemented: ADR-001 (updated — DynamoDB removed, use_lockfile = true adopted)
- Deviations from ADR: None.
- Problems found: No CLAUDE.md exists in the project root. Context derived from ADR-001 content and prior memory.
- Pending items: User must create backend.hcl after first apply and run migrate-state. S3 bucket policy (s3.bucket-policies.tf) deferred per ADR — to be added after IAM strategy is defined.
- Changes vs revision 1: dynamodb.tf deleted; variable `backend.dynamodb_table` removed from variables.tf; DynamoDB outputs removed from outputs.tf; terraform.tfvars dynamodb_table block removed; all file headers updated to new ADR title.
- Execution instructions (in order):
    1. cd infra/bootstrap/
    2. Comment out the `backend "s3" {}` block in backend.tf for the first run (local state)
    3. terraform init
    4. terraform plan
    5. terraform apply
    6. terraform output  # note bucket name
    7. Create backend.hcl:
         bucket       = "<output: this_s3_bucket_id>"
         key          = "bootstrap/terraform.tfstate"
         region       = "us-east-1"
         use_lockfile = true
         encrypt      = true
    8. Restore `backend "s3" {}` block in backend.tf
    9. terraform init -backend-config=backend.hcl -migrate-state
    10. Confirm migration when prompted
    11. aws s3 ls s3://workshop-terraform-state2/bootstrap/  # verify state and .tflock path
    12. rm -f terraform.tfstate terraform.tfstate.backup

**Why:** ADR-001 was updated to remove DynamoDB as locking mechanism (deprecated by HashiCorp) in favour of native S3 locking via use_lockfile = true.
**How to apply:** In future sessions, there is no DynamoDB table in bootstrap. backend.hcl uses use_lockfile = true, not dynamodb_table.
