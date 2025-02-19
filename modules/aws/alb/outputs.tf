output "load_balancer_dns_name" {
  value = !var.use_existing_load_balancer ? try(aws_lb.lb[0].dns_name, null) : try(data.aws_lb.existing_lb[0].dns_name, null)
}

output "alb_name" {
  value = !var.use_existing_load_balancer ? try(aws_lb.lb[0].name, null) : try(data.aws_lb.existing_lb[0].name, null)
}

output "alb_arn_suffix" {
  value = !var.use_existing_load_balancer ? try(aws_lb.lb[0].arn_suffix, null) : try(data.aws_lb.existing_lb[0].arn_suffix, null)
}

output "alb_arn" {
  value = !var.use_existing_load_balancer ? try(aws_lb.lb[0].arn, null) : try(data.aws_lb.existing_lb[0].arn, null)
}

output "load_balancer_zone_id" {
  value = !var.use_existing_load_balancer ? try(aws_lb.lb[0].zone_id, null) : try(data.aws_lb.existing_lb[0].zone_id, null)
}

output "target_group_name" {
  value = !var.use_existing_load_balancer ? try(aws_lb_target_group.this[0].name, null) : try(data.aws_lb.existing_lb[0].name, null)
}

output "target_group_arn_suffix" {
  value = !var.use_existing_load_balancer ? try(aws_lb_target_group.this[0].arn_suffix, null) : try(data.aws_lb.existing_lb[0].arn_suffix, null)
}

output "target_group_arns" {
  value       = { for k, v in aws_lb_target_group.this : k => v.arn }
  description = "The ARNs of the created target groups"
}
