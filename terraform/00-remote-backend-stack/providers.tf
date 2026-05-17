# ============================================================
# File    : terraform/00-remote-backend-stack/providers.tf
# ADR     : ADR-001 — Terraform Remote Backend com S3 e Native State Locking
# Author  : DevOps Engineer Agent
# Date    : 2026-05-12
# ============================================================

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}
