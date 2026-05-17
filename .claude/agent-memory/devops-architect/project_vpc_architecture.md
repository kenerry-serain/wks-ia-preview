---
name: VPC Architecture Decision
description: ADR-002 proposes a /24 VPC with 4 /26 subnets, single zonal NAT Gateway, in us-east-1 for workshop project
type: project
---

ADR-002 proposes VPC 10.0.0.0/24 split into 4 equal /26 subnets (2 public + 2 private) across us-east-1a and us-east-1b, with a single zonal NAT Gateway in us-east-1a to save costs.

**Why:** Workshop/learning context where cost savings (~$32.40/mo) outweigh the single-AZ NAT failure risk. The /24 CIDR is intentionally small for the workshop scope.

**How to apply:** When planning future stacks (ECS, RDS, ALB), account for 59 usable IPs per subnet max. Flag if any workload would exceed this (especially EKS). Regional NAT Gateway should be evaluated when Terraform support matures.
