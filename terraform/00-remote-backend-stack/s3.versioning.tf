# ============================================================
# File    : terraform/00-remote-backend-stack/s3.versioning.tf
# ADR     : ADR-001 — Terraform Remote Backend com S3 e Native State Locking
# Author  : DevOps Engineer Agent
# Date    : 2026-05-12
# ============================================================

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = var.backend.bucket.versioning_enabled ? "Enabled" : "Suspended"
  }
}
