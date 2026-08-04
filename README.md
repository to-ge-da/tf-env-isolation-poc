# tf-env-isolation-poc

One directory and one S3 state per environment (`dev` / `uat` / `prod`), instead of one shared state with multi-account provider aliases.

PoC: config present and validate-clean in all env roots; no AWS credentials here, nothing applied. Terraform >= 1.11.

## Why

Shared state plus `aws.dev` / `aws.uat` / `aws.prod` aliases means one `apply` or `destroy` can touch every account. `legacy/` demonstrates that unsafe pattern. `dev/`, `uat/`, and `prod/` are the per-env layout: one root module and one state key each.

## Quickstart

Dependencies: `just` (via mise) and `terraform >= 1.11`.

```bash
just --list        # list recipes
just validate dev  # local-only init + validate, no AWS creds needed
just init dev      # init dev against the S3 backend (needs AWS creds)
```

## Layout

```text
dev/  uat/  prod/         # one root module + one state key each
legacy/                   # shared-state multi-account demo (unsafe on purpose)
docs/poc.md               # PoC brief
docs/context.md           # aliases vs separate state
docs/migration.md         # state-split migration procedure (legacy -> per-env)
.github/ci-config.json    # env/state-key sketch read by the justfile
justfile                  # env-targeted task runner
```

## Usage

```bash
just init dev            # terraform init for an env (S3 backend)
just init dev reconfigure  # re-init after backend changes or a -backend=false validate-init
just validate dev        # local-only init + validate (no AWS creds needed)
just plan uat            # plan for uat
just apply prod          # banner + confirm, then apply
just destroy prod        # banner + typed env-name gate, then destroy
just output dev          # show outputs for an env
just state-list dev      # list resources in remote state
just fmt                 # terraform fmt -recursive (all envs)
```

Mutating commands (`plan`, `apply`, `destroy`, `output`, `state-list`, and a full `init` against S3) require AWS credentials. Without them they fail at provider/backend auth after the banner (and confirm/typed gate); expected in this PoC.

## Docs

- [docs/poc.md](docs/poc.md): objective, target structure, success criteria
- [docs/context.md](docs/context.md): when provider aliases fit and when they don't
- [docs/migration.md](docs/migration.md): step-by-step state-split procedure, legacy to per-env
