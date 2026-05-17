# ============================================================
# File    : terraform/01-network-stack/vpc.private-subnets.tf
# ADR     : ADR-002 — VPC Network Stack com Public/Private Subnets e Single NAT Gateway
# Author  : DevOps Engineer Agent
# Date    : 2026-05-14
# ============================================================

resource "aws_subnet" "private" {
  count = length(var.vpc.private_subnets.cidr_blocks)

  availability_zone = var.vpc.private_subnets.availability_zones[count.index]
  cidr_block        = var.vpc.private_subnets.cidr_blocks[count.index]
  vpc_id            = aws_vpc.this.id

  tags = {
    Name = "${var.vpc.private_subnets.name}-${count.index + 1}"
  }
}
