# tf-env-isolation-poc

PoC for **per-environment Terraform state**: one directory and one S3 state per env (`dev` / `uat` / `prod`), instead of one shared state with multi-account provider aliases.

## Why

- Shared state plus `aws.dev` / `aws.uat` / `aws.prod` aliases raises blast radius
- This repo shows the unsafe pattern (`legacy/`) and the corrected per-environment layout

## Docs

- [PoC brief](docs/poc.md)
- [Context: aliases vs separate state](docs/context.md)

## Layout

```
dev/    uat/    prod/     # one root module + one state each
legacy/                   # shared-state multi-account demo
docs/poc.md               # PoC brief
docs/context.md           # aliases vs separate state
.github/ci-config.json    # structure/state sketch
justfile                  # env-targeted task runner
```

## Usage

Prerequisites: `just` (via mise) and `terraform >= 1.11`.

```bash
just --list              # list recipes
just init dev            # terraform init for an env
just validate dev        # local-only init + validate (no AWS creds needed)
just plan uat            # plan for uat
just apply prod          # banner + confirm, then apply
just destroy prod        # banner + typed env name gate, then destroy
just fmt                 # terraform fmt -recursive (all envs)
just state-list dev      # list resources in remote state
```

Mutating commands (`plan`, `apply`, `destroy`, `output`, `state-list`, and a full `init` against S3) require AWS credentials. Without them they fail at provider/backend auth **after** the banner (and confirm/typed gate) — expected in this PoC. Use `just init <env> reconfigure` after backend changes or after a `-backend=false` validate-init.
