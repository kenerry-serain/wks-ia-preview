# ============================================================
# File    : terraform/02-eks-stack/eks.subnet-tags.tf
# ADR     : ADR-003 — EKS Cluster com EC2 Managed Node Group em Private Subnets
# Author  : DevOps Engineer Agent
# Date    : 2026-05-14
# ============================================================

# These tags are applied to the private subnets owned by 01-network-stack using
# aws_ec2_tag resources. This avoids modifying 01-network-stack and keeps the
# EKS-specific tagging lifecycle in this stack. Tags are removed automatically
# if this stack is destroyed.

resource "aws_ec2_tag" "private_subnet_internal_elb" {
  count = length(data.terraform_remote_state.network.outputs.private_subnet_ids)

  resource_id = data.terraform_remote_state.network.outputs.private_subnet_ids[count.index]
  key         = "kubernetes.io/role/internal-elb"
  value       = "1"
}

resource "aws_ec2_tag" "private_subnet_cluster" {
  count = length(data.terraform_remote_state.network.outputs.private_subnet_ids)

  resource_id = data.terraform_remote_state.network.outputs.private_subnet_ids[count.index]
  key         = "kubernetes.io/cluster/${var.eks.cluster_name}"
  value       = "shared"
}
