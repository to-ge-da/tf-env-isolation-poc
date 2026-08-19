# Agent notes

PoC: one environment → one directory → one S3 state. Do not add cross-env provider aliases under `dev/`, `uat/`, or `prod/`. `legacy/` is the unsafe counter-example.

## Layout

- `dev/` `uat/` `prod/` — thin roots: unaliased AWS provider, S3 backend, `module.stack`
- `modules/poc/` — shared SSM parameter + log group (isolation is the root/state, not this module)
- `legacy/` — shared-state multi-account aliases (do not copy)
- `.github/ci-config.json` — env names, state keys, pinned Terraform version, validate roots

## Commands

```bash
just ci              # fmt-check + isolation + validate-all (no AWS)
just validate-all    # init -backend=false + validate every root
just validate dev
just plan uat        # needs AWS
just apply prod      # needs AWS + confirmation
```

`plan` / `apply` / `destroy` require AWS. CI on PR/push is validate-only; apply is `workflow_dispatch` only.

## Conventions

- Terraform `1.15.9` in `mise.toml` / CI (`required_version >= 1.11` for `use_lockfile`); AWS provider `~> 6.0`
- Commit `.terraform.lock.hcl` for each root; do not commit `*.tfvars`
- `deploy_role_arn` default is `null` (ambient creds / CI OIDC). Do not restore hardcoded fake ARNs as defaults — that double-assumes in CI.
- Isolation check: no `alias =` in `dev/`, `uat/`, `prod/`, or `modules/`
- Conventional Commits; branch from `main`
