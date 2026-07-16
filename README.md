# tf-env-isolation-poc

Proof of concept for **environment-isolated Terraform**: one directory and one S3 state per environment (`dev` / `uat` / `prod`).

## Problem

Critical infrastructure is often managed as a **monolith** at the repo root: one shared Terraform state and aliased AWS providers for multiple accounts.

```hcl
provider "aws" {
  alias  = "dev"
  region = "us-east-1"
}
provider "aws" {
  alias  = "uat"
  region = "us-east-1"
}
provider "aws" {
  alias  = "prod"
  region = "us-east-1"
}
```

That is **not good daily practice** for AWS/Terraform. One `apply` or `destroy` can touch the wrong account. This PoC demonstrates the standard fix.

## PoC goal

| Environment | Directory | S3 state key (example) |
|-------------|-----------|------------------------|
| dev | `dev/` | `env/dev/terraform.tfstate` |
| uat | `uat/` | `env/uat/terraform.tfstate` |
| prod | `prod/` | `env/prod/terraform.tfstate` |

- **No Terraform Cloud** — remote state is S3 (+ DynamoDB lock).
- **No cross-env provider aliases** — one unaliased provider per env root.
- **CI deferred** — when added later, prefer one reusable/matrix workflow, not three duplicated pipelines.

See [specification.md](specification.md) for the full brief.

## Demo script

1. Compare `dev/backend.tf`, `uat/backend.tf`, and `prod/backend.tf` — three distinct state keys.
2. Confirm no multi-account provider aliases (`alias = "dev"|"uat"|"prod"`) in any env root.
3. Mentally map: changes under `dev/` only ever apply against `dev/` and `env/dev/terraform.tfstate`.

## Non-goals

- Migrating the real production monolith
- Terraform Cloud / Enterprise
- Vault, bastions, Grafana, RFC bots, snapshot/rollback automation
- Shipping GitHub Actions in this PoC pass

## Layout

```
dev/    uat/    prod/     # one root module + one state each
.github/ci-config.json    # structure/state sketch
specification.md          # PoC brief
```
