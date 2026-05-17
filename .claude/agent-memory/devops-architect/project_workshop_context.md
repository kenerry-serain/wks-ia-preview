---
name: Workshop project initial context
description: Projeto workshop sem CLAUDE.md - contexto inicial derivado do ADR-001 sobre Terraform remote backend com S3 native locking
type: project
---

Projeto "novo-workshop-com-ia-2" iniciado sem CLAUDE.md, sem codigo Terraform, sem ADRs previos. ADR-001 criado em 2026-05-12 para Terraform remote backend com S3 + native S3 locking (use_lockfile = true). DynamoDB foi explicitamente descartado como mecanismo deprecado.

**Why:** O projeto estava vazio (apenas .claude/rules/ e .mcp.json). Nao ha informacoes confirmadas sobre regiao AWS, escala, compliance, ou equipe. O ADR-001 usa us-east-1 e project_name "workshop" como placeholders no terraform.tfvars.

**How to apply:** Antes de qualquer recomendacao futura, confirmar regiao AWS, escala do time, e requisitos de compliance com o usuario. O CLAUDE.md ainda precisa ser criado para fixar o contexto do projeto. Sempre usar use_lockfile = true (nunca DynamoDB) para state locking em novos backends.
