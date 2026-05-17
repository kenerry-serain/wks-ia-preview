# ============================================================
# File    : terraform/01-network-stack/vpc.public-route-table.tf
# ADR     : ADR-002 — VPC Network Stack com Public/Private Subnets e Single NAT Gateway
# Author  : DevOps Engineer Agent
# Date    : 2026-05-14
# ============================================================
#
# Routes are defined as separate aws_route resources (not inline route blocks)
# per Terraform AWS provider best practice. Inline routes conflict with
# separately managed aws_route resources and complicate lifecycle management.

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = var.vpc.public_route_table.name
  }
}

resource "aws_route" "public_internet" {
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
  route_table_id         = aws_route_table.public.id
}

resource "aws_route_table_association" "public" {
  count = length(var.vpc.public_subnets.cidr_blocks)

  route_table_id = aws_route_table.public.id
  subnet_id      = aws_subnet.public[count.index].id
}
