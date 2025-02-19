locals {
  name_prefix = "${var.custom_tags["Project"] != "" ? var.custom_tags["Project"] : "default-project"}-${var.custom_tags["Environment"] != "" ? var.custom_tags["Environment"] : "default-env"}-${var.name != "" ? var.name : "default-name"}"
}


# auto scaling group config
resource "aws_autoscaling_group" "this" {
  count = var.create ? 1 : 0
  name  = "${local.name_prefix}-asg"

  launch_template {
    id      = try(aws_launch_template.this[0].id, null)
    version = var.launch_template_version
  }
  min_size         = try(var.min_size, 0)
  max_size         = try(var.max_size, 0)
  desired_capacity = try(var.desired_capacity, 0)
  # used for zero-downtime deployment
  # Wait for at least this many instances to pass health checks before
  # considering the ASG deployment complete
  min_elb_capacity = var.min_size

  availability_zones  = var.availability_zones
  vpc_zone_identifier = var.vpc_zone_identifier

  target_group_arns         = values(var.target_group_arns)
  placement_group           = var.placement_group
  health_check_type         = var.health_check_type
  health_check_grace_period = var.health_check_grace_period

  dynamic "instance_refresh" {
    for_each = length(var.instance_refresh) > 0 ? [var.instance_refresh] : []
    content {
      strategy = instance_refresh.value.strategy
      triggers = try(instance_refresh.value.triggers, null)

      dynamic "preferences" {
        for_each = try([instance_refresh.value.preferences], [])
        content {
          checkpoint_delay             = try(preferences.value.checkpoint_delay, null)
          checkpoint_percentages       = try(preferences.value.checkpoint_percentages, null)
          instance_warmup              = try(preferences.value.instance_warmup, null)
          min_healthy_percentage       = try(preferences.value.min_healthy_percentage, null)
          max_healthy_percentage       = try(preferences.value.max_healthy_percentage, null)
          auto_rollback                = try(preferences.value.auto_rollback, null)
          scale_in_protected_instances = try(preferences.value.scale_in_protected_instances, null)
          skip_matching                = try(preferences.value.skip_matching, null)
          standby_instances            = try(preferences.value.standby_instances, null)
        }
      }
    }
  }

  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "Name"
    value               = try(local.name_prefix, var.name, null)
    propagate_at_launch = true
  }

  // default_tags (apply to all resources by default) set in provider don't work in asg
  dynamic "tag" {
    for_each = {
      for key, value in var.custom_tags :
      key => value
    }

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}


#---------------------------
# Auto Scaling Schedule
#---------------------------
resource "aws_autoscaling_schedule" "this" {
  for_each = var.create && var.create_schedule ? var.schedules : {}

  scheduled_action_name = each.key

  min_size         = try(each.value.min_size, null)
  max_size         = try(each.value.max_size, null)
  desired_capacity = try(each.value.desired_capacity, null)
  start_time       = try(each.value.start_time, null)
  end_time         = try(each.value.end_time, null)
  time_zone        = try(each.value.time_zone, null)

  recurrence             = try(each.value.recurrence, null)
  autoscaling_group_name = aws_autoscaling_group.this[0].name
}
