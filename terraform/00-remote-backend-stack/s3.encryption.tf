# ============================================================
# File    : terraform/00-remote-backend-stack/s3.encryption.tf
# ADR     : ADR-001 — Terraform Remote Backend com S3 e Native State Locking
# Author  : DevOps Engineer Agent
# Date    : 2026-05-12
# ============================================================

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = var.backend.bucket.encryption_algorithm
    }

    bucket_key_enabled = true
  }
}
