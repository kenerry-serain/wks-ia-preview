---
name: User monorepo GitOps preference
description: User explicitly chose monorepo GitOps (no separate gitops repo) to keep Claude Agents context unified
type: user
---

The user decided to keep K8s manifests, app source code, and Terraform in a single repo. The primary motivation is leveraging custom Claude Agents that operate on the full codebase. This is a firm decision -- do not suggest splitting into a separate gitops repo unless explicitly asked. Instead, focus on mitigating monorepo trade-offs (commit loops, history pollution).
