# #-------------------------------------------
# # CloudWatch Alarm ECS Auto Scaling
# #-------------------------------------------

# # CloudWatch alarm that triggers the autoscaling up policy
# resource "aws_cloudwatch_metric_alarm" "service_cpu_high" {
#   count               = var.create ? 1 : 0
#   alarm_name          = "${local.name_prefix}-cpu-utilization-high"
#   comparison_operator = "GreaterThanOrEqualToThreshold"
#   evaluation_periods  = "2"
#   metric_name         = "CPUUtilization"
#   namespace           = "AWS/ECS"
#   period              = "60"
#   statistic           = "Average"
#   threshold           = "85"

#   dimensions = {
#     ClusterName = aws_ecs_cluster.main[0].name
#     ServiceName = aws_ecs_service.main[0].name
#   }

#   alarm_actions = [aws_appautoscaling_policy.up[0].arn]
#   tags = merge(
#     { "Name" = "${local.name_prefix}" },
#     var.ecs_tags,
#     var.custom_tags
#   )
# }

# # CloudWatch alarm that triggers the autoscaling down policy
# resource "aws_cloudwatch_metric_alarm" "service_cpu_low" {
#   count               = var.create ? 1 : 0
#   alarm_name          = "${local.name_prefix}-cpu-utilization-low"
#   comparison_operator = "LessThanOrEqualToThreshold"
#   evaluation_periods  = "2"
#   metric_name         = "CPUUtilization"
#   namespace           = "AWS/ECS"
#   period              = "60"
#   statistic           = "Average"
#   threshold           = "5"

#   dimensions = {
#     ClusterName = aws_ecs_cluster.main[0].name
#     ServiceName = aws_ecs_service.main[0].name
#   }

#   alarm_actions = [aws_appautoscaling_policy.down[0].arn]
#   tags = merge(
#     { "Name" = "${local.name_prefix}" },
#     var.ecs_tags,
#     var.custom_tags
#   )
# }
