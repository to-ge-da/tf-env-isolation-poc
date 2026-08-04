# One unaliased provider, scoped to the dev account only.
# Contrast with legacy/ where one root uses aws.dev / aws.uat / aws.prod aliases.
provider "aws" {
  region = var.region

  assume_role {
    role_arn     = var.deploy_role_arn
    session_name = "terraform-dev"
  }

  default_tags {
    tags = local.common_tags
  }
}

locals {
  common_tags = merge(
    {
      Environment = "dev"
      ManagedBy   = "terraform"
    },
    var.tags,
  )
}

resource "aws_ssm_parameter" "env" {
  name  = "/tf-env-isolation-poc/dev/deployed-by"
  type  = "String"
  value = "terraform-dev"
}

resource "aws_cloudwatch_log_group" "poc" {
  name              = "/tf-env-isolation-poc/dev"
  retention_in_days = 7
}
