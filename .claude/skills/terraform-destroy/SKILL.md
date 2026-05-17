---
name: terraform-destroy
description: |
  Destroys Terraform stacks by running terraform destroy. Supports destroying a single
  stack by folder name or all stacks in reverse numeric order (highest number first, so
  dependent stacks are torn down before their dependencies). The remote backend stack
  (00-remote-backend-stack) is never destroyed — it is always excluded automatically.
  Asks for confirmation exactly once before starting — after that, all stacks are
  destroyed without further prompts. Use this skill whenever the user wants to destroy,
  tear down, remove, or clean up Terraform infrastructure in this project. Also trigger
  when the user says things like "destroy all stacks", "tear down the VPC", "tf destroy",
  "nuke the infra", "clean up everything", or "remove the network stack".
---

# Terraform Destroy

Destroy Terraform stacks in reverse dependency order with a single confirmation.

## Protected Stack

The `00-remote-backend-stack` is **never destroyed**. It holds the S3 bucket that stores
Terraform state for all other stacks — destroying it would orphan every other stack's
state. This exclusion applies whether destroying all stacks or targeting it by name.
If the user explicitly asks to destroy the remote backend stack, explain why it's
protected and refuse.

## Arguments

This skill accepts an optional stack name argument:

- `/terraform-destroy` — destroys **all** stacks (except the remote backend) in **reverse** numeric order
- `/terraform-destroy <stack-folder>` — destroys a single stack (e.g., `/terraform-destroy 01-network-stack`)

The stack folder name corresponds to a directory under `terraform/` in the project root.

## Pipeline

### Step 1: Discover stacks

- If a specific stack was provided, verify the directory exists at `terraform/<stack-folder>/`. If it is `00-remote-backend-stack`, refuse and explain why.
- If no stack was provided ("destroy all"), list all directories under `terraform/`, **exclude `00-remote-backend-stack`**, and sort the remaining stacks in **reverse** numeric order. Higher-numbered stacks are destroyed first because they depend on lower-numbered ones.

### Step 2: Confirm once

List all stacks that will be destroyed and ask for confirmation **exactly once**:

```
The following stacks will be destroyed (in this order):
  1. 01-network-stack

Note: 00-remote-backend-stack is protected and will NOT be destroyed.

Type "yes" to confirm.
```

If the user confirms, proceed with all stacks without asking again. If they decline, stop.

### Step 3: For each stack, run destroy

For each stack directory, in order:

#### 3a: `terraform init`

Ensure the stack is initialized. Check if `backend.hcl` exists — if so, use `terraform init -backend-config=backend.hcl`. If `.terraform/` already exists, skip init.

#### 3b: `terraform destroy -auto-approve`

Run `terraform destroy -auto-approve` — no per-stack confirmation since the user already confirmed in Step 2.

- Show the destruction summary (resources destroyed count)
- If destroy fails, show the error and ask if the user wants to continue with the remaining stacks or stop

### Step 4: Summary

After all stacks have been processed, provide a brief summary:

- Which stacks were destroyed successfully (and how many resources each)
- Which stacks failed (and the error)
- Which stacks were skipped
- Remind that `00-remote-backend-stack` was preserved

## Important Notes

- Always `cd` into the stack directory before running terraform commands
- Reverse numeric order is critical — higher stacks depend on lower ones
- The single upfront confirmation replaces per-stack confirmations — once the user says yes, execute everything
- Environment variables and AWS credentials should already be configured in the shell
