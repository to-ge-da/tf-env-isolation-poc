# References

Official documentation that supports this PoC’s thesis: separate environment directories and separate state, instead of one shared state with multi-account provider aliases. CLI workspaces alone are not enough when credentials and blast radius differ by environment.

- [CLI workspaces](https://developer.hashicorp.com/terraform/cli/workspaces) — workspaces share a backend; not strong isolation when credentials differ across environments
- [Organize configuration](https://developer.hashicorp.com/terraform/tutorials/modules/organize-configuration) — directory-separated environments shrink blast radius
- [Provider configuration](https://developer.hashicorp.com/terraform/language/providers/configuration) — what provider aliases are for (multiple configurations of the same provider)
- [Configure providers tutorial](https://developer.hashicorp.com/terraform/tutorials/configuration-language/configure-providers) — aliases and multiple provider configurations
- [AWS backend best practices](https://docs.aws.amazon.com/prescriptive-guidance/latest/terraform-aws-provider-best-practices/backend.html) — distinct state or backends per environment
