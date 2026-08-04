variable "region" {
  description = "AWS region for the uat account."
  type        = string
  default     = "us-east-1"
}

variable "deploy_role_arn" {
  description = "IAM role ARN to assume in the uat account (placeholder; replace before real applies)."
  type        = string
  default     = "arn:aws:iam::222222222222:role/UatTerraformDeployRole"
}

variable "tags" {
  description = "Additional tags merged onto all resources."
  type        = map(string)
  default     = {}
}
