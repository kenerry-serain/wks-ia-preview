# ============================================================
# File    : terraform/02-eks-stack/eks.node-group.tf
# ADR     : ADR-003 — EKS Cluster com EC2 Managed Node Group em Private Subnets
# Author  : DevOps Engineer Agent
# Date    : 2026-05-14
# ============================================================

resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = var.eks.node_group.name
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = data.terraform_remote_state.network.outputs.private_subnet_ids
  capacity_type   = var.eks.node_group.capacity_type
  disk_size       = var.eks.node_group.disk_size
  instance_types  = var.eks.node_group.instance_types

  scaling_config {
    desired_size = var.eks.node_group.scaling.desired_size
    max_size     = var.eks.node_group.scaling.max_size
    min_size     = var.eks.node_group.scaling.min_size
  }

  tags = {
    Name = var.eks.node_group.name
  }

  depends_on = [
    aws_iam_role_policy_attachment.node_worker,
    aws_iam_role_policy_attachment.node_cni,
    aws_iam_role_policy_attachment.node_ecr,
  ]
}
