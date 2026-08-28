# tf-env-isolation-poc

One directory and one S3 state per environment (`dev` / `uat` / `prod`), instead of one shared state with multi-account provider aliases.

PoC is **validate-complete** without AWS: config, shared module, isolation check, and CI fmt/validate. Nothing is applied until you add credentials. Terraform `1.15.9` (required `>= 1.11` for S3 `use_lockfile`).

## Why

Shared state plus `aws.dev` / `aws.uat` / `aws.prod` aliases means one `apply` or `destroy` can touch every account. `legacy/` demonstrates that unsafe pattern. `dev/`, `uat/`, and `prod/` are the per-env layout: one root module and one state key each. Resource code lives in `modules/poc/`; isolation is the root + state, not the module.

## Quickstart

Dependencies: `just`, `terraform`, and `jq` (see `mise.toml`).

```bash
just --list        # list recipes
just ci            # fmt-check + isolation + validate-all (no AWS)
just validate dev  # local-only init + validate, no AWS creds needed
just init dev      # init dev against the S3 backend (needs AWS creds)
```

## Layout

```text
dev/  uat/  prod/         # thin roots: unaliased provider + backend + module.stack
modules/poc/              # shared SSM parameter + log group
legacy/                   # shared-state multi-account demo (unsafe on purpose)
docs/poc.md               # PoC brief
docs/context.md           # aliases vs separate state
docs/migration.md         # state-split migration procedure (legacy -> per-env)
docs/aws-setup.md         # remaining live-AWS steps (bucket, OIDC, secrets)
.github/ci-config.json    # env/state-key sketch read by the justfile and CI
justfile                  # env-targeted task runner
```

## Usage

```bash
just ci                  # local CI, no AWS
just validate-all        # validate every root including legacy/
just check-isolation     # fail if a per-env root declares a provider alias
just init dev            # terraform init for an env (S3 backend)
just init dev reconfigure  # re-init after backend changes or a -backend=false validate-init
just validate dev        # local-only init + validate (no AWS creds needed)
just plan uat            # plan for uat (banner + AWS creds)
just apply prod          # banner + confirm, then apply
just destroy prod        # banner + typed env-name gate, then destroy
just output dev          # show outputs for an env
just state-list dev      # list resources in remote state
just fmt                 # terraform fmt -recursive (all envs)
```

Mutating commands (`plan`, `apply`, `destroy`, `output`, `state-list`, and a full `init` against S3) require AWS credentials. Without them they fail at provider/backend auth after the banner (and confirm/typed gate). CI on pull requests and `main` is fmt + isolation + validate only. Remote plan/apply need GitHub secrets; apply is **workflow_dispatch only** (never on push).

Copy `dev/terraform.tfvars.example` (or uat/prod) to `terraform.tfvars` if you need `deploy_role_arn`. The default is ambient credentials so CI OIDC does not double-assume.

## Docs

- [docs/poc.md](docs/poc.md): objective, target structure, success criteria
- [docs/context.md](docs/context.md): when provider aliases fit and when they don't
- [docs/migration.md](docs/migration.md): step-by-step state-split procedure, legacy to per-env
- [docs/aws-setup.md](docs/aws-setup.md): S3 backend, OIDC roles, and GitHub environments for a live apply
