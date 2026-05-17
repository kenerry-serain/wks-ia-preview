# ============================================================
# File    : terraform/00-remote-backend-stack/backend.tf
# ADR     : ADR-001 — Terraform Remote Backend com S3 e Native State Locking
# Author  : DevOps Engineer Agent
# Date    : 2026-05-12
# ============================================================
#
# NOTE: The backend block does not support variable interpolation (Terraform
# limitation). The recommended approach is to keep this block empty and pass
# all backend configuration via: terraform init -backend-config=backend.hcl
#
# Bootstrap procedure (first-time only):
#   1. Comment out or remove the backend "s3" {} block below
#   2. Run: terraform init && terraform apply
#   3. Create backend.hcl with the values from terraform output
#   4. Restore the backend "s3" {} block
#   5. Run: terraform init -backend-config=backend.hcl -migrate-state

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {}
}
