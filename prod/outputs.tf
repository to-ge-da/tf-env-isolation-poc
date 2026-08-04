output "environment" {
  value = "prod"
}

output "ssm_parameter_arn" {
  value = aws_ssm_parameter.env.arn
}

output "log_group_arn" {
  value = aws_cloudwatch_log_group.poc.arn
}
