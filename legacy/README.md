# Shared state across AWS accounts

This directory is a deliberate unsafe example: one Terraform state drives multiple AWS account providers. Do not copy it for production use.

It shows:

- **One shared state** (`env/legacy/terraform.tfstate`)
- **Aliased AWS providers** for `dev`, `uat`, and `prod` in the same root module
- **One apply/destroy** that can create or delete resources in **all three accounts**

For the per-env layout, see `../dev`, `../uat`, and `../prod` (one directory and one state key each). Background: [docs/context.md](../docs/context.md).

## What it deploys

One SSM String parameter per alias:

| Provider alias | SSM parameter name | Value |
|----------------|--------------------|-------|
| `aws.dev` | `/tf-env-isolation-poc/legacy/dev` | `legacy-dev` |
| `aws.uat` | `/tf-env-isolation-poc/legacy/uat` | `legacy-uat` |
| `aws.prod` | `/tf-env-isolation-poc/legacy/prod` | `legacy-prod` |

## How to run

1. Copy and edit variables:

```bash
cp terraform.tfvars.example terraform.tfvars
```

2. Set real role ARNs for each account (roles need permission to manage SSM parameters).

3. Ensure the S3 state bucket from `backend.tf` exists (or adjust those values). Native S3 lockfiles are used (`use_lockfile = true`).

4. Initialize, plan, apply:

```bash
terraform init
terraform plan
terraform apply
```

5. Destroy when finished:

```bash
terraform destroy
```

## Why this is unsafe

Because all three aliases share one state file, a broad `destroy` or a mistaken plan in this root can touch every account wired into the providers. That is the blast-radius failure mode this repository is designed to eliminate.
