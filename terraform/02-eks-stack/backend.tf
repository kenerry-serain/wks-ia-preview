# ============================================================
# File    : terraform/02-eks-stack/backend.tf
# ADR     : ADR-003 — EKS Cluster com EC2 Managed Node Group em Private Subnets
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
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  backend "s3" {}
}
