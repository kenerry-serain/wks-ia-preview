---
name: EKS IP Constraints on /24 VPC
description: Critical IP limitations for EKS on 10.0.0.0/24 VPC - max ~34 pods, no prefix delegation, t3.medium 17 pods/node
type: project
---

EKS cluster on the /24 VPC has severe IP constraints that must be considered for any scaling decisions:
- t3.medium: 3 ENIs, 6 IPs/ENI = 17 max pods per node (default VPC CNI)
- 2 nodes x 17 pods = ~34 pods total cluster capacity
- Private subnets are /26 with 59 usable IPs each
- Prefix delegation is NOT safe on /26 subnets (fragmentation risk)
- EKS control plane consumes 2-4 X-ENI IPs per subnet

**Why:** AWS VPC CNI assigns one VPC IP per pod. The /24 CIDR was chosen for workshop cost/simplicity (ADR-002) but creates a hard ceiling on pod count.

**How to apply:** Any workload planning must account for the ~34 pod limit. If more pods are needed, the options are: (1) add secondary CIDR + custom networking, (2) migrate to IPv6, or (3) expand VPC CIDR. Do NOT enable prefix delegation on these subnets.
