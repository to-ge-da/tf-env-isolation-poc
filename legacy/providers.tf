# ============================================
# AWS PROVIDERS — MULTI-ACCOUNT ALIASES (ANTI-PATTERN)
# ============================================
# One root module, three aliased providers, one shared state.
# There is intentionally no default (unaliased) aws provider.

provider "aws" {
  alias  = "dev"
  region = var.region

  assume_role {
    role_arn     = var.dev_role_arn
    session_name = "terraform-legacy-dev"
  }
}

provider "aws" {
  alias  = "uat"
  region = var.region

  assume_role {
    role_arn     = var.uat_role_arn
    session_name = "terraform-legacy-uat"
  }
}

provider "aws" {
  alias  = "prod"
  region = var.region

  assume_role {
    role_arn     = var.prod_role_arn
    session_name = "terraform-legacy-prod"
  }
}
