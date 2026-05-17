---
description: Enforces Terraform naming conventions, file structure, and variable organization based on terraform-best-practices.com/naming
globs: ["**/*.tf", "**/*.tfvars"]
alwaysApply: true
---

# Terraform Naming & Structure Conventions

This rule MUST be followed for ALL Terraform code in this project. No exceptions.

---

## 1. File Naming Convention

File names MUST follow the pattern `<resource>.<sub-resource>.tf` using dots as separators and lowercase with dashes for multi-word names.

### Pattern

```
<main-resource>.tf                          # Main resource file
<main-resource>.<sub-resource>.tf           # Sub-resource file
<main-resource>.<sub-resource>.<detail>.tf  # Detailed sub-resource file
```

### Examples

```
vpc.tf
vpc.public-subnets.tf
vpc.private-subnets.tf
vpc.internet-gateway.tf
vpc.nat-gateway.tf
vpc.public-route-table.tf
vpc.private-route-table.tf
ec2.tf
ec2.security-groups.tf
ec2.key-pairs.tf
rds.tf
rds.subnet-groups.tf
rds.parameter-groups.tf
ecs.tf
ecs.task-definitions.tf
ecs.services.tf
ecs.load-balancer.tf
s3.tf
s3.bucket-policies.tf
s3.lifecycle-rules.tf
lambda.tf
lambda.iam-roles.tf
lambda.event-sources.tf
```

### Standard files (always present)

```
variables.tf        # All variable declarations
outputs.tf          # All output declarations
providers.tf        # Provider configuration
backend.tf          # Backend configuration
locals.tf           # Local values
data.tf             # Shared data sources (data sources specific to a resource go in that resource's file)
terraform.tfvars    # Variable values
```

---

## 2. General Naming Rules

- ALWAYS use `_` (underscore) in Terraform identifiers (resource names, variable names, outputs, locals, data sources)
- ALWAYS use lowercase letters and numbers only
- NEVER use `-` (dash) in Terraform identifiers — dashes are ONLY for file names and cloud resource name values
- NEVER repeat the resource type in the resource name
  - CORRECT: `resource "aws_route_table" "public" {}`
  - WRONG: `resource "aws_route_table" "public_route_table" {}`
- ALWAYS use singular nouns for resource and data source names
- Use `this` as the name when there is only one resource of that type in the module and no more descriptive name is available

---

## 3. No Hard-Coded Strings

NEVER hard-code string values directly in resource arguments. ALWAYS use variables or locals.

### WRONG

```hcl
resource "aws_vpc" "this" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name        = "my-vpc"
    Environment = "production"
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "my-igw"
  }
}
```

### CORRECT

```hcl
resource "aws_vpc" "this" {
  cidr_block = var.vpc.cidr_block

  tags = {
    Name = var.vpc.name
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = var.vpc.internet_gateway_name
  }
}
```

> **Note**: Cross-cutting tags like `Environment`, `Project`, and `ManagedBy` MUST be defined in `default_tags` inside the `provider` block (see section 10), NOT repeated in each resource's `tags`. Only resource-specific tags (like `Name`) go in the resource's `tags` block.

---

## 4. Variable Grouping — Related Variables MUST Be Nested

Related variables MUST be grouped into a single structured variable using `object()` type. Do NOT create separate flat variables for resources that are logically related.

### WRONG — Flat unrelated variables

```hcl
variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "internet_gateway_name" {
  description = "Name of the Internet Gateway"
  type        = string
}

variable "public_route_table_name" {
  description = "Name of the public route table"
  type        = string
}

variable "private_subnet_name" {
  description = "Name of the private subnet"
  type        = string
}
```

### CORRECT — Grouped structured variable

```hcl
variable "vpc" {
  description = "VPC configuration including all related sub-resource names and settings"
  type = object({
    name       = string
    cidr_block = string

    internet_gateway = object({
      name = string
    })

    public_subnets = object({
      name              = string
      cidr_blocks       = list(string)
      availability_zones = list(string)
    })

    private_subnets = object({
      name              = string
      cidr_blocks       = list(string)
      availability_zones = list(string)
    })

    nat_gateway = object({
      name = string
    })

    public_route_table = object({
      name = string
    })

    private_route_table = object({
      name = string
    })
  })
}
```

### Usage in terraform.tfvars

```hcl
vpc = {
  name       = "main-vpc"
  cidr_block = "10.0.0.0/16"

  internet_gateway = {
    name = "main-igw"
  }

  public_subnets = {
    name              = "public"
    cidr_blocks       = ["10.0.1.0/24", "10.0.2.0/24"]
    availability_zones = ["us-east-1a", "us-east-1b"]
  }

  private_subnets = {
    name              = "private"
    cidr_blocks       = ["10.0.10.0/24", "10.0.11.0/24"]
    availability_zones = ["us-east-1a", "us-east-1b"]
  }

  nat_gateway = {
    name = "main-nat"
  }

  public_route_table = {
    name = "public-rt"
  }

  private_route_table = {
    name = "private-rt"
  }
}
```

### More grouping examples

```hcl
# ECS grouped variable
variable "ecs" {
  description = "ECS cluster configuration and related resources"
  type = object({
    cluster_name = string

    service = object({
      name          = string
      desired_count = number
      cpu           = number
      memory        = number
    })

    task_definition = object({
      family         = string
      container_name = string
      container_port = number
      image          = string
    })

    load_balancer = object({
      name                = string
      target_group_name   = string
      health_check_path   = string
    })
  })
}

# RDS grouped variable
variable "rds" {
  description = "RDS instance configuration and related resources"
  type = object({
    identifier     = string
    engine         = string
    engine_version = string
    instance_class = string

    subnet_group = object({
      name = string
    })

    parameter_group = object({
      name   = string
      family = string
    })
  })
}
```

### Grouping rule — when to nest vs. keep separate

- Variables that describe the SAME logical resource or its sub-resources → NEST inside one `object()`
- Variables that are truly cross-cutting (e.g., `environment`, `region`, `project_name`, `default_tags`) → keep as separate top-level variables

```hcl
# Cross-cutting variables — these stay as top-level
variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "project_name" {
  description = "Project name used for tagging"
  type        = string
}

variable "default_tags" {
  description = "Default tags applied to all resources"
  type        = map(string)
  default     = {}
}
```

---

## 5. Variable Declaration Rules

- ALWAYS include a `description` for every variable
- Place variable arguments in this order: `description`, `type`, `default`, `validation`
- Use `list(...)` or `map(...)` types → variable name MUST be plural
- Use positive boolean names: `encryption_enabled` NOT `encryption_disabled`
- Set `nullable = false` for variables that should never accept null
- Match variable names and descriptions to the provider's official Argument Reference when applicable

### Example

```hcl
variable "security_groups" {
  description = "List of security group configurations"
  type = list(object({
    name        = string
    description = string
    ingress_rules = list(object({
      from_port   = number
      to_port     = number
      protocol    = string
      cidr_blocks = list(string)
    }))
  }))
}
```

---

## 6. Resource Argument Ordering

Inside every resource block, follow this order:

1. `count` or `for_each` (first argument, followed by a blank line)
2. Regular arguments (alphabetical or logical grouping)
3. `tags` — only resource-specific tags (e.g., `Name`); cross-cutting tags come from `default_tags` in the provider (followed by a blank line)
4. `depends_on`
5. `lifecycle`

### Example

```hcl
resource "aws_instance" "this" {
  count = var.create_instance ? 1 : 0

  ami           = var.ec2.ami
  instance_type = var.ec2.instance_type
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name = var.ec2.name
  }

  depends_on = [aws_internet_gateway.this]

  lifecycle {
    create_before_destroy = true
  }
}
```

> Cross-cutting tags (`Environment`, `Project`, `ManagedBy`) are automatically applied via `default_tags` in the provider block. Do NOT repeat them in individual resources.

---

## 7. Output Naming Convention

Follow the pattern: `{name}_{type}_{attribute}`

- `{name}` — the resource's logical name (e.g., `public`, `private`, `this`)
- `{type}` — the resource type without provider prefix (e.g., `subnet`, `vpc`, `instance`)
- `{attribute}` — the specific attribute (e.g., `id`, `arn`, `name`)

### Examples

```hcl
output "this_vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_arns" {
  description = "List of private subnet ARNs"
  value       = aws_subnet.private[*].arn
}
```

- ALWAYS include `description` for every output
- If the returned value is a list, use a plural name
- Prefer `try()` over `element(concat(...))`

---

## 8. Conditional Logic

When using `count` / `for_each` with conditions, prefer boolean values:

### CORRECT

```hcl
count = var.create_vpc ? 1 : 0
```

### WRONG

```hcl
count = length(var.vpc_id) > 0 ? 0 : 1
```

---

## 9. Default Tags via Provider

Cross-cutting tags MUST be defined in `default_tags` inside the `provider` block in `providers.tf`. This eliminates the need for `merge(local.common_tags, ...)` in every resource and ensures consistency.

### WRONG — Using locals and merge for common tags

```hcl
# locals.tf
locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# s3.tf
resource "aws_s3_bucket" "this" {
  bucket = var.backend.bucket.name

  tags = merge(local.common_tags, {
    Name = var.backend.bucket.name
  })
}
```

### CORRECT — Using default_tags in the provider

```hcl
# providers.tf
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

# s3.tf — only resource-specific tags
resource "aws_s3_bucket" "this" {
  bucket = var.backend.bucket.name

  tags = {
    Name = var.backend.bucket.name
  }
}
```

### Rules

- `default_tags` MUST include at minimum: `Project`, `Environment`, `ManagedBy`
- Individual resources MUST only define resource-specific tags (typically `Name`)
- NEVER use `merge(local.common_tags, ...)` — `default_tags` handles this automatically
- NEVER define a `locals` block solely for common tags — use `default_tags` instead
- `default_tags` are automatically applied to ALL resources that support tags

---

## 10. Summary Checklist

Before creating or reviewing any Terraform code, verify:

- [ ] File names follow `<resource>.<sub-resource>.tf` dot-separated pattern
- [ ] All Terraform identifiers use `_` (underscores), never `-` (dashes)
- [ ] Resource names do NOT repeat the resource type
- [ ] Singular nouns for resource/data source names
- [ ] NO hard-coded strings in resource arguments — use variables or locals
- [ ] Related variables are grouped into structured `object()` types
- [ ] Every variable and output has a `description`
- [ ] `count`/`for_each` is the first argument in resource blocks
- [ ] `tags` contains only resource-specific tags (e.g., `Name`); cross-cutting tags via `default_tags` in provider
- [ ] Outputs follow `{name}_{type}_{attribute}` pattern
- [ ] Boolean variables use positive names (`_enabled`, not `_disabled`)
- [ ] List/map variables use plural names
- [ ] `providers.tf` has `default_tags` with `Project`, `Environment`, `ManagedBy`
- [ ] NO `merge(local.common_tags, ...)` anywhere — use `default_tags` instead
