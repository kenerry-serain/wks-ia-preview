# ============================================================
# File    : terraform/01-network-stack/vpc.tf
# ADR     : ADR-002 — VPC Network Stack com Public/Private Subnets e Single NAT Gateway
# Author  : DevOps Engineer Agent
# Date    : 2026-05-14
# ============================================================

resource "aws_vpc" "this" {
  cidr_block           = var.vpc.cidr_block
  enable_dns_hostnames = var.vpc.dns_hostnames_enabled
  enable_dns_support   = var.vpc.dns_support_enabled

  tags = {
    Name = var.vpc.name
  }
}
