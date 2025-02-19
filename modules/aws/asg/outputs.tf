output "asg_name" {
  value       = try(aws_autoscaling_group.this[0].name, null)
  description = "The name of the Auto Scaling Group"

}
