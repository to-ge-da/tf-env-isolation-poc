variable "region" {
  description = "AWS region for the uat account."
  type        = string
  default     = "us-east-1"
}

variable "deploy_role_arn" {
  description = "IAM role ARN to assume in the uat account. Null uses ambient credentials (local profile or CI OIDC)."
  type        = string
  default     = null
  nullable    = true
}

variable "tags" {
  description = "Additional tags merged onto all resources."
  type        = map(string)
  default     = {}
}
