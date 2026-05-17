# ============================================================
# File    : terraform/02-eks-stack/eks.tf
# ADR     : ADR-003 — EKS Cluster com EC2 Managed Node Group em Private Subnets
# Author  : DevOps Engineer Agent
# Date    : 2026-05-14
# ============================================================

resource "aws_eks_cluster" "this" {
  name     = var.eks.cluster_name
  version  = var.eks.cluster_version
  role_arn = aws_iam_role.cluster.arn

  vpc_config {
    subnet_ids              = data.terraform_remote_state.network.outputs.private_subnet_ids
    endpoint_private_access = var.eks.endpoint.private_access
    endpoint_public_access  = var.eks.endpoint.public_access
    public_access_cidrs     = var.eks.endpoint.public_access_cidrs
  }

  tags = {
    Name = var.eks.cluster_name
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster
  ]
}
