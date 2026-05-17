# ============================================================
# File    : terraform/02-eks-stack/outputs.tf
# ADR     : ADR-003 — EKS Cluster com EC2 Managed Node Group em Private Subnets
# Author  : DevOps Engineer Agent
# Date    : 2026-05-14
# ============================================================

output "this_eks_cluster_id" {
  description = "The ID of the EKS cluster"
  value       = aws_eks_cluster.this.id
}

output "this_eks_cluster_name" {
  description = "The name of the EKS cluster"
  value       = aws_eks_cluster.this.name
}

output "this_eks_cluster_endpoint" {
  description = "The endpoint URL for the EKS cluster API server"
  value       = aws_eks_cluster.this.endpoint
}

output "this_eks_cluster_certificate_authority" {
  description = "Base64 encoded certificate data for the EKS cluster"
  value       = aws_eks_cluster.this.certificate_authority[0].data
}

output "this_eks_cluster_security_group_id" {
  description = "The ID of the default security group created by EKS for the cluster"
  value       = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}

output "this_eks_cluster_arn" {
  description = "The ARN of the EKS cluster"
  value       = aws_eks_cluster.this.arn
}

output "this_eks_node_group_id" {
  description = "The ID of the EKS managed node group"
  value       = aws_eks_node_group.this.id
}

output "this_eks_node_group_status" {
  description = "The status of the EKS managed node group"
  value       = aws_eks_node_group.this.status
}

output "this_eks_cluster_role_arn" {
  description = "The ARN of the IAM role used by the EKS cluster"
  value       = aws_iam_role.cluster.arn
}

output "this_eks_node_role_arn" {
  description = "The ARN of the IAM role used by the EKS node group"
  value       = aws_iam_role.node.arn
}

output "frontend_ecr_repository_url" {
  description = "The URL of the ECR repository for the frontend application"
  value       = aws_ecr_repository.frontend.repository_url
}

output "frontend_ecr_repository_arn" {
  description = "The ARN of the ECR repository for the frontend application"
  value       = aws_ecr_repository.frontend.arn
}

output "backend_ecr_repository_url" {
  description = "The URL of the ECR repository for the backend application"
  value       = aws_ecr_repository.backend.repository_url
}

output "backend_ecr_repository_arn" {
  description = "The ARN of the ECR repository for the backend application"
  value       = aws_ecr_repository.backend.arn
}

# ---------------------------------------------------------------------------
# GitHub Actions OIDC outputs
# ---------------------------------------------------------------------------

output "github_oidc_provider_arn" {
  description = "The ARN of the GitHub OIDC Identity Provider"
  value       = aws_iam_openid_connect_provider.github.arn
}

output "github_actions_iam_role_arn" {
  description = "The ARN of the IAM role for GitHub Actions to assume via OIDC"
  value       = aws_iam_role.github_actions.arn
}
