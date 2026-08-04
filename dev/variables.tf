variable "region" {
  description = "AWS region for the dev account."
  type        = string
  default     = "us-east-1"
}

variable "deploy_role_arn" {
  description = "IAM role ARN to assume in the dev account (placeholder; replace before real applies)."
  type        = string
  default     = "arn:aws:iam::111111111111:role/DevTerraformDeployRole"
}

variable "tags" {
  description = "Additional tags merged onto all resources."
  type        = map(string)
  default     = {}
}
