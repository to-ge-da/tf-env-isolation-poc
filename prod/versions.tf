terraform {
  required_version = ">= 1.11.0"

  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    # Production roots should declare a single unaliased AWS provider for this
    # environment's account only — never aws.dev / aws.uat / aws.prod aliases here.
    # aws = {
    #   source  = "hashicorp/aws"
    #   version = "~> 6.0"
    # }
  }
}
