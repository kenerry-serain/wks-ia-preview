---
name: Terraform Stack Structure
description: Project uses numbered Terraform stacks (00-, 01-, etc.) with S3 backend and backend.hcl pattern
type: project
---

Project organizes infrastructure in numbered Terraform stacks under `terraform/`:
- `00-remote-backend-stack` — S3 bucket for state (deployed, ADR-001)
- `01-network-stack` — VPC, subnets, NAT/IGW (deployed, ADR-002)
- `02-eks-stack` — EKS cluster with EC2 managed node group (proposed, ADR-003)

**Why:** Numbered prefixes enforce deployment order and dependencies. Each stack has its own `backend.hcl` with key `<stack-name>/terraform.tfstate`. Cross-stack data is shared via `terraform_remote_state` data source.

**How to apply:** Future stacks should follow the pattern `NN-<purpose>-stack/` with sequential numbering. Backend key must match the folder name. Cross-cutting vars (region=us-east-1, environment=production, project_name=workshop) are consistent across all stacks.
