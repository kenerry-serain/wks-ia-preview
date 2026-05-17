# ============================================================
# File    : terraform/02-eks-stack/iam.oidc-provider.tf
# ADR     : ADR-004 — OIDC Provider + IAM Role para GitHub Actions
# Author  : DevOps Engineer Agent
# Date    : 2026-05-17
# ============================================================

data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com/.well-known/openid-configuration"
}

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github.certificates[0].sha1_fingerprint]

  tags = {
    Name = var.github_actions.oidc_provider_name
  }
}
