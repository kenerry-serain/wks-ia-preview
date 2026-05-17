# ============================================================
# File    : terraform/01-network-stack/outputs.tf
# ADR     : ADR-002 — VPC Network Stack com Public/Private Subnets e Single NAT Gateway
# Author  : DevOps Engineer Agent
# Date    : 2026-05-14
# ============================================================

output "this_vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.this.id
}

output "this_vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = aws_vpc.this.cidr_block
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "public_subnet_cidr_blocks" {
  description = "List of public subnet CIDR blocks"
  value       = aws_subnet.public[*].cidr_block
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "private_subnet_cidr_blocks" {
  description = "List of private subnet CIDR blocks"
  value       = aws_subnet.private[*].cidr_block
}

output "this_internet_gateway_id" {
  description = "The ID of the Internet Gateway"
  value       = aws_internet_gateway.this.id
}

output "this_nat_gateway_id" {
  description = "The ID of the NAT Gateway"
  value       = aws_nat_gateway.this.id
}

output "this_nat_gateway_public_ip" {
  description = "The public Elastic IP address of the NAT Gateway"
  value       = aws_nat_gateway.this.public_ip
}

output "public_route_table_id" {
  description = "The ID of the public route table"
  value       = aws_route_table.public.id
}

output "private_route_table_id" {
  description = "The ID of the private route table"
  value       = aws_route_table.private.id
}
