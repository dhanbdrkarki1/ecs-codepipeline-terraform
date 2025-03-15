output "ecr_repo" {
  value = try(module.ecr.repository_url, null)
}

output "load_balancer_dns_name" {
  value = module.alb.load_balancer_dns_name
}

# output "asg_arns" {
#   value = {
#     for key, asg in module.asgs : key => asg.asg_arn
#   }
# }

# # Cloudwatch Log groups
# output "log_group_arns" {
#   value = {
#     for k, v in module.cloudwatch_log_groups : k => v.log_group_arn
#   }
# }

# output "log_group_names" {
#   value = {
#     for k, v in module.cloudwatch_log_groups : k => v.log_group_name
#   }
# }

# output "database_endpoint" {
#   value = module.database.db_instance_address
# }
