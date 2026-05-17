# ADR-001: Terraform Remote Backend com S3 e Native State Locking

**Status**: Aceito
**Data**: 2026-05-12
**Decisores**: Time de infraestrutura / DevOps lead

---

## Sumario Executivo

Definir a configuracao do remote backend do Terraform usando S3 para armazenamento do state file e locking nativo via S3 (`use_lockfile = true`). Este ADR especifica a arquitetura, decisoes de seguranca, estrutura de arquivos (conforme convencoes do projeto), e o mapeamento exato de recursos e variaveis.

---

## Contexto

O Terraform precisa de um backend para armazenar seu state file de forma segura, compartilhada e com controle de concorrencia. Sem um remote backend:

1. **State local** e vulneravel a perda (disco local, sem backup automatico).
2. **Sem locking**, dois engenheiros executando `terraform apply` simultaneamente podem corromper o state.
3. **Sem versionamento**, um `terraform apply` destrutivo nao tem rollback do state.

Este e o primeiro recurso de infraestrutura do projeto e funciona como fundacao para toda a stack Terraform subsequente.

### Problema do bootstrap (chicken-and-egg)

O backend S3 precisa existir antes que o Terraform possa usa-lo. Isso cria um problema circular: o Terraform nao pode usar o backend para gerenciar a criacao do proprio backend.

**Solucao adotada**: Criar os recursos do backend em um modulo/workspace separado (`terraform/00-remote-backend-stack/`) com backend local na primeira execucao, e depois migrar o state desse proprio modulo para o backend remoto com `terraform init -migrate-state`. Este e um procedimento unico, executado uma vez.

---

## Decisao

### Arquitetura do Backend

| Componente | Servico AWS | Finalidade |
|---|---|---|
| State storage | S3 Bucket | Armazenar o `terraform.tfstate` |
| State locking | S3 Native Lock (`use_lockfile = true`) | Prevenir execucoes concorrentes via lock file (`.tflock`) |
| Encryption | SSE-S3 (AES-256) | Criptografia at-rest do state file |
| Versionamento | S3 Versioning | Historico e rollback do state |
| Acesso publico | S3 Block Public Access | Bloquear qualquer acesso publico ao bucket |

### Decisao explicita: DynamoDB esta deprecado para state locking

O Terraform deprecou o uso de DynamoDB como mecanismo de state locking no backend S3. O parametro `dynamodb_table` sera removido em versao futura. O mecanismo nativo via S3 (`use_lockfile = true`) e agora a abordagem recomendada pela HashiCorp.

Referencia: https://developer.hashicorp.com/terraform/language/backend/s3

Esta decisao traz os seguintes beneficios:

- **Menos recursos para gerenciar**: elimina a necessidade de provisionar e manter uma tabela DynamoDB.
- **Menor custo**: remove o custo (ainda que minimo) do DynamoDB e simplifica a billing.
- **Mecanismo nativo e recomendado**: o lock file (`.tflock`) e gerenciado diretamente no mesmo bucket S3 do state, usando operacoes atomicas do S3.
- **Permissoes IAM simplificadas**: apenas `s3:GetObject`, `s3:PutObject`, e `s3:DeleteObject` no path do lockfile sao necessarias, sem necessidade de permissoes DynamoDB.
- **Menor superficie de ataque**: um recurso a menos para proteger e auditar.

### Estrutura de Arquivos

O codigo Terraform sera organizado no diretorio `terraform/00-remote-backend-stack/` com a seguinte estrutura, respeitando integralmente as convencoes definidas em `.claude/rules/terraform-naming.md`:

```
terraform/
  00-remote-backend-stack/
    backend.tf                    # Bloco terraform { backend "s3" {} }
    providers.tf                  # Provider AWS com regiao via variavel e default_tags
    variables.tf                  # Todas as declaracoes de variaveis
    outputs.tf                    # Outputs do bucket
    s3.tf                         # Recurso aws_s3_bucket principal
    s3.versioning.tf              # Recurso aws_s3_bucket_versioning
    s3.encryption.tf              # Recurso aws_s3_bucket_server_side_encryption_configuration
    s3.public-access-block.tf     # Recurso aws_s3_bucket_public_access_block
    s3.lifecycle-rules.tf         # Recurso aws_s3_bucket_lifecycle_configuration
    terraform.tfvars              # Valores das variaveis
```

**Total: 10 arquivos**

> **Nota**: Nao ha `locals.tf` neste modulo. Tags cross-cutting (Project, Environment, ManagedBy) sao definidas via `default_tags` no bloco `provider` em `providers.tf`, eliminando a necessidade de `merge(local.common_tags, ...)` em cada recurso.

---

### Detalhamento de Cada Arquivo

#### 1. `backend.tf`

Contem o bloco `terraform` com a configuracao do backend S3. Na primeira execucao (bootstrap), o backend comeca como local. Apos a criacao dos recursos, migra-se para S3.

```hcl
terraform {
  required_version = ">= 1.5.0"

  backend "s3" {
    bucket       = "VALOR-DEFINIDO-APOS-BOOTSTRAP"
    key          = "bootstrap/terraform.tfstate"
    region       = "REGIAO-DEFINIDA-APOS-BOOTSTRAP"
    use_lockfile = true
    encrypt      = true
  }
}
```

> **Nota**: Os valores do bloco `backend` nao aceitam variaveis ou interpolacao do Terraform. Eles devem ser strings literais ou passados via `-backend-config` flags durante `terraform init`. Isso e uma limitacao do Terraform, nao uma violacao da regra de "no hard-coded strings". A recomendacao e usar `-backend-config` com um arquivo `.hcl` separado para cada ambiente.

**Alternativa recomendada com `-backend-config`:**

```hcl
terraform {
  required_version = ">= 1.5.0"

  backend "s3" {}
}
```

Com arquivo `backend.hcl`:

```hcl
bucket       = "nome-do-bucket-tfstate"
key          = "bootstrap/terraform.tfstate"
region       = "us-east-1"
use_lockfile = true
encrypt      = true
```

Executado com: `terraform init -backend-config=backend.hcl`

> **Nota sobre locking nativo**: Com `use_lockfile = true`, o Terraform cria um arquivo `.tflock` no mesmo bucket S3, no path `<key>.tflock` (ex: `bootstrap/terraform.tfstate.tflock`). Este arquivo e gerenciado automaticamente e nao requer nenhuma configuracao adicional.

#### 2. `providers.tf`

```hcl
provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}
```

> **Nota**: Tags cross-cutting sao definidas aqui via `default_tags` e aplicadas automaticamente a todos os recursos que suportam tags. Nao e necessario `locals.tf` nem `merge(local.common_tags, ...)` nos recursos.

#### 3. `variables.tf`

Seguindo a convencao de agrupamento em objetos estruturados:

```hcl
variable "region" {
  description = "AWS region for all resources"
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g., production, staging)"
  type        = string
}

variable "project_name" {
  description = "Project name used for tagging and resource naming"
  type        = string
}

variable "backend" {
  description = "Terraform remote backend configuration for S3 state storage with native S3 locking"
  type = object({
    bucket = object({
      name                 = string
      force_destroy        = optional(bool, false)
      versioning_enabled   = optional(bool, true)
      encryption_algorithm = optional(string, "AES256")
      noncurrent_version_expiration_days = optional(number, 90)
    })
  })
}
```

**Justificativas das decisoes na variavel `backend`:**

- `bucket` e um sub-objeto porque representa o sub-recurso logicamente ligado ao conceito de "backend".
- `force_destroy` com default `false` previne exclusao acidental do bucket com state files.
- `versioning_enabled` com default `true` garante resiliencia por padrao.
- `encryption_algorithm` com default `AES256` (SSE-S3) e a opcao mais simples e sem custo adicional.
- `noncurrent_version_expiration_days` com default `90` evita acumulo indefinido de versoes antigas.
- O locking nativo via S3 (`use_lockfile = true`) e configurado diretamente no bloco `backend` do `backend.tf`, nao como variavel, pois o bloco `backend` nao aceita interpolacao.

#### 4. `outputs.tf`

```hcl
output "this_s3_bucket_arn" {
  description = "ARN of the S3 bucket used for Terraform state storage"
  value       = aws_s3_bucket.this.arn
}

output "this_s3_bucket_id" {
  description = "Name (ID) of the S3 bucket used for Terraform state storage"
  value       = aws_s3_bucket.this.id
}
```

#### 5. `s3.tf`

```hcl
resource "aws_s3_bucket" "this" {
  bucket        = var.backend.bucket.name
  force_destroy = var.backend.bucket.force_destroy

  tags = {
    Name = var.backend.bucket.name
  }

  lifecycle {
    prevent_destroy = true
  }
}
```

> **Nota**: `prevent_destroy = true` e critico aqui. A exclusao acidental do bucket de state e uma das falhas mais graves possiveis em infraestrutura Terraform.

#### 7. `s3.versioning.tf`

```hcl
resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = var.backend.bucket.versioning_enabled ? "Enabled" : "Suspended"
  }
}
```

#### 8. `s3.encryption.tf`

```hcl
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = var.backend.bucket.encryption_algorithm
    }

    bucket_key_enabled = true
  }
}
```

#### 9. `s3.public-access-block.tf`

```hcl
resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```

> **Nota**: Todos os 4 flags sao `true`. Nao existe cenario valido onde um bucket de Terraform state deva ter acesso publico.

#### 10. `s3.lifecycle-rules.tf`

```hcl
resource "aws_s3_bucket_lifecycle_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    id     = "expire-noncurrent-versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = var.backend.bucket.noncurrent_version_expiration_days
    }
  }

  depends_on = [aws_s3_bucket_versioning.this]
}
```

#### 11. `terraform.tfvars`

```hcl
region       = "us-east-1"
environment  = "production"
project_name = "workshop"

backend = {
  bucket = {
    name                 = "workshop-terraform-state2"
    force_destroy        = false
    versioning_enabled   = true
    encryption_algorithm = "AES256"
    noncurrent_version_expiration_days = 90
  }
}
```

---

## Justificativa

### 1. S3 como state storage

S3 e o backend nativo e mais maduro do Terraform para AWS. Oferece durabilidade de 99.999999999% (11 noves), versionamento nativo, encryption at-rest, e integracao direta com IAM para controle de acesso.

### 2. Locking nativo via S3 (`use_lockfile = true`) ao inves de DynamoDB

O Terraform agora suporta locking nativo diretamente no S3 usando a opcao `use_lockfile = true`. Este mecanismo:

- Cria um arquivo `.tflock` no mesmo bucket S3, eliminando a necessidade de um servico adicional (DynamoDB).
- E o mecanismo oficialmente recomendado pela HashiCorp para novas implementacoes.
- O parametro `dynamodb_table` esta deprecado e sera removido em versao futura do Terraform.
- Requer apenas permissoes S3 (`s3:GetObject`, `s3:PutObject`, `s3:DeleteObject`) no path do lockfile, simplificando a politica IAM.
- Reduz custo operacional (elimina DynamoDB) e complexidade arquitetural (um recurso a menos para provisionar, monitorar e proteger).

### 3. SSE-S3 (AES-256) ao inves de SSE-KMS

SSE-S3 e a opcao escolhida como default porque:
- Custo zero adicional (KMS cobra por chamada de API e por chave)
- Atende requisitos de compliance basicos (SOC2, ISO 27001)
- Nao requer gerenciamento de chaves
- O state file nao contem dados de PII ou PHI na maioria dos cenarios

### 4. Lifecycle `prevent_destroy` no bucket S3

O bucket S3 tem `prevent_destroy = true`. A exclusao acidental do bucket de state pode tornar todo o Terraform state inacessivel, exigindo recuperacao manual.

### 5. Versionamento com expiracao de versoes antigas

Versionamento habilitado permite recuperar state files anteriores em caso de corrupcao. A expiracao de versoes nao-atuais apos 90 dias evita crescimento indefinido de custos de storage.

---

## Alternativas Consideradas

### Por que nao Terraform Cloud / HCP Terraform

- **Descartado porque**: Adiciona dependencia de servico externo (SaaS), tem custo a partir de 5 usuarios, e reduz controle sobre onde o state e armazenado. Para equipes que ja estao na AWS, S3 com locking nativo e mais simples, mais barato, e sem vendor lock-in adicional.
- **Quando reconsiderar**: Se o time crescer acima de 10 engenheiros e precisar de features como Sentinel policies, private module registry, ou run triggers integrados.

### Por que nao SSE-KMS com chave gerenciada (CMK)

- **Descartado porque**: Adiciona custo (~$1/mes por chave + $0.03/10k requests), complexidade de gerenciamento (key rotation, key policy), e nao e necessario para o nivel de compliance atual.
- **Quando reconsiderar**: Se o projeto tiver requisitos de HIPAA, FedRAMP, ou se o state contiver dados sensiveis que exijam auditoria de acesso via CloudTrail KMS events.

### Por que nao DynamoDB para state locking (mecanismo deprecado)

- **Descartado porque**: O parametro `dynamodb_table` no backend S3 do Terraform esta oficialmente deprecado e sera removido em versao futura. A HashiCorp recomenda `use_lockfile = true` para novas implementacoes. Manter DynamoDB significaria:
  - Provisionar e gerenciar um recurso adicional desnecessario.
  - Custo adicional (ainda que minimo com PAY_PER_REQUEST).
  - Permissoes IAM adicionais (DynamoDB GetItem, PutItem, DeleteItem).
  - Divida tecnica: necessidade futura de migrar para o mecanismo nativo quando DynamoDB for removido.
- **Quando reconsiderar**: Nunca para novas implementacoes. Apenas projetos legados com DynamoDB existente podem manter ate a migracao para `use_lockfile`.

### Por que nao um unico arquivo `main.tf`

- **Descartado porque**: Viola as convencoes do projeto (`.claude/rules/terraform-naming.md`) e dificulta navegacao, code review, e manutencao a medida que o modulo cresce.
- **Quando reconsiderar**: Nunca, dentro deste projeto.

### Por que nao S3 bucket policy restritiva no bootstrap

- **Descartado nesta fase porque**: O controle de acesso via IAM policies (identity-based) e suficiente para o bootstrap. Adicionar bucket policy agora criaria acoplamento com roles/users especificos que podem nao existir ainda.
- **Quando reconsiderar**: Apos definir a estrategia de IAM do projeto (roles para CI/CD, roles para engenheiros), adicionar um arquivo `s3.bucket-policies.tf` com restricoes explicitas.

---

## Riscos e Trade-offs

| Risco | Mitigacao | Severidade |
|---|---|---|
| Exclusao acidental do bucket S3 | `prevent_destroy = true` + `force_destroy = false` + S3 versioning | Alta (mitigada) |
| State file exposto publicamente | Block Public Access (4 flags) + sem bucket policy publica | Alta (mitigada) |
| State file contem secrets em plain text | SSE-S3 encryption at-rest. Para secrets em runtime, usar `sensitive = true` nos outputs e avaliar ferramentas como SOPS ou Vault | Media (aceita) |
| Lock file (`.tflock`) no mesmo bucket do state | Risco minimo: o lock file e efemero e gerenciado automaticamente pelo Terraform. Se o lock file ficar orfao (ex: crash), pode ser removido manualmente com `terraform force-unlock` | Baixa (aceita) |
| Custo de storage com versionamento | Lifecycle rule expira versoes nao-atuais apos 90 dias | Baixa (mitigada) |
| Bootstrap requer procedimento manual unico | Documentado no procedimento abaixo; executado uma unica vez | Baixa (aceita) |
| Backend block nao aceita variaveis | Usar `-backend-config=backend.hcl` para parametrizar | Baixa (mitigada) |

### Trade-off aceito: complexidade do bootstrap

O procedimento de bootstrap em duas fases (local -> migrar para S3) adiciona um passo manual. A alternativa seria usar um script wrapper ou Terragrunt, mas ambos adicionam dependencias que nao se justificam para um procedimento executado uma unica vez.

---

## Permissoes IAM Necessarias

Para que o backend S3 com locking nativo funcione corretamente, a identity IAM (user ou role) que executa o Terraform precisa das seguintes permissoes no bucket:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject"
      ],
      "Resource": [
        "arn:aws:s3:::NOME-DO-BUCKET/bootstrap/terraform.tfstate",
        "arn:aws:s3:::NOME-DO-BUCKET/bootstrap/terraform.tfstate.tflock"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket"
      ],
      "Resource": "arn:aws:s3:::NOME-DO-BUCKET"
    }
  ]
}
```

> **Nota**: O path do lockfile segue o padrao `<key>.tflock`. O `s3:DeleteObject` no path do lockfile e necessario para que o Terraform libere o lock apos a execucao.

---

## Procedimento de Bootstrap

```bash
# 1. Primeira execucao com backend local
cd terraform/00-remote-backend-stack/
# Comentar o bloco backend "s3" {} em backend.tf (ou usar backend vazio)
terraform init
terraform plan
terraform apply

# 2. Anotar os outputs (bucket name)
terraform output

# 3. Configurar o backend.hcl com os valores dos outputs
# 4. Descomentar/configurar o bloco backend "s3" {} em backend.tf

# 5. Migrar o state para o S3
terraform init -backend-config=backend.hcl -migrate-state

# 6. Confirmar a migracao quando solicitado
# 7. Verificar que o state esta no S3
aws s3 ls s3://NOME-DO-BUCKET/bootstrap/

# 8. Remover o state local (agora redundante)
rm -f terraform.tfstate terraform.tfstate.backup
```

---

## Conformidade com Convencoes do Projeto

Checklist de validacao contra `.claude/rules/terraform-naming.md`:

- [x] Arquivos seguem `<resource>.<sub-resource>.tf` (ex: `s3.versioning.tf`, `s3.public-access-block.tf`)
- [x] Identificadores Terraform usam `_` (underscore), nunca `-` (dash)
- [x] Nomes de recursos nao repetem o tipo (ex: `aws_s3_bucket "this"`, nao `aws_s3_bucket "s3_bucket"`)
- [x] Substantivos singulares para nomes de recursos (`this`, nao `buckets`)
- [x] Zero hard-coded strings em argumentos de recursos
- [x] Variaveis relacionadas agrupadas em `object()` (`var.backend.bucket.name`)
- [x] Toda variavel e output tem `description`
- [x] `tags` posicionado antes de `depends_on` / `lifecycle`
- [x] Outputs seguem `{name}_{type}_{attribute}` (ex: `this_s3_bucket_arn`)
- [x] Booleans com nomes positivos (`versioning_enabled`, nao `versioning_disabled`)
- [x] Arquivos padrao presentes (`variables.tf`, `outputs.tf`, `providers.tf`, `backend.tf`, `terraform.tfvars`)
- [x] `default_tags` configurado no provider com `Project`, `Environment`, `ManagedBy`
- [x] Nenhum uso de `merge(local.common_tags, ...)` — tags cross-cutting via `default_tags`

---

## Proximos Passos

1. **Validar este ADR** com o time e definir regiao AWS e nomes finais dos recursos.
2. **Criar os 10 arquivos** listados na estrutura, seguindo o codigo especificado em cada secao.
3. **Executar o procedimento de bootstrap** (secao acima) para criar os recursos e migrar o state.
4. **Configurar o `backend.hcl`** para uso nos demais modulos Terraform do projeto.
5. **Adicionar `s3.bucket-policies.tf`** apos definir a estrategia de IAM (roles de CI/CD e engenheiros).

---

## Revisao Recomendada

Reavaliar esta decisao quando:

- O time crescer acima de 10 engenheiros (considerar Terraform Cloud para governance).
- Requisitos de compliance exigirem SSE-KMS com CMK (substituir `AES256` por `aws:kms`).
- O projeto adotar multi-account AWS (avaliar backend por account vs backend centralizado).
