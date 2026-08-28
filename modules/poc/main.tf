# Cheap, derivable resources so each env root can apply independently.
# Isolation comes from the calling root (own provider, own state), not from this module.

resource "aws_ssm_parameter" "env" {
  name  = "/tf-env-isolation-poc/${var.environment}/deployed-by"
  type  = "String"
  value = "terraform-${var.environment}"
}

resource "aws_cloudwatch_log_group" "poc" {
  name              = "/tf-env-isolation-poc/${var.environment}"
  retention_in_days = var.log_retention_days
}
