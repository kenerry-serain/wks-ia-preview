# ============================================================
# File    : terraform/00-remote-backend-stack/outputs.tf
# ADR     : ADR-001 — Terraform Remote Backend com S3 e Native State Locking
# Author  : DevOps Engineer Agent
# Date    : 2026-05-12
# ============================================================

output "this_s3_bucket_arn" {
  description = "ARN of the S3 bucket used for Terraform state storage"
  value       = aws_s3_bucket.this.arn
}

output "this_s3_bucket_id" {
  description = "Name (ID) of the S3 bucket used for Terraform state storage"
  value       = aws_s3_bucket.this.id
}
