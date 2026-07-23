# ============================================
# OUTPUTS
# ============================================

output "dev_ssm_parameter_name" {
  description = "SSM parameter name created via aws.dev"
  value       = aws_ssm_parameter.dev.name
}

output "dev_ssm_parameter_arn" {
  description = "SSM parameter ARN created via aws.dev"
  value       = aws_ssm_parameter.dev.arn
}

output "uat_ssm_parameter_name" {
  description = "SSM parameter name created via aws.uat"
  value       = aws_ssm_parameter.uat.name
}

output "uat_ssm_parameter_arn" {
  description = "SSM parameter ARN created via aws.uat"
  value       = aws_ssm_parameter.uat.arn
}

output "prod_ssm_parameter_name" {
  description = "SSM parameter name created via aws.prod"
  value       = aws_ssm_parameter.prod.name
}

output "prod_ssm_parameter_arn" {
  description = "SSM parameter ARN created via aws.prod"
  value       = aws_ssm_parameter.prod.arn
}
