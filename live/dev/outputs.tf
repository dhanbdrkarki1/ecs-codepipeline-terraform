output "ecr_repo" {
  value = try(module.ecr.repository_url, null)
}

output "load_balancer_dns_name" {
  value = module.alb.load_balancer_dns_name
}

# output "asg_arn" {
#   value = module.asg.asg_arn
# }

output "asg_arns" {
  value = {
    for key, asg in module.asgs : key => asg.asg_arn
  }
}


# output "database_endpoint" {
#   value = module.database.db_instance_address
# }
