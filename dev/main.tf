# One unaliased provider, scoped to the dev account only.
# Contrast with legacy/ where one root uses aws.dev / aws.uat / aws.prod aliases.
provider "aws" {
  region = var.region

  # Null (default) uses ambient credentials — local profile or CI OIDC already
  # assumed. Set deploy_role_arn only when this root should assume a role itself.
  dynamic "assume_role" {
    for_each = var.deploy_role_arn == null ? [] : [var.deploy_role_arn]
    content {
      role_arn     = assume_role.value
      session_name = "terraform-dev"
    }
  }

  default_tags {
    tags = merge(
      {
        Environment = "dev"
        ManagedBy   = "terraform"
      },
      var.tags,
    )
  }
}

module "stack" {
  source      = "../modules/poc"
  environment = "dev"
}
