# legacy/ — anti-pattern example (do not copy for production)

This directory intentionally shows a **bad** Terraform layout:

- **One shared state** (`env/legacy/terraform.tfstate`)
- **Aliased AWS providers** for `dev`, `uat`, and `prod` in the same root module
- **One apply/destroy** can create or delete resources in **all three accounts**

Use it only to understand the problem this PoC fixes. For the corrected layout, see `../dev`, `../uat`, and `../prod` (one directory + one state key each).

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

3. Ensure the S3 state bucket and DynamoDB lock table from `backend.tf` exist (or adjust those values).

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
