# PoC demo resource (no AWS account required).
# When wiring real infra, use a single unaliased provider, e.g.:
#
# provider "aws" {
#   region = "us-east-1"
#   # credentials / assume_role for the UAT account only
# }

resource "random_id" "poc" {
  byte_length = 4

  keepers = {
    environment = "uat"
  }
}

output "environment" {
  value = "uat"
}

output "poc_id" {
  value = random_id.poc.hex
}
