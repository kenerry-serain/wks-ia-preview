# ============================================================
# File    : terraform/01-network-stack/variables.tf
# ADR     : ADR-002 — VPC Network Stack com Public/Private Subnets e Single NAT Gateway
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
# VPC — grouped object covering all VPC sub-resources.
# public_subnets and private_subnets use plural names because they contain
# list(string) for cidr_blocks and availability_zones.
# dns_support_enabled and dns_hostnames_enabled default to true because the
# majority of AWS workloads (RDS, ECS, VPC endpoints) require DNS resolution.
# nat_gateway includes eip_name to allow tagging of the associated Elastic IP.
# ---------------------------------------------------------------------------

variable "vpc" {
  description = "VPC configuration including all related sub-resource names and settings"
  type = object({
    name       = string
    cidr_block = string

    dns_support_enabled   = optional(bool, true)
    dns_hostnames_enabled = optional(bool, true)

    internet_gateway = object({
      name = string
    })

    public_subnets = object({
      name               = string
      cidr_blocks        = list(string)
      availability_zones = list(string)
    })

    private_subnets = object({
      name               = string
      cidr_blocks        = list(string)
      availability_zones = list(string)
    })

    nat_gateway = object({
      name     = string
      eip_name = string
    })

    public_route_table = object({
      name = string
    })

    private_route_table = object({
      name = string
    })
  })
  nullable = false
}
