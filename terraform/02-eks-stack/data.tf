# ============================================================
# File    : terraform/02-eks-stack/data.tf
# ADR     : ADR-003 — EKS Cluster com EC2 Managed Node Group em Private Subnets
# Author  : DevOps Engineer Agent
# Date    : 2026-05-14
# ============================================================

# Reads VPC ID and subnet IDs from the 01-network-stack remote state.
# This is a unidirectional dependency: 02-eks-stack reads from 01-network-stack,
# but 01-network-stack has no knowledge of 02-eks-stack.
data "terraform_remote_state" "network" {
  backend = "s3"

  config = {
    bucket = var.network_state.bucket
    key    = var.network_state.key
    region = var.network_state.region
  }
}
