output "environment" {
  description = "Environment name passed into the stack."
  value       = var.environment
}

output "ssm_parameter_arn" {
  description = "ARN of the environment marker SSM parameter."
  value       = aws_ssm_parameter.env.arn
}

output "log_group_arn" {
  description = "ARN of the PoC CloudWatch log group."
  value       = aws_cloudwatch_log_group.poc.arn
}
