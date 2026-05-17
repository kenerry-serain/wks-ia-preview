# ============================================================
# File    : terraform/02-eks-stack/eks.node-group.iam-role.tf
# ADR     : ADR-003 — EKS Cluster com EC2 Managed Node Group em Private Subnets
# Author  : DevOps Engineer Agent
# Date    : 2026-05-14
# ============================================================

# Three separate policy attachments instead of inline policies allow
# independent management of each permission boundary. The AmazonEKS_CNI_Policy
# is attached here (node role) rather than via IRSA — a simplification
# accepted for workshop scope per ADR-003.

resource "aws_iam_role" "node" {
  name = var.eks.node_group.node_role.name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = var.eks.node_group.node_role.name
  }
}

resource "aws_iam_role_policy_attachment" "node_worker" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "node_cni" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "node_ecr" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node.name
}
