#-----------------------
# ECS Auto Scaling
#-----------------------

resource "aws_appautoscaling_target" "target" {
  count = var.create ? 1 : 0
  service_namespace  = var.service_namespace
  resource_id        = "service/${aws_ecs_cluster.main[0].name}/${aws_ecs_service.main[0].name}"
  scalable_dimension = var.scalable_dimension
  role_arn           = aws_iam_role.ecs_auto_scale_role[0].arn
  min_capacity       = var.min_capacity
  max_capacity       = var.max_capacity
  tags = merge(
    { "Name" = "${local.name_prefix}" },
    var.custom_tags
  )
}

# Automatically scale capacity up by one
resource "aws_appautoscaling_policy" "up" {
  count = var.create ? 1 : 0
  name               = "${local.name_prefix}-scale-up"
  service_namespace  = var.service_namespace
  resource_id        = "service/${aws_ecs_cluster.main[0].name}/${aws_ecs_service.main[0].name}"
  scalable_dimension = var.scalable_dimension

  step_scaling_policy_configuration {
    adjustment_type         = var.step_scaling_adjustment_type
    cooldown                = var.cooldown_period
    metric_aggregation_type = var.step_scaling_metric_aggregation_type

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = var.scale_up_adjustment
    }
  }

  depends_on = [aws_appautoscaling_target.target]
}

# Automatically scale capacity down by one
resource "aws_appautoscaling_policy" "down" {
  count = var.create ? 1 : 0
  name               = "${local.name_prefix}-scale-down"
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.main[0].name}/${aws_ecs_service.main[0].name}"
  scalable_dimension = var.scalable_dimension

  step_scaling_policy_configuration {
    adjustment_type         = var.step_scaling_adjustment_type
    cooldown                = var.cooldown_period
    metric_aggregation_type = var.step_scaling_metric_aggregation_type

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = var.scale_down_adjustment
    }
  }

  depends_on = [aws_appautoscaling_target.target]
}


