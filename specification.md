# Testnet Infra PoC Specification

## Objective

This proof of concept (PoC) aims to establish sovereign workflows per environment within the GitHub repository for Terraform infrastructure. The goal is to:

- Separate environments into distinct directories (Dev, Integrate, Prod)
- Establish sovereign workflows that only interact with resources within the same environment
- Prevent accidental production resource deletions
- Provide clear, environment-specific governance and security boundaries

## Current Problem

The current infrastructure repository has a flat structure with all environments in the same root directory. Multiple Terraform files define resources for different accounts and environments. This structure has proven fragile — inexperienced team members have accidentally destroyed production resources due to lack of proper separation and governance.

## Proposed Solution

### Repository Structure

```
Testnet Infra/
├── Dev/
│   ├── main.tf
│   ├── variables.tf
│   └── ...
├── Integrate/
│   ├── main.tf
│   ├── variables.tf
│   └── ...
├── Prod/
│   ├── main.tf
│   ├── variables.tf
│   └── ...
└── .github/
    ├── terraform.yaml (global configuration)
    └── workflows/
        ├── dev.yml
        ├── integrate.yml
        └── prod.yml
```

### Environment Separation

Each environment (Dev, Integrate, Prod) has its own directory containing:
- Environment-specific Terraform configuration files
- Variables defining environment-specific values
- Dependencies scoped only to that environment

### Workflow Sovereignty

Each environment has its own set of GitHub Actions workflows that:
- Operate only on files within the same environment directory
- Use state locking with unique workspace names per environment
- Execute with environment-specific permissions (cannot modify other environments)

### CI/CD Configuration

The `.github/terraform.yaml` file serves as the central configuration source-of-truth, defining:
- Environment-specific paths
- Pipeline triggers and commands
- Approval requirements per environment
- Notification channels and thresholds
- Security policies and timeouts

## Governance Levels

### 1. Dev Environment

**Characteristics:**
- Highly iterative, fast feedback loop
- Non-production resources only
- Minimal approvals required

**Policies:**
- Allow auto-apply on main branch
- Automatic destroy only via explicit tag (requires approval)
- Branch protection: only allow create operations
- No production resources should exist here

**Workflows:**
- **apply**: Auto-apply on main branch (create/update operations only)
- **destroy**: Triggered by tag vX.X.X-destroy, requires manual review
- **plan**: Triggered on PR to main, comments plan on PR

**Implementation Requirements:**
- Set branch protection rule: `required_approving_reviews: 1` on main branch
- Add status check: `terraform plan` must pass before merge
- Allow destroy only via manual workflow trigger with explicit tag

### 2. Integrate Environment

**Characteristics:**
- Near-production environment
- More conservative deployment process
- Manual approvals for destructive operations
- Rollback capabilities with automated snapshots

**Policies:**
- Require manual approval for all destructive operations
- Do not allow direct access to production resources (read-only monitoring only)
- Deploy only from tagged releases (not main branch)
- Automated snapshots before any destructive changes
- Rollback window with automated snapshots

**Workflows:**
- **apply**: Triggered by tag vX.X.X, requires manual review, SLA alerts
- **destroy**: Triggered by approved deprecation RFC, requires manual review, final approval from 2 stakeholders
- **plan**: Triggered on PR to main, requires manual review before merge, suggests changes
- **rollback**: Automatic on destroy failure or alert, imports from automated snapshots

**Implementation Requirements:**
- Set branch protection rule: `required_approving_reviews: 2` on main branch
- Add status check: `terraform plan` must pass before merge
- Add Slack alert for any destroy operation
- Add runbook link to workflow context
- Configure rollback automation with 24-hour snapshot retention

### 3. Prod Environment

**Characteristics:**
- Heavily gated, manual approval, slow feedback cycle
- Maximum security and isolation
- Strict governance and audit trail

**Policies:**
- No auto-approval - always manual review
- Destroy requires RFC (Request for Comments) with 3+ stakeholder approval
- Automated snapshots before any state change
- Who can modify terraform.lock.hcl: platform engineers only
- Workflows run in dedicated prod-workflow-runner service (if using Terraform Cloud)
- SLA: plan runs max 15 minutes, apply max 5 minutes (aligned with cloud control plane)

**Workflows:**
- **apply**: Triggered by approved RFC + tagged release, requires manual review, runs in prod-workflow-runner, 5-minute SLA
- **destroy**: Triggered by approved RFC + 3+ stakeholder signatures, requires manual review, runs in prod-workflow-runner, 60-minute SLA, final approval required
- **plan**: Triggered on PR to main, requires manual review, suggests changes, runs in prod-workflow-runner, 15-minute SLA
- **rollback**: Triggered by approved RFC + immediate action, imports from automated snapshots, 30-minute SLA
- **monitoring**: Runs every 15 minutes, lists resources in state, SLA alerts

**Implementation Requirements:**
- Set branch protection rule: `required_approving_reviews: 3` on main branch
- Add status check: `terraform plan` must pass before merge
- Require manual approval for all workflow actions (apply, destroy, plan)
- Configure dedicated prod-workflow-runner service if using Terraform Cloud
- Implement RFC (Request for Comments) workflow with automatic comment triggers
- Configure SLA enforcement with timeout and alert action
- Configure Slack notifications to critical channels (#production-alerts, #devops-critical)
- Configure email notifications for destructive operations
- Add runbook links to all workflows
- Require stakeholder approval before any destructive operation
- Enforce automated snapshot before any state change

## Pipeline Global Configuration

### Backend Configuration

- **Type**: Remote state via Terraform Cloud/Enterprise
- **Workspace Base**: `Testnet-infra`
- **Workspace Prefixes**:
  - Dev: `dev-`
  - Integrate: `int-`
  - Prod: `prod-`

### State Locking

- **Enabled**: Yes
- **Auto Unlock**: Disabled (manual unlock required after timeout)
- **SLA**: 30 minutes
- **Alert**: Slack notification if locked for SLA period

### Notifications

**Slack:**
- Enabled: Yes
- Team: `Testnet-infra`
- Channels:
  - Dev: `#dev-infra-alerts`
  - Integrate: `#int-infra-alerts`
  - Prod: `#production-alerts`, `#devops-critical`
- Log Levels:
  - Dev: INFO
  - Integrate: WARN
  - Prod: ERROR

**Email:**
- Enabled: Yes
- Recipients:
  - Destroy: `infra-team@Testnet.int`
  - Prod Apply: `devops-lead@Testnet.int`, `security-officer@Testnet.int`
  - Prod Destroy: `devops-lead@Testnet.int`, `security-officer@Testnet.int`, `architect@Testnet.int`

### Security

- **TFVars Encryption**: Enabled
- **Secrets Management**: HashiCorp Vault
- **Bastion Required**:
  - Dev: No
  - Integrate: Yes
  - Prod: Yes
- **Role Permissions**:
  - Dev: create, read, update, destroy
  - Integrate: create, read, update
  - Prod: read only

### Artifacts

**TF Plan Files:**
- Dev: Keep for 24 hours
- Integrate: Keep for 7 days
- Prod: Do not keep

**State Snapshots:**
- Enabled: Yes
- Schedule: Daily
- Retention: 30 days
- Encryption: Yes

## CI/CD System

### Platform

- **Type**: GitHub Actions
- **Runner Image**: `hashicorp/terraform:latest`

### Environment Variables

- `TF_CLI_CONFIG_FILE`: `.github/terraform.yaml`
- `TF_INPUT`: `false`
- `TF_IN_INTERACTIVE`: `false`

### Matrix Configuration

- Environments: `["Dev", "Integrate", "Prod"]`
- Modules: `["core-networking", "iam", "storage", "compute", "database"]`
- Parallelism: 3

### Caching

- Terraform provider cache: Yes
- Cache size: 10 GB

### Validation

- Terraform format check: Yes
- Terraform validate: Yes
- Terraform linting (tflint): Yes
- Plan validation:
  - Check for destroy operations: Yes
  - Check for deprecated functions: Yes
  - Check for unmatched resources: Yes

## Git Workflow

### Branch Protection

**Main Branch:**
- Enforce status checks: Yes
- Required approving reviews:
  - Dev: 1
  - Integrate: 2
  - Prod: 3
- Restrict commits: Yes
- Disallow force pushes: Yes
- Require pull request branch: Yes

### Release Workflow

- **Tag Pattern**: `vX.X.X`
- **Pre-release**: Yes
- **Pre-release Tags**: `[-alpha, -beta, -rc]`

### Dependency Management

- Terraform version lock: Yes
- Provider version lock: Yes

## Monitoring and Alerting

### Metrics

**Apply Duration (seconds):**
- Alert if above:
  - Dev: 5 seconds
  - Integrate: 10 seconds
  - Prod: 5 seconds

**Plan Duration (seconds):**
- Alert if above:
  - Dev: 10 seconds
  - Integrate: 15 seconds
  - Prod: 15 seconds

**Destroy Duration (seconds):**
- Alert if above:
  - Dev: 120 seconds
  - Integrate: 120 seconds
  - Prod: 60 seconds

**State Lock Timeout (minutes):**
- Alert if above: 30 minutes

### Dashboards

- **Terraform Dashboard**: `https://grafana.Testnet.int/d/terraform`
- **Integration Tests Dashboard**: `https://grafana.Testnet.int/d/integration-tests`

## Implementation Plan

### Phase 1: Repository Structure

1. Create directory structure: `Dev/`, `Integrate/`, `Prod/`
2. Move existing Terraform files into appropriate directories
3. Update environment variables and references in configuration
4. Verify Terraform can initialize each environment separately

### Phase 2: CI/CD Configuration

1. Create `.github/terraform.yaml` with global configuration
2. Create workflow files for each environment
3. Configure branch protection rules
4. Set up Slack and email notifications

### Phase 3: Governance and Security

1. Implement approval gates for all destructive operations
2. Configure SLA enforcement with timeout
3. Set up automated state snapshots
4. Create runbooks for critical operations

### Phase 4: Monitoring and Alerting

1. Configure metrics collection
2. Set up dashboards in Grafana
3. Configure alerting thresholds
4. Test alert notifications

### Phase 5: Testing and Validation

1. Test Dev environment workflow
2. Test Integrate environment workflow
3. Test Prod environment workflow
4. Conduct security review
5. Document changes and processes

## Success Criteria

- [ ] Each environment has its own directory with independent Terraform configuration
- [ ] Workflows are sovereign (no cross-environment resource modification)
- [ ] Production destroy operations require 3+ stakeholder approvals
- [ ] All destructive operations trigger Slack and email notifications
- [ ] Automated snapshots are created before any state change
- [ ] SLA enforcement is in place for all workflows
- [ ] All workflows have runbooks linked
- [ ] Monitoring and alerting are configured and tested
- [ ] Branch protection rules enforce approval requirements
- [ ] Documentation is complete and accessible

## Risk Mitigation

1. **Production Deletion Risk**: Mitigated by multi-stakeholder approval requirement and automated snapshots
2. **Workshop State Conflicts**: Mitigated by environment-specific workspaces with unique prefixes
3. **Permission Escalation**: Mitigated by bastion requirement for Integrate and Prod environments
4. **State Lock Conflicts**: Mitigated by environment isolation and SLA enforcement
5. **Workflow Failures**: Mitigated by rollback automation and monitoring

## Next Steps

1. Review this specification with the team
2. Obtain approval for the proposed structure and governance model
3. Create RFC (Request for Comments) for Prod environment changes
4. Begin Phase 1 implementation with Dev environment
5. Validate and test before proceeding to Integrate and Prod
