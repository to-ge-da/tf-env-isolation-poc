# State-split migration: legacy/ → per-env states

This procedure moves real infrastructure out of the shared monolithic `legacy/`
state (`env/legacy/terraform.tfstate`) into per-environment states
(`env/<env>/terraform.tfstate` under `dev/`, `uat/`, and `prod/`). Commands are
copy-pasteable templates keyed to this PoC's SSM resources and backends.

> **This is a procedure document. No commands below were executed against a live
> AWS account in this PoC (no credentials available). Commands are copy-pasteable
> templates; substitute your org's bucket/region/account values.**

## Naming / address honesty

| Aspect | Legacy | Per-env target | Consequence |
|---|---|---|---|
| SSM address | `aws_ssm_parameter.dev` | `aws_ssm_parameter.env` | address rewrite needed if moving state |
| SSM `name` (ForceNew) | `/tf-env-isolation-poc/legacy/dev` | `/tf-env-isolation-poc/dev/deployed-by` | `state mv` alone → plan proposes **replace** |
| Provider | aliased `aws.dev` | unaliased | alias is not in the stored address; rename is plain |

> **Recreate when the resource is cheap, derivable, and holds no irreplaceable
> AWS-side state.** **Use `state mv` only when the AWS-side identity must
> persist** (IAM roles referenced by ARN elsewhere, log groups with retained
> history, resources other stacks point at). The PoC's SSM parameters are cheap
> and derivable → the worked example below uses recreation. `state mv` is taught
> in full as the secondary method because it is the general, identity-preserving
> tool.

Versions assumed: Terraform `required_version >= 1.11.0`, AWS provider `~> 6.0`.
Backend: bucket `tf-env-isolation-poc-state`, `use_lockfile = true`.

---

## Step 0: backup, lockfile, rollback stance

```bash
terraform -chdir=legacy state pull > "$HOME/legacy-tfstate-backup-$(date +%Y%m%d-%H%M%S).json"
aws s3 cp s3://tf-env-isolation-poc-state/env/legacy/terraform.tfstate \
  s3://tf-env-isolation-poc-state/env/legacy/terraform.tfstate.bak
```

**Expected:** local JSON backup + S3 `.bak` object. With `use_lockfile = true`,
do not run concurrent `plan`/`apply`/`state` operations against the same state
key during migration.

**Pitfall:** never push a stale state file; verify `serial`/`lineage` before any
`state push`; avoid `state push -force` except deliberately.

---

## Step 1: inventory and map table

```bash
terraform -chdir=legacy state list
```

**Expected:** addresses `aws_ssm_parameter.dev`, `aws_ssm_parameter.uat`,
`aws_ssm_parameter.prod`. Mapping for this PoC:

| Legacy address | Target root | Method | Target address |
|---|---|---|---|
| `aws_ssm_parameter.dev` | `dev/` | **recreate** | `aws_ssm_parameter.env` |
| `aws_ssm_parameter.uat` | `uat/` | **recreate** | `aws_ssm_parameter.env` |
| `aws_ssm_parameter.prod` | `prod/` | **recreate** | `aws_ssm_parameter.env` |

**Pitfall:** an env root's `state list` is empty before its first apply; empty
`state pull` from a target root is normal, not an error.

---

## Step 2: prepare the target roots

```bash
terraform -chdir=dev init
terraform -chdir=uat init
terraform -chdir=prod init
terraform -chdir=dev validate
terraform -chdir=uat validate
terraform -chdir=prod validate
```

**Expected:** clean init against `env/<env>/terraform.tfstate`; each env
`main.tf` already declares `aws_ssm_parameter.env` (and
`aws_cloudwatch_log_group.poc`).

**Pitfall:** the moved/recreated resource must be manageable by the target
root's **unaliased** provider. Provider alias is not stored in the resource
address (renames are plain strings), but verify region/account match the env
you intend to own.

---

## Step 3: recreation (method A, primary)

For cheap, derivable resources with no irreplaceable AWS-side state, create the
new object first, verify, then release the old. This sidesteps ForceNew replace
entirely, the right lead method for this PoC's SSM parameters.

### Worked example: dev

#### 1. Declare

Already present in `dev/main.tf`:

```hcl
resource "aws_ssm_parameter" "env" {
  name  = "/tf-env-isolation-poc/dev/deployed-by"
  type  = "String"
  value = "terraform-dev"
}
```

#### 2. Copy the value (optional reference)

```bash
aws ssm get-parameter --name /tf-env-isolation-poc/legacy/dev \
  --query Parameter.Value --output text
```

Repo default for the new parameter is `terraform-dev` (already set in
`dev/main.tf`). Adjust only if your live legacy value must be preserved
verbatim and differs from that default.

#### 3. Plan (create only)

```bash
terraform -chdir=dev plan
```

**Expected:** `Plan: 2 to add, 0 to change, 0 to destroy` (SSM parameter + log
group on a fresh env root).

#### 4. Apply

```bash
terraform -chdir=dev apply
```

**Expected:** new `/tf-env-isolation-poc/dev/deployed-by` exists; `dev/` state
owns `aws_ssm_parameter.env`.

#### 5. Release the legacy resource

```bash
terraform -chdir=legacy state rm aws_ssm_parameter.dev
```

Alternatively leave it in legacy state and destroy later in Step 7; prefer
`state rm` once the new param is verified.

After `state rm`, remove the migrated resource block from `legacy/main.tf`
(and any now-unused alias provider config in `legacy/providers.tf` if no longer
referenced). State and config must stay paired; otherwise legacy plan wants
to recreate what you just released.

#### 6. Verify both sides

```bash
terraform -chdir=dev plan
terraform -chdir=legacy plan
```

**Expected:** `dev/` → "No changes." After `state rm` alone, while
`aws_ssm_parameter.dev` still remains in `legacy/main.tf`, the legacy plan
shows **1 to add** (a re-create for the moved address); that is expected, not
an error. The "dev param no longer managed; only uat/prod remain" outcome is
true only once the corresponding block is **removed from `legacy/main.tf`**
(see §5 above). After that edit, legacy plan no longer proposes the re-create
(uat/prod still present until you repeat).

**Pitfall:** brief dual-existence window (old + new coexist until
`state rm`/destroy). Harmless for SSM `String` params with different names;
for singleton/unique-name resources, plan ordering to avoid name collision.

### uat / prod as substitutions

Repeat Step 3 substituting `uat` or `prod` for `dev`. Only these tokens change:
directory, legacy address suffix, SSM name path segment.

```bash
# uat — same flow as Step 3
aws ssm get-parameter --name /tf-env-isolation-poc/legacy/uat \
  --query Parameter.Value --output text
terraform -chdir=uat plan
terraform -chdir=uat apply
terraform -chdir=legacy state rm aws_ssm_parameter.uat
```

```bash
# prod — same flow as Step 3
aws ssm get-parameter --name /tf-env-isolation-poc/legacy/prod \
  --query Parameter.Value --output text
terraform -chdir=prod plan
terraform -chdir=prod apply
terraform -chdir=legacy state rm aws_ssm_parameter.prod
```

---

## Step 4: state mv (method B, secondary, identity-preserving)

Use when AWS-side identity must persist (IAM roles referenced by ARN from
outside Terraform, log groups with retained history, anything another stack
addresses). Complete teaching below; nothing removed from the procedure.
Move the state binding without destroy/create. Use pull/push around
`-state`/`-state-out` (canonical cross-backend form):

```bash
# Pull both states locally
terraform -chdir=legacy state pull > /tmp/legacy.tfstate
terraform -chdir=dev    state pull > /tmp/dev.tfstate    # may be empty pre-first-apply

# Move within local files (removes the address from the legacy copy, adds it to the dev copy)
terraform state mv -state=/tmp/legacy.tfstate -state-out=/tmp/dev.tfstate \
  aws_ssm_parameter.dev aws_ssm_parameter.env

# Push BOTH updated local states back to their backends
terraform -chdir=dev    state push /tmp/dev.tfstate
terraform -chdir=legacy state push /tmp/legacy.tfstate
```

After the move, **remove the migrated resource block(s) from `legacy/main.tf`**
(and the now-unused alias provider config(s) in `legacy/providers.tf` if they
are no longer referenced) so the legacy config no longer declares the migrated
resource; otherwise legacy `plan` will want to recreate it. Until
`legacy/main.tf` is edited, the legacy plan may show a re-create for the moved
address; removing the block resolves it. When done, the resource must exist in
**exactly one state and one config**.

**Address rewrites:** the stored address contains no provider alias →
`aws_ssm_parameter.dev` → `aws_ssm_parameter.env` is a plain rename. Two ways:

| Mechanism | When | Cross-state? |
|---|---|---|
| `moved {}` block | preferred when source and target are the **same** state file; add before apply, remove after | **No** (cannot cross state files) |
| `state mv` | required here | **Yes** (the only mechanism that crosses state files/backends) |

**Honest limitation:** for the PoC's SSM, `state mv` alone is **not**
sufficient. After the move, `terraform plan` in `dev/` proposes **replace**
because the declared `name` (`/tf-env-isolation-poc/dev/deployed-by`) differs
from state's (`/tf-env-isolation-poc/legacy/dev`) and `name` is ForceNew. The
happy path for `state mv` is when the declared target name **matches** the
existing AWS object. If identity must be preserved, keep the legacy `name` in
env config, move state, rename later via normal apply if not ForceNew, or
accept the replace, which is why recreation (Step 3) is the lead method.

**Expected (happy path only):** `terraform -chdir=dev plan` → "No changes.";
after pushing both states **and** removing the block from `legacy/main.tf`,
legacy plan no longer proposes a re-create for the moved address.

**Pitfalls:**

- Stale push: verify `serial`/`lineage` before `state push` (see Step 0); avoid `-force` except deliberately.
- Push **both** local state files (omitting the legacy push leaves the address bound in two backends, dual-management hazard).
- After `state mv`, remove the migrated block from `legacy/main.tf` (and unused alias providers); otherwise legacy plan shows a re-create.
- `moved {}` cannot cross state files; only `state mv` crosses; add `moved {}` before apply and remove after when staying in one state.
- Empty target `state pull` before first apply is normal (see Step 1).

---

## Step 5: verification ("no changes")

```bash
terraform -chdir=dev plan
terraform -chdir=uat plan
terraform -chdir=prod plan
terraform -chdir=legacy plan
```

**Expected:** "No changes." in all four (legacy shows only what was intentionally
left, ideally empty of env resources after Steps 3–4).

**Pitfall:** a `replace` after `state mv` means ForceNew mismatch → back to the
decision rule; recreate (Step 3) is the exit.

---

## Step 6: rollback

```bash
# Restore legacy state from the Step 0 backup (check serial/lineage first)
terraform -chdir=legacy state push "$HOME/legacy-tfstate-backup-<ts>.json"

# If the new env resource must be released from the target state
terraform -chdir=dev state rm aws_ssm_parameter.env
```

**Expected:** legacy state back to pre-migration; AWS objects are untouched by
state surgery alone (state push/rm only change Terraform bindings).

**Pitfall:** `state push` refuses mismatched lineage without `-force`; use
`-force` only after confirming the backup is the newest serial you intend to
restore.

---

## Step 7: decommission legacy/

Retire the shared state only after all envs verified. After Step 5 is green for
all envs:

```bash
terraform -chdir=legacy destroy        # removes anything still owned (if state rm was skipped)
aws s3 rm s3://tf-env-isolation-poc-state/env/legacy/terraform.tfstate   # only after backup confirmed
```

**Expected:** no remaining legacy-owned resources; legacy state key removed from
S3 after backups exist (local JSON + `.bak` from Step 0).

**Pitfall:** backup the legacy state key **before** removing it; decommission
**only** after all three envs verified. `legacy/` is the safety net until then.

---

## Pitfalls checklist

- [ ] Empty target `state pull` before first apply: normal, not an error (Step 1)
- [ ] `moved {}` cannot cross state files; only `state mv` crosses; `moved {}` added before apply, removed after (Step 4)
- [ ] Never push a stale state; serial/lineage check; `-force` only deliberately (Steps 0, 4, 6)
- [ ] Provider alias not in stored address; moved resource manageable by target's unaliased provider (Steps 2, 4)
- [ ] Decommission only after all envs verified; backup before removing legacy state key (Step 7)
