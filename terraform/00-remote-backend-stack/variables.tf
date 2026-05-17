# ============================================================
# File    : terraform/00-remote-backend-stack/variables.tf
# ADR     : ADR-001 — Terraform Remote Backend com S3 e Native State Locking
# Author  : DevOps Engineer Agent
# Date    : 2026-05-12
# ============================================================

# ---------------------------------------------------------------------------
# Cross-cutting variables — kept as top-level per naming conventions
# ---------------------------------------------------------------------------

variable "region" {
  description = "AWS region for all resources"
  type        = string
  nullable    = false
}

variable "environment" {
  description = "Deployment environment (e.g., production, staging)"
  type        = string
  nullable    = false
}

variable "project_name" {
  description = "Project name used for tagging and resource naming"
  type        = string
  nullable    = false
}

# ---------------------------------------------------------------------------
# Backend — grouped object covering S3 bucket sub-resource.
# State locking uses the native S3 mechanism (use_lockfile = true) configured
# directly in the backend block; no DynamoDB table is needed or provisioned.
# ---------------------------------------------------------------------------

variable "backend" {
  description = "Terraform remote backend configuration for S3 state storage with native S3 locking"
  type = object({
    bucket = object({
      name                               = string
      force_destroy                      = optional(bool, false)
      versioning_enabled                 = optional(bool, true)
      encryption_algorithm               = optional(string, "AES256")
      noncurrent_version_expiration_days = optional(number, 90)
    })
  })
  nullable = false
}
