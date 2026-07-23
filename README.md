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
```
