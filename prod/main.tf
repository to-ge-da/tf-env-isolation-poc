# One unaliased provider, scoped to the prod account only.
# Contrast with legacy/ where one root uses aws.dev / aws.uat / aws.prod aliases.
provider "aws" {
  region = var.region

  assume_role {
    role_arn     = var.deploy_role_arn
    session_name = "terraform-prod"
  }

  default_tags {
    tags = local.common_tags
  }
}

locals {
  common_tags = merge(
    {
      Environment = "prod"
      ManagedBy   = "terraform"
    },
    var.tags,
  )
}

resource "aws_ssm_parameter" "env" {
  name  = "/tf-env-isolation-poc/prod/deployed-by"
  type  = "String"
  value = "terraform-prod"
}

resource "aws_cloudwatch_log_group" "poc" {
  name              = "/tf-env-isolation-poc/prod"
  retention_in_days = 7
}
