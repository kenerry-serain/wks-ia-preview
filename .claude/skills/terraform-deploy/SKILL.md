---
name: terraform-deploy
description: |
  Deploys Terraform stacks through the full lifecycle: fmt, validate, plan, and apply.
  Supports deploying a single stack by folder name or all stacks in numeric order.
  Use this skill whenever the user wants to deploy, apply, plan, validate, or format
  Terraform code in this project. Also trigger when the user says things like
  "deploy the VPC stack", "apply all stacks", "run terraform", "plan the backend stack",
  or "tf apply". Even if the user only mentions one step (like "validate"), run the
  full pipeline up to that step.
---

# Terraform Deploy

Deploy Terraform stacks through a controlled pipeline: **fmt** -> **validate** -> **plan** -> **apply**.

## Arguments

This skill accepts an optional stack name argument:

- `/terraform-deploy` — deploys **all** stacks in the `terraform/` directory, in numeric prefix order
- `/terraform-deploy <stack-folder>` — deploys a single stack (e.g., `/terraform-deploy 00-remote-backend-stack`)

The stack folder name corresponds to a directory under `terraform/` in the project root.

## Pipeline Steps

Execute these steps in order. **Stop immediately if any step fails** — do not proceed to the next step. Show the user the error output and help them fix it.

### Step 1: Discover stacks

- If a specific stack was provided, verify the directory exists at `terraform/<stack-folder>/`
- If no stack was provided ("deploy all"), list all directories under `terraform/` and sort them by their numeric prefix (e.g., `00-*` before `01-*` before `02-*`). This ordering matters because later stacks often depend on earlier ones.

### Step 2: For each stack, run the pipeline

For each stack directory, run these substeps in sequence:

#### 2a: `terraform fmt -check -recursive`

Run from within the stack directory. This checks if the code is properly formatted.

- If formatting issues are found, run `terraform fmt -recursive` to fix them automatically, then inform the user what was reformatted.
- If already formatted, move on.

#### 2b: `terraform init`

Run `terraform init` to initialize the stack. Check if a `backend.hcl` file exists in the stack directory — if so, use `terraform init -backend-config=backend.hcl`. If init was already done (`.terraform/` exists and lock file is current), you can add `-reconfigure` only if needed.

#### 2c: `terraform validate`

Run `terraform validate` to check configuration validity.

- If validation fails, show the errors and stop. Help the user understand what's wrong.

#### 2d: `terraform plan`

Run `terraform plan -out=tfplan` to create an execution plan.

- Show the user a summary of what will be created/changed/destroyed.
- If there are no changes, inform the user and skip the apply step for this stack.

#### 2e: Apply

Run `terraform apply tfplan` immediately — do not ask for confirmation, the user has already decided to deploy by invoking this skill.

- After apply completes, clean up the `tfplan` file

### Step 3: Summary

After all stacks have been processed, provide a brief summary:

- Which stacks were deployed successfully
- Which stacks were skipped (no changes or user declined)
- Which stacks failed (and at which step)

## Important Notes

- Always `cd` into the stack directory before running any terraform commands
- If deploying all stacks and one fails, ask the user if they want to continue with remaining stacks or stop
- Environment variables and AWS credentials should already be configured in the shell — do not attempt to configure them
- If `terraform init` has already been run and `.terraform/` exists, you can skip re-init unless the user asks for it or there are provider/module changes
- When showing plan output, highlight the resource count summary (e.g., "Plan: 3 to add, 0 to change, 1 to destroy")
