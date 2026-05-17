# ============================================================
# File    : terraform/01-network-stack/backend.tf
# ADR     : ADR-002 — VPC Network Stack com Public/Private Subnets e Single NAT Gateway
# Author  : DevOps Engineer Agent
# Date    : 2026-05-14
# ============================================================
#
# NOTE: The backend block does not support variable interpolation (Terraform
# limitation). All backend configuration is passed via:
#   terraform init -backend-config=backend.hcl

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
