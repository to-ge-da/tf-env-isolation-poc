# Live AWS setup (remaining)

The PoC is validate-complete without credentials. This page is the human checklist for a first real `plan`/`apply`. Do not apply from a laptop against shared accounts until the S3 backend and per-env roles exist.

Nothing here is executed in this repository today.

## 1. State bucket

Create one bucket (name in `.github/ci-config.json` → `backend.bucket`, default `tf-env-isolation-poc-state`) in the state account:

- Versioning on
- Encryption on
- Public access blocked
- Native lockfiles (`use_lockfile = true` in each `backend.tf`) — no DynamoDB lock table

Same bucket for every env is fine. Keys must stay distinct (`env/dev|uat|prod/terraform.tfstate`).

Replace `bucket` / `region` in each `backend.tf` if your org names differ. Keep the keys.

## 2. Per-env deploy roles

One IAM role per account (`dev` / `uat` / `prod`), each able to:

- Manage the PoC resources (SSM parameter + CloudWatch log group)
- Read/write **only** that environment's state key in the bucket

Trust GitHub OIDC (`token.actions.githubusercontent.com`) limited to this repository and, for apply, the matching GitHub Environment.

Local apply: copy `*/terraform.tfvars.example` → `terraform.tfvars` and set `deploy_role_arn`, **or** export ambient credentials for that account and leave the variable null.

CI apply: leave `deploy_role_arn` null. The workflow already assumes `<ENV>_DEPLOY_ROLE_ARN` via OIDC. Setting both would double-assume.

## 3. GitHub configuration

Repo secrets (Actions):

| Secret | Role |
|---|---|
| `DEV_DEPLOY_ROLE_ARN` | Dev account deploy role |
| `UAT_DEPLOY_ROLE_ARN` | UAT account deploy role |
| `PROD_DEPLOY_ROLE_ARN` | Prod account deploy role |

Optional repo variable: `AWS_REGION` (default `us-east-1`).

GitHub Environments named `dev`, `uat`, and `prod` — the apply job uses `environment: ${{ matrix.env }}`. Put protection rules on `prod` (required reviewers).

Without these secrets, PR/push CI still passes (fmt + isolation + validate). Remote plan is skipped with a notice. Apply via **Actions → terraform-env → Run workflow** (`command=apply`) fails closed if the secret is missing.

## 4. First apply

```bash
# local, after creds + bucket exist
just init dev
just plan dev
just apply dev
```

Or dispatch `command=plan` then `command=apply` for one environment. Never apply more than one env in a single operation — that is the failure mode this PoC exists to prevent.

## 5. Out of scope here

- Creating the AWS accounts themselves
- Org-wide OIDC provider modules
- Migrating real workloads (see [migration.md](migration.md) once `legacy/` has live state)
