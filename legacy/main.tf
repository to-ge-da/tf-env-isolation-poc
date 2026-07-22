# ============================================
# SSM PARAMETERS — ONE PER ENVIRONMENT ALIAS
# ============================================
# Cheap deployable resources so a single apply/destroy in this root
# can touch all three accounts via the shared state.

resource "aws_ssm_parameter" "dev" {
  provider = aws.dev

  name  = "/tf-env-isolation-poc/legacy/dev"
  type  = "String"
  value = "legacy-dev"

  tags = {
    Environment = "dev"
    PoC         = "legacy-anti-pattern"
  }
}

resource "aws_ssm_parameter" "uat" {
  provider = aws.uat

  name  = "/tf-env-isolation-poc/legacy/uat"
  type  = "String"
  value = "legacy-uat"

  tags = {
    Environment = "uat"
    PoC         = "legacy-anti-pattern"
  }
}

resource "aws_ssm_parameter" "prod" {
  provider = aws.prod

  name  = "/tf-env-isolation-poc/legacy/prod"
  type  = "String"
  value = "legacy-prod"

  tags = {
    Environment = "prod"
    PoC         = "legacy-anti-pattern"
  }
}
