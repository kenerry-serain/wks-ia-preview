# ============================================================
# File    : terraform/01-network-stack/terraform.tfvars
# ADR     : ADR-002 — VPC Network Stack com Public/Private Subnets e Single NAT Gateway
# Author  : DevOps Engineer Agent
# Date    : 2026-05-14
# ============================================================

region       = "us-east-1"
environment  = "production"
project_name = "workshop"

vpc = {
  name       = "workshop-vpc"
  cidr_block = "10.0.0.0/24"

  dns_support_enabled   = true
  dns_hostnames_enabled = true

  internet_gateway = {
    name = "workshop-igw"
  }

  public_subnets = {
    name               = "workshop-public"
    cidr_blocks        = ["10.0.0.0/26", "10.0.0.64/26"]
    availability_zones = ["us-east-1a", "us-east-1b"]
  }

  private_subnets = {
    name               = "workshop-private"
    cidr_blocks        = ["10.0.0.128/26", "10.0.0.192/26"]
    availability_zones = ["us-east-1a", "us-east-1b"]
  }

  nat_gateway = {
    name     = "workshop-nat"
    eip_name = "workshop-nat-eip"
  }

  public_route_table = {
    name = "workshop-public-rt"
  }

  private_route_table = {
    name = "workshop-private-rt"
  }
}
