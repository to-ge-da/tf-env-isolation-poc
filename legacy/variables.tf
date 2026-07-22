# ============================================
# TERRAFORM VARIABLES
# ============================================

variable "region" {
  description = "AWS region for all aliased providers"
  type        = string
  default     = "us-east-1"
}

variable "dev_role_arn" {
  description = "IAM role ARN to assume in the DEV account"
  type        = string
}

variable "uat_role_arn" {
  description = "IAM role ARN to assume in the UAT account"
  type        = string
}

variable "prod_role_arn" {
  description = "IAM role ARN to assume in the PROD account"
  type        = string
}
