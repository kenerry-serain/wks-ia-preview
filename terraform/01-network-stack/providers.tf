# ============================================================
# File    : terraform/01-network-stack/providers.tf
# ADR     : ADR-002 — VPC Network Stack com Public/Private Subnets e Single NAT Gateway
# Author  : DevOps Engineer Agent
# Date    : 2026-05-14
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
