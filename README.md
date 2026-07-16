# tf-env-governance-poc

Proof of concept for **environment-isolated Terraform**: one directory, one S3 state, and one GitHub Actions workflow scope per environment (`dev` / `uat` / `prod`).

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

| Environment | Directory | S3 state key (example) | Workflow |
|-------------|-----------|------------------------|----------|
| dev | `dev/` | `env/dev/terraform.tfstate` | `.github/workflows/dev.yml` |
| uat | `uat/` | `env/uat/terraform.tfstate` | `.github/workflows/uat.yml` |
| prod | `prod/` | `env/prod/terraform.tfstate` | `.github/workflows/prod.yml` |

- **No Terraform Cloud** — remote state is S3 (+ DynamoDB lock).
- **No cross-env provider aliases** — one unaliased provider per env root.
- **Approvals** via GitHub Environments (`dev`, `uat`, `prod`), not conflicting per-env rules on the same branch protection config.

See [specification.md](specification.md) for the full brief.

## Demo script

1. Open a PR that only changes `dev/` → only the `dev` workflow should plan.
2. Open a PR that only changes `prod/` → only the `prod` workflow should plan; apply waits on Environment reviewers.
3. Compare `dev/backend.tf`, `uat/backend.tf`, and `prod/backend.tf` — three distinct state keys; no multi-account aliases.

## Non-goals

- Migrating the real production monolith
- Terraform Cloud / Enterprise
- Vault, bastions, Grafana, RFC bots, snapshot/rollback automation

## Layout

```
dev/    uat/    prod/     # one root module + one state each
.github/workflows/        # path-filtered sovereign workflows
.github/ci-config.json    # CI sketch (paths, state keys, gates)
specification.md          # PoC brief
```
