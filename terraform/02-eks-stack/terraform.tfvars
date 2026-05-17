# ============================================================
# File    : terraform/02-eks-stack/terraform.tfvars
# ADR     : ADR-003 — EKS Cluster com EC2 Managed Node Group em Private Subnets
# Author  : DevOps Engineer Agent
# Date    : 2026-05-14
# ============================================================

region       = "us-east-1"
environment  = "production"
project_name = "workshop"

network_state = {
  bucket = "workshop-terraform-state2"
  key    = "01-network-stack/terraform.tfstate"
  region = "us-east-1"
}

eks = {
  cluster_name    = "workshop-eks"
  cluster_version = "1.32"

  cluster_role = {
    name = "workshop-eks-cluster-role"
  }

  endpoint = {
    private_access      = true
    public_access       = true
    public_access_cidrs = ["0.0.0.0/0"]
  }

  node_group = {
    name           = "workshop-eks-nodes"
    instance_types = ["t3.medium"]
    capacity_type  = "ON_DEMAND"
    disk_size      = 20

    scaling = {
      desired_size = 2
      min_size     = 2
      max_size     = 2
    }

    node_role = {
      name = "workshop-eks-node-role"
    }
  }
}

ecr = {
  image_tag_mutability = "MUTABLE"
  scan_on_push         = true

  frontend = {
    name = "workshop-frontend"
  }

  backend = {
    name = "workshop-backend"
  }

  lifecycle_policy = {
    max_image_count = 30
  }
}

github_actions = {
  repository         = "kenerry-serain/wks-ia-preview"
  branch             = "main"
  oidc_provider_name = "github-actions-oidc"
  role_name          = "workshop-github-actions-role"
  policy_name        = "github-actions-ecr-push"
}
