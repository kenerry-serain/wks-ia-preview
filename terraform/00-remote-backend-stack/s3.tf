# ============================================================
# File    : terraform/00-remote-backend-stack/s3.tf
# ADR     : ADR-001 — Terraform Remote Backend com S3 e Native State Locking
# Author  : DevOps Engineer Agent
# Date    : 2026-05-12
# ============================================================

resource "aws_s3_bucket" "this" {
  bucket        = var.backend.bucket.name
  force_destroy = var.backend.bucket.force_destroy

  tags = {
    Name = var.backend.bucket.name
  }

  lifecycle {
    prevent_destroy = true
  }
}
