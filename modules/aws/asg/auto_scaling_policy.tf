# Scaling Policies
resource "aws_autoscaling_policy" "dynamic_scaling_policies" {
  for_each = var.create_auto_scaling_policy ? var.auto_scaling_policies : {}

  name                      = "${local.name_prefix}-${each.key}"
  autoscaling_group_name    = try(aws_autoscaling_group.this[0].name, null)
  policy_type               = each.value.policy_type
  estimated_instance_warmup = each.value.estimated_instance_warmup

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = each.value.metric_type
      resource_label         = try(each.value.resource_label, null) # required for ALBRequestCountPerTarget
    }

    target_value = each.value.target_value
  }
}
