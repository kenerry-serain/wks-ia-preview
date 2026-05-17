# ============================================================
# File    : terraform/02-eks-stack/variables.tf
# ADR     : ADR-003 — EKS Cluster com EC2 Managed Node Group em Private Subnets
# Author  : DevOps Engineer Agent
# Date    : 2026-05-14
# ============================================================

# ---------------------------------------------------------------------------
# Cross-cutting variables — kept as top-level per naming conventions
# ---------------------------------------------------------------------------

variable "region" {
  description = "AWS region for all resources"
  type        = string
  nullable    = false
}

variable "environment" {
  description = "Deployment environment (e.g., production, staging)"
  type        = string
  nullable    = false
}

variable "project_name" {
  description = "Project name used for tagging and resource naming"
  type        = string
  nullable    = false
}

# ---------------------------------------------------------------------------
# Network stack reference — configuration for reading 01-network-stack state
# ---------------------------------------------------------------------------

variable "network_state" {
  description = "Remote state configuration for the 01-network-stack to retrieve VPC and subnet IDs"
  type = object({
    bucket = string
    key    = string
    region = string
  })
  nullable = false
}

# ---------------------------------------------------------------------------
# EKS — grouped object covering cluster, node group, and IAM sub-resources.
#
# cluster_version defaults to "1.32" (latest stable at time of writing).
# endpoint groups the three API server access settings into one sub-object.
# node_group groups all node configuration; scaling is a further sub-object.
# node_role is nested inside node_group as it is a sub-resource of the node group.
# cluster_role is a top-level sub-object because it belongs to the cluster, not the node group.
# disk_size defaults to 20 GB — sufficient for workshop container images.
# capacity_type defaults to ON_DEMAND to avoid Spot interruptions in a learning environment.
# ---------------------------------------------------------------------------

variable "eks" {
  description = "EKS cluster configuration including node group, IAM roles, and endpoint access settings"
  type = object({
    cluster_name    = string
    cluster_version = optional(string, "1.32")

    cluster_role = object({
      name = string
    })

    endpoint = object({
      private_access      = optional(bool, true)
      public_access       = optional(bool, true)
      public_access_cidrs = optional(list(string), ["0.0.0.0/0"])
    })

    node_group = object({
      name           = string
      instance_types = list(string)
      capacity_type  = optional(string, "ON_DEMAND")
      disk_size      = optional(number, 20)

      scaling = object({
        desired_size = number
        min_size     = number
        max_size     = number
      })

      node_role = object({
        name = string
      })
    })
  })
  nullable = false
}

# ---------------------------------------------------------------------------
# ECR — grouped object covering the two application repositories and their
# shared configuration (scanning, tag mutability, lifecycle retention).
#
# frontend and backend are kept as sibling sub-objects because they represent
# two distinct repositories of the same class of resource.
# lifecycle_policy is shared configuration applied identically to both repos.
# image_tag_mutability defaults to MUTABLE to allow the "latest" tag pattern
# common in workshop/CI workflows; change to IMMUTABLE for stricter pipelines.
# ---------------------------------------------------------------------------

variable "ecr" {
  description = "ECR repository configuration for the frontend and backend application images"
  type = object({
    image_tag_mutability = optional(string, "MUTABLE")
    scan_on_push         = optional(bool, true)

    frontend = object({
      name = string
    })

    backend = object({
      name = string
    })

    lifecycle_policy = object({
      max_image_count = optional(number, 30)
    })
  })
  nullable = false
}

# ---------------------------------------------------------------------------
# GitHub Actions — OIDC federation and IAM role for CI/CD pipelines.
#
# repository format: "<owner>/<repo>" (e.g., "my-org/my-repo")
# branch restricts which branch can assume the role via OIDC subject claim.
# oidc_provider_name is the Name tag for the OIDC provider resource.
# role_name is the IAM role name assumed by GitHub Actions.
# policy_name is the inline policy name for ECR push permissions.
# ---------------------------------------------------------------------------

variable "github_actions" {
  description = "GitHub Actions OIDC federation and IAM role configuration for CI/CD ECR push"
  type = object({
    repository         = string
    branch             = optional(string, "main")
    oidc_provider_name = optional(string, "github-actions-oidc")
    role_name          = string
    policy_name        = optional(string, "github-actions-ecr-push")
  })
  nullable = false
}
