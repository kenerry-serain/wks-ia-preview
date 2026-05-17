---
name: ADR-002 Network Stack Implementation
description: Session record for VPC network stack implementation on 2026-05-14 — files generated, patterns used, pending commands
type: project
---

ADR-002 (Accepted) implemented on 2026-05-14. Stack directory: terraform/01-network-stack/.

**Why:** Foundation network layer required before any workload stacks (ECS, RDS, ALB) can be built.

**How to apply:** Reference this when implementing stacks that consume VPC outputs (subnet IDs, VPC ID, route table IDs).

## Files generated

- backend.tf — Terraform version constraint + empty S3 backend block
- backend.hcl — S3 backend config: bucket=workshop-terraform-state2, key=01-network-stack/terraform.tfstate, region=us-east-1, use_lockfile=true, encrypt=true
- providers.tf — AWS provider with default_tags (Project, Environment, ManagedBy)
- variables.tf — Cross-cutting top-level vars + single vpc object grouping all sub-resource config
- outputs.tf — 11 outputs: this_vpc_id, this_vpc_cidr_block, public/private subnet IDs and CIDRs, IGW ID, NAT ID and public IP, public/private route table IDs
- vpc.tf — aws_vpc with dns_support and dns_hostnames enabled
- vpc.internet-gateway.tf — aws_internet_gateway
- vpc.public-subnets.tf — 2 aws_subnet (count), map_public_ip_on_launch = true
- vpc.private-subnets.tf — 2 aws_subnet (count), no public IP
- vpc.nat-gateway.tf — aws_eip (domain=vpc) + aws_nat_gateway in public[0] (us-east-1a), both depend_on IGW
- vpc.public-route-table.tf — aws_route_table + aws_route (0.0.0.0/0 -> IGW) + 2 associations (count)
- vpc.private-route-table.tf — aws_route_table + aws_route (0.0.0.0/0 -> NAT) + 2 associations (count)
- terraform.tfvars — All actual values: VPC 10.0.0.0/24, public subnets 10.0.0.0/26 + 10.0.0.64/26, private subnets 10.0.0.128/26 + 10.0.0.192/26

## Deviations from ADR

None. All 13 files match ADR-002 specification exactly.

## Execution instructions (user must run manually)

```
cd terraform/01-network-stack
terraform init -backend-config=backend.hcl
terraform validate
terraform plan
terraform apply
```
