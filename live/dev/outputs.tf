output "vpc_id" {
  value = module.vpc.vpc_id
}

output "alb_arn" {
  value = module.alb.alb_arn
}

output "alb_target_group_arns" {
  value = module.alb.target_group_arns
}

output "load_balancer_dns_name" {
  value = module.alb.load_balancer_dns_name
}

# output "database_endpoint" {
#   value = module.database.db_instance_address
# }
