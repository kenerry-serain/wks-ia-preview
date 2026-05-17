# ============================================================
# File    : terraform/01-network-stack/vpc.private-route-table.tf
# ADR     : ADR-002 — VPC Network Stack com Public/Private Subnets e Single NAT Gateway
# Author  : DevOps Engineer Agent
# Date    : 2026-05-14
# ============================================================
#
# A single private route table serves both private subnets because both
# point to the same NAT Gateway. If the architecture migrates to a per-AZ
# NAT Gateway, separate route tables per AZ will be required.

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = var.vpc.private_route_table.name
  }
}

resource "aws_route" "private_nat" {
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this.id
  route_table_id         = aws_route_table.private.id
}

resource "aws_route_table_association" "private" {
  count = length(var.vpc.private_subnets.cidr_blocks)

  route_table_id = aws_route_table.private.id
  subnet_id      = aws_subnet.private[count.index].id
}
