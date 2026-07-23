# tf-env-isolation-poc

Proof of concept for **environment-isolated Terraform**: one directory and one S3 state per environment (`dev` / `uat` / `prod`), replacing a shared multi-account state with aliased providers.

See [docs/poc.md](docs/poc.md) for the full brief.

## Layout

```
dev/    uat/    prod/     # one root module + one state each
legacy/                   # shared-state multi-account demo
docs/poc.md               # PoC brief
docs/context.md           # aliases vs separate state
.github/ci-config.json    # structure/state sketch
```
