# Environment-Isolated Terraform PoC

## Objective

Prove that splitting a Terraform monolith into **one environment → one directory → one state** prevents cross-account accidental destroys.

This PoC establishes:

- Lowercase environment directories: `dev/`, `uat/`, `prod/`
- **One Terraform state per environment** (S3 backend, distinct state keys)
- No cross-environment AWS provider aliases in any env root module

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

That pattern increases blast radius: one `plan` / `apply` / `destroy` can touch the wrong account. It also weakens credential isolation (runners often need access to every account) and makes PR review harder ("what did this change?" spans environments). Unwanted production deletes have already occurred under this model.

**Standard correction:** one environment (or account) → one root module → one state → operations scoped to that path with credentials limited to that account.

## Target structure

```
tf-env-isolation-poc/
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
    └── ci-config.json
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

Same bucket is acceptable; **different keys** mean different state. State locking uses native S3 lockfiles (`use_lockfile = true`). This PoC does **not** use Terraform Cloud.

## Success criteria

- [ ] Each environment has its own directory with independent Terraform configuration
- [ ] Each environment has its own S3 state key (one state per environment)
- [ ] No cross-environment provider aliases in any env root module

See [references.md](references.md) for related official documentation.
