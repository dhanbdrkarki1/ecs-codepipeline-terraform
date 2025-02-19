output "ecs_cluster_name" {
  value = try(aws_ecs_cluster.main[0].name, null)
}

output "ecs_service_name" {
  value = try(aws_ecs_service.main[0].name, null)
}

output "application_log_group_name" {
  value = try(local.log_group_name, null)
}

output "new_relic_log_group_name" {
  value = try(local.new_relic_log_group_name, null)
}
