output "environment" {
  value = module.stack.environment
}

output "ssm_parameter_arn" {
  value = module.stack.ssm_parameter_arn
}

output "log_group_arn" {
  value = module.stack.log_group_arn
}
