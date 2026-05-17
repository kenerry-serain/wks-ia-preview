# ============================================================
# File    : terraform/02-eks-stack/ecr.tf
# ADR     : ADR-003 — EKS Cluster com EC2 Managed Node Group em Private Subnets
# Author  : DevOps Engineer Agent
# Date    : 2026-05-14
# ============================================================

resource "aws_ecr_repository" "frontend" {
  name                 = var.ecr.frontend.name
  image_tag_mutability = var.ecr.image_tag_mutability
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = var.ecr.scan_on_push
  }

  tags = {
    Name = var.ecr.frontend.name
  }
}

resource "aws_ecr_repository" "backend" {
  name                 = var.ecr.backend.name
  image_tag_mutability = var.ecr.image_tag_mutability
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = var.ecr.scan_on_push
  }

  tags = {
    Name = var.ecr.backend.name
  }
}
