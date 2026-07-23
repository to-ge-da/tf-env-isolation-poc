# Context

Background for this PoC: when provider aliases are appropriate, when they are not, and why separate directories plus separate state are the safer default for multi-account environments.

## Contents

1. [Purpose](#purpose)
2. [The pattern under review](#the-pattern-under-review)
3. [What provider aliases are for](#what-provider-aliases-are-for)
4. [When not to rely on aliases](#when-not-to-rely-on-aliases)
5. [Workspaces are not enough](#workspaces-are-not-enough)
6. [PoC conclusion](#poc-conclusion)
7. [Sources](#sources)

## Purpose

This note explains the reasoning behind the repository layout. Terraform documents provider aliases as a supported feature. It also documents separating configuration and state when environments need independent blast radius. Those two ideas are easy to mix up. This PoC keeps them distinct.

## The pattern under review

A common fragile layout looks like this:

- One root module at the repository root (or a single shared tree)
- **One shared Terraform state**
- Multiple **aliased** AWS providers for different accounts (often the **same region**, different assume-role targets)
- One `plan` / `apply` / `destroy` that can touch every account wired into those aliases

That pattern is demonstrated in [`legacy/`](../legacy/). The corrected layout is [`dev/`](../dev/), [`uat/`](../uat/), and [`prod/`](../prod/): one directory and one state key per environment, with no cross-environment provider aliases in a single root.

## What provider aliases are for

A provider is the plugin that lets Terraform talk to a platform (for example AWS). The `provider` block configures that plugin. The optional `alias` argument creates **additional configurations of the same provider** inside one root module.

Official examples of multiple provider configurations focus on cases such as **different regions** in the same setup: one default `aws` config and an aliased config for another region. Resources then select a configuration with `provider = aws.<alias>`. See the [provider block reference — multiple provider configurations](https://developer.hashicorp.com/terraform/language/block/provider#multiple-provider-configurations).

So aliases are appropriate when **one deployment** legitimately needs more than one provider configuration (for example two regions, or a rare cross-account **read** beside resources managed in a primary account).

Aliases are **not** an environment isolation strategy. Using `aws.dev`, `aws.uat`, and `aws.prod` in one shared state does not give each environment its own destroy boundary; it only names different credentials inside the same blast radius.

## When not to rely on aliases

Do not use aliases as the primary way to separate environments or accounts that need:

- Independent state
- Independent credentials and access controls
- Independent apply/destroy lifecycle
- A smaller blast radius if someone runs the wrong command

HashiCorp’s guidance on organizing configuration describes **directory-separated environments** and **separate states** as the way to shrink blast radius when environments should not share fate. See [Organize configuration — separate states](https://developer.hashicorp.com/terraform/tutorials/modules/organize-configuration#separate-states).

AWS’s Terraform guidance similarly favors distinct state (or backends) per environment rather than relying on a single shared state for strong isolation. See [Backend best practices](https://docs.aws.amazon.com/prescriptive-guidance/latest/terraform-aws-provider-best-practices/backend.html).

**Rule of thumb:** same deployment, another region or secondary config → alias can be fine. Different env or account that must not share destroy risk → separate directory and separate state, one unaliased provider per root.

## Workspaces are not enough

Terraform CLI workspaces give multiple state instances for one configuration and one backend. They are convenient for similar copies of the same stack. They are **not** designed for strong separation when each environment needs different credentials and access controls, because workspaces in a working directory still share that backend. See [CLI workspaces](https://developer.hashicorp.com/terraform/cli/workspaces).

For multi-account environments with real isolation requirements, prefer separate roots and separate state keys (this PoC), not “one root + workspaces + aliases.”

## PoC conclusion

This repository’s target model is:

**one environment → one directory → one state**

Use provider aliases only when a single deployment truly needs multiple provider configurations. Do not use aliases to stand in for `dev` / `uat` / `prod` account isolation.

## Sources

- [Provider block — multiple provider configurations](https://developer.hashicorp.com/terraform/language/block/provider#multiple-provider-configurations)
- [Provider configuration](https://developer.hashicorp.com/terraform/language/providers/configuration)
- [Configure providers tutorial](https://developer.hashicorp.com/terraform/tutorials/configuration-language/configure-providers)
- [Organize configuration — separate states](https://developer.hashicorp.com/terraform/tutorials/modules/organize-configuration#separate-states)
- [CLI workspaces](https://developer.hashicorp.com/terraform/cli/workspaces)
- [AWS backend best practices](https://docs.aws.amazon.com/prescriptive-guidance/latest/terraform-aws-provider-best-practices/backend.html)
