# ============================================================
# File    : terraform/01-network-stack/vpc.nat-gateway.tf
# ADR     : ADR-002 — VPC Network Stack com Public/Private Subnets e Single NAT Gateway
# Author  : DevOps Engineer Agent
# Date    : 2026-05-14
# ============================================================
#
# Single NAT Gateway placed in public subnet [0] (us-east-1a).
# Trade-off: cost savings (~$32.40/month) accepted over HA per-AZ NAT.
# Both the EIP and NAT Gateway depend on the Internet Gateway being fully
# attached before provisioning, as required by AWS and documented by the
# Terraform AWS provider.

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = var.vpc.nat_gateway.eip_name
  }

  depends_on = [aws_internet_gateway.this]
}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name = var.vpc.nat_gateway.name
  }

  depends_on = [aws_internet_gateway.this]
}
