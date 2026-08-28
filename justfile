set shell := ["bash", "-cu"]

# One AWS provider download for all roots (the zip is ~800MB).
export TF_PLUGIN_CACHE_DIR := env("TF_PLUGIN_CACHE_DIR", env("HOME") + "/.cache/terraform/plugin-cache")

# Default: list available recipes
default:
    @just --list

_plugin-cache:
    mkdir -p "${TF_PLUGIN_CACHE_DIR}"

# Guard: env must exist in ci-config.json and as a directory
_guard env:
    #!/usr/bin/env bash
    set -euo pipefail
    if ! jq -e --arg e "{{env}}" '.environments | has($e)' .github/ci-config.json >/dev/null; then
        envs="$(jq -r '.environments | keys_unsorted | join(" ")' .github/ci-config.json)"
        echo "error: '{{env}}' is not a valid environment (expected one of: ${envs})" >&2
        exit 1
    fi
    if [ ! -d "{{env}}" ]; then
        echo "error: environment directory '{{env}}/' does not exist" >&2
        exit 1
    fi

# Banner: show env targeting details before mutating commands
_banner env:
    #!/usr/bin/env bash
    set -euo pipefail
    state_key="$(jq -r --arg e "{{env}}" '.environments[$e].state_key' .github/ci-config.json)"
    bucket="$(jq -r '.backend.bucket' .github/ci-config.json)"
    echo "============================================================"
    echo "  environment : {{env}}"
    echo "  directory   : {{env}}/"
    echo "  state key   : ${state_key}"
    echo "  bucket      : ${bucket}"
    echo "============================================================"

# Initialize terraform for an environment.
# Use `just init <env> reconfigure` after backend changes or after a `-backend=false` validate-init.
init env reconfigure="": (_guard env) (_plugin-cache)
    #!/usr/bin/env bash
    set -euo pipefail
    if [ -z "{{reconfigure}}" ]; then
        terraform -chdir={{env}} init
    elif [ "{{reconfigure}}" = "reconfigure" ]; then
        terraform -chdir={{env}} init -reconfigure
    else
        echo "error: second argument must be 'reconfigure' or omitted (got '{{reconfigure}}')" >&2
        exit 1
    fi

# Format all terraform files recursively from repo root
fmt:
    terraform fmt -recursive

# Validate an environment (local-only init, no AWS creds required)
validate env: (_guard env) (_plugin-cache)
    terraform -chdir={{env}} init -backend=false -input=false >/dev/null && terraform -chdir={{env}} validate

# Validate every root in ci-config.json (env dirs + legacy anti-pattern)
validate-all: (_plugin-cache)
    #!/usr/bin/env bash
    set -euo pipefail
    jq -r '.validate_roots[]' .github/ci-config.json | while read -r root; do
        echo "==> validate ${root}"
        terraform -chdir="${root}" init -backend=false -input=false >/dev/null
        terraform -chdir="${root}" validate
    done

# Fail if a per-env root declares a provider alias (the anti-pattern this PoC forbids)
check-isolation:
    #!/usr/bin/env bash
    set -euo pipefail
    if grep -R --include='*.tf' -nE 'alias[[:space:]]*=' dev uat prod modules; then
        echo "error: provider aliases are forbidden under per-env roots and modules/" >&2
        exit 1
    fi
    echo "ok: no provider aliases in dev/, uat/, prod/, or modules/"

# Local CI: fmt-check + isolation + validate-all (no AWS)
ci: _plugin-cache check-isolation
    terraform fmt -check -recursive
    just validate-all

# Plan changes for an environment
plan env: (_guard env) (_banner env)
    terraform -chdir={{env}} plan

# Apply changes for an environment (requires confirmation)
[confirm("Apply to '{{env}}' (state: env/{{env}}/terraform.tfstate)?")]
apply env: (_guard env) (_banner env)
    terraform -chdir={{env}} apply

# Destroy an environment (typed confirmation required)
destroy env: (_guard env) (_banner env)
    #!/usr/bin/env bash
    set -euo pipefail
    read -r -p "Type '{{env}}' to destroy: " a
    [ "$a" = "{{env}}" ] || { echo aborted; exit 1; }
    terraform -chdir={{env}} destroy

# Show terraform outputs for an environment
output env: (_guard env)
    terraform -chdir={{env}} output

# List terraform state resources for an environment
state-list env: (_guard env)
    terraform -chdir={{env}} state list
