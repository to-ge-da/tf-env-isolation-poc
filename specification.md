# Environment-Isolated Terraform PoC

## Objective

Prove that splitting a Terraform monolith into **one environment → one directory → one state → one workflow scope** prevents cross-account accidental destroys.

This PoC establishes:

- Lowercase environment directories: `dev/`, `uat/`, `prod/`
- **One Terraform state per environment** (S3 backend, distinct state keys)
- Sovereign GitHub Actions workflows that only operate on their own environment path
- GitHub Environment approval gates for apply/destroy (especially production destroy)

## Why the current pattern is not good practice

The production-style layout this PoC replaces is **not appropriate for daily AWS/Terraform work**:

- Several `.tf` files at the repository root
- **One shared Terraform state**
- Multiple aliased AWS providers in that same root, each pointing at a different account

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

That pattern increases blast radius: one `plan` / `apply` / `destroy` can touch the wrong account. It also weakens credential isolation (runners often need access to every account) and makes PR review harder (“what did this change?” spans environments). Unwanted production deletes have already occurred under this model.

**Standard correction:** one environment (or account) → one root module → one state → CI scoped to that path with credentials limited to that account.

## Target structure

```
tf-env-governance-poc/
├── dev/
│   ├── main.tf
│   ├── versions.tf
│   └── backend.tf
├── uat/
│   ├── main.tf
│   ├── versions.tf
│   └── backend.tf
├── prod/
│   ├── main.tf
│   ├── versions.tf
│   └── backend.tf
└── .github/
    ├── ci-config.json
    └── workflows/
        ├── dev.yml
        ├── uat.yml
        └── prod.yml
```

### Environment separation

Each of `dev/`, `uat/`, and `prod/` contains:

- Environment-specific Terraform configuration
- Exactly **one** unaliased AWS provider for that account (no cross-env aliases)
- Its own remote state configuration

### State isolation (S3 — no Terraform Cloud)

| Environment | Directory | Example S3 state key |
|-------------|-----------|----------------------|
| dev | `dev/` | `env/dev/terraform.tfstate` |
| uat | `uat/` | `env/uat/terraform.tfstate` |
| prod | `prod/` | `env/prod/terraform.tfstate` |

Same bucket is acceptable; **different keys** mean different state. Use a DynamoDB table for state locking. This PoC does **not** use Terraform Cloud.

### Workflow sovereignty

Each environment has its own GitHub Actions workflow that:

- Triggers only on changes under that environment’s path (`paths` filters)
- Sets `working-directory` to that environment only
- Uses credentials/roles scoped to that environment’s account
- Uses a matching GitHub Environment (`dev`, `uat`, `prod`) for approval gates on apply/destroy

## Governance (PoC scope)

Single `main` branch. Per-environment approval counts are enforced via **GitHub Environments**, not conflicting branch-protection rules on the same branch.

| Environment | Plan (PR) | Apply | Destroy |
|-------------|-----------|-------|---------|
| dev | On PR touching `dev/` | Auto-apply non-destroy on `main` (GitHub Environment `dev`) | Manual / explicit; Environment approval |
| uat | On PR touching `uat/` | Manual approval via Environment `uat` | Manual; Environment approval |
| prod | On PR touching `prod/` | Manual approval via Environment `prod` | Manual; **multi-reviewer** Environment `prod` gate |

## Success criteria

- [ ] Each environment has its own directory with independent Terraform configuration
- [ ] Each environment has its own S3 state key (one state per environment)
- [ ] No cross-environment provider aliases in any env root module
- [ ] Workflow for environment A never runs Terraform in environment B’s path
- [ ] Production destroy requires a multi-reviewer GitHub Environment gate

## Demo script

1. Open a PR that only changes `dev/` → only the `dev` workflow plans.
2. Open a PR that only changes `prod/` → only the `prod` workflow plans; apply blocked on Environment reviewers.
3. Inspect the three `backend.tf` files: distinct S3 keys; no aliased multi-account providers in any root.

## Out of scope / later (post-PoC)

Deferred platform items (not success gates for this PoC):

- HashiCorp Vault, bastion hosts
- Grafana dashboards and SLA metrics
- Email notifications and RFC automation
- Automated state snapshots / rollback bots
- Migrating the real production monolith modules into this layout
- Terraform Cloud / Terraform Enterprise
