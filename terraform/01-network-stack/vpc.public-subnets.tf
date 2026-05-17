# ============================================================
# File    : terraform/01-network-stack/vpc.public-subnets.tf
# ADR     : ADR-002 — VPC Network Stack com Public/Private Subnets e Single NAT Gateway
# Author  : DevOps Engineer Agent
# Date    : 2026-05-14
# ============================================================

resource "aws_subnet" "public" {
  count = length(var.vpc.public_subnets.cidr_blocks)

  availability_zone       = var.vpc.public_subnets.availability_zones[count.index]
  cidr_block              = var.vpc.public_subnets.cidr_blocks[count.index]
  map_public_ip_on_launch = true
  vpc_id                  = aws_vpc.this.id

  tags = {
    Name = "${var.vpc.public_subnets.name}-${count.index + 1}"
  }
}
