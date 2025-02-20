output "ecr_repo" {
  value = try(module.ecr.repository_url, null)
}

output "load_balancer_dns_name" {
  value = module.alb.load_balancer_dns_name
}

# output "database_endpoint" {
#   value = module.database.db_instance_address
# }
