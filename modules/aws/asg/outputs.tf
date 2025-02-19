output "asg_name" {
  value       = try(aws_autoscaling_group.this[0].name, null)
  description = "The name of the Auto Scaling Group"

}

output "asg_arn" {
  value       = try(aws_autoscaling_group.this[0].arn, null)
  description = "The Amazon Resource Name (ARN) of the Auto Scaling Group"
}
