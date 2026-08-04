variable "region" {
  description = "AWS region for the prod account."
  type        = string
  default     = "us-east-1"
}

variable "deploy_role_arn" {
  description = "IAM role ARN to assume in the prod account (placeholder; replace before real applies)."
  type        = string
  default     = "arn:aws:iam::333333333333:role/ProdTerraformDeployRole"
}

variable "tags" {
  description = "Additional tags merged onto all resources."
  type        = map(string)
  default     = {}
}
