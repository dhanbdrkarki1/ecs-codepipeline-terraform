output "cluster_name" {
  value = try(aws_ecs_cluster.main[0].name, null)
}

output "cluster_id" {
  value = try(aws_ecs_cluster.main[0].id, null)
}

output "ecs_service_name" {
  value = try(aws_ecs_service.main[0].name, null)
}

################################################################################
# Cluster Capacity Providers
################################################################################

output "cluster_capacity_providers" {
  description = "Map of cluster capacity providers attributes"
  value       = { for k, v in aws_ecs_cluster_capacity_providers.this : v.id => v }
}

################################################################################
# Capacity Provider - Autoscaling Group(s)
################################################################################

output "autoscaling_capacity_providers" {
  description = "Map of autoscaling capacity providers created and their attributes"
  value       = aws_ecs_capacity_provider.this
}
