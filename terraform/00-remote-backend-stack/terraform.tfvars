# ============================================================
# File    : terraform/00-remote-backend-stack/terraform.tfvars
# ADR     : ADR-001 — Terraform Remote Backend com S3 e Native State Locking
# Author  : DevOps Engineer Agent
# Date    : 2026-05-12
# ============================================================

region       = "us-east-1"
environment  = "production"
project_name = "workshop"

backend = {
  bucket = {
    name                               = "workshop-terraform-state2"
    force_destroy                      = false
    versioning_enabled                 = true
    encryption_algorithm               = "AES256"
    noncurrent_version_expiration_days = 90
  }
}
