# ============================================================
# File    : terraform/02-eks-stack/iam.github-actions-role.tf
# ADR     : ADR-004 — OIDC Provider + IAM Role para GitHub Actions
# Author  : DevOps Engineer Agent
# Date    : 2026-05-17
# ============================================================

resource "aws_iam_role" "github_actions" {
  name = var.github_actions.role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_actions.repository}:ref:refs/heads/${var.github_actions.branch}"
          }
        }
      }
    ]
  })

  tags = {
    Name = var.github_actions.role_name
  }
}

resource "aws_iam_role_policy" "github_actions_ecr" {
  name = var.github_actions.policy_name
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowECRAuth"
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowECRPush"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage"
        ]
        Resource = [
          aws_ecr_repository.backend.arn,
          aws_ecr_repository.frontend.arn
        ]
      }
    ]
  })
}
