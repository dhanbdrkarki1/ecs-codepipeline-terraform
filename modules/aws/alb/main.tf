locals {
  name_prefix = "${var.custom_tags["Project"] != "" ? var.custom_tags["Project"] : "default-project"}-${var.custom_tags["Environment"] != "" ? var.custom_tags["Environment"] : "default-env"}-${var.name != "" ? var.name : "default-name"}"
}


resource "aws_lb" "lb" {
  count                      = var.create && !var.use_existing_load_balancer ? 1 : 0
  name                       = local.name_prefix
  internal                   = false
  load_balancer_type         = var.load_balancer_type
  security_groups            = var.security_groups_ids
  subnets                    = var.subnet_groups_ids
  enable_deletion_protection = false

  tags = merge(
    { "Name" = "${local.name_prefix}" },
    var.lb_tags,
    var.custom_tags
  )
}

# Load Balancer Listener with forward action
resource "aws_lb_listener" "this" {
  for_each          = { for k, v in var.listeners : k => v if var.create || var.use_existing_load_balancer }
  load_balancer_arn = var.use_existing_load_balancer ? var.existing_lb_arn : aws_lb.lb[0].arn
  port              = try(each.value.port, var.default_port)
  protocol          = try(each.value.protocol, var.default_protocol)
  ssl_policy        = contains(["HTTPS", "TLS"], try(each.value.protocol, var.default_protocol)) ? try(each.value.ssl_policy, "ELBSecurityPolicy-TLS13-1-2-Res-2021-06") : try(each.value.ssl_policy, null)
  certificate_arn   = try(each.value.certificate_arn, null)
  #   alpn_policy     = try(each.value.alpn_policy, null)

  # Fixed Response
  dynamic "default_action" {
    for_each = try([each.value.fixed_response], [])

    content {
      type  = "fixed-response"
      order = try(default_action.value.order, null)

      fixed_response {
        content_type = default_action.value.content_type
        message_body = try(default_action.value.message_body, null)
        status_code  = try(default_action.value.status_code, null)
      }
    }
  }

  # Redirect http to https
  dynamic "default_action" {
    for_each = try([each.value.redirect], [])

    content {
      type  = "redirect"
      order = try(default_action.value.order, null)

      redirect {
        port        = try(default_action.value.port, null)
        protocol    = try(default_action.value.protocol, null)
        status_code = default_action.value.status_code
        host        = try(default_action.value.host, null)
        path        = try(default_action.value.path, null)
        query       = try(default_action.value.query, null)
      }

    }
  }


  # Forward
  dynamic "default_action" {
    for_each = try([each.value.forward], [])

    content {
      order            = try(default_action.value.order, null)
      target_group_arn = try(aws_lb_target_group.this[default_action.value.target_group_key].arn, default_action.value.arn, null)
      type             = "forward"
    }
  }

  tags = merge(
    { "Name" = "${local.name_prefix}" },
    var.custom_tags
  )
}

# Listener Rule

locals {
  # This allows rules to be specified under the listener definition
  listener_rules = flatten([
    for listener_key, listener_values in var.listeners : [
      for rule_key, rule_values in lookup(listener_values, "rules", {}) :
      merge(rule_values, {
        listener_key = listener_key
        rule_key     = rule_key
      })
    ]
  ])
}

resource "aws_lb_listener_rule" "this" {
  for_each     = { for v in local.listener_rules : "${v.listener_key}/${v.rule_key}" => v if var.create || var.use_existing_load_balancer }
  listener_arn = try(each.value.listener_arn, aws_lb_listener.this[each.value.listener_key].arn)
  priority     = try(each.value.priority, null)

  dynamic "condition" {
    for_each = [for condition in each.value.conditions : condition if contains(keys(condition), "path_pattern")]

    content {
      dynamic "path_pattern" {
        for_each = try([condition.value.path_pattern], [])

        content {
          values = path_pattern.value.values
        }
      }
    }
  }

  dynamic "action" {
    for_each = [for action in each.value.actions : action if action.type == "forward"]

    content {
      type             = "forward"
      order            = try(action.value.order, null)
      target_group_arn = try(action.value.target_group_arn, aws_lb_target_group.this[action.value.target_group_key].arn, null)
    }
  }

  tags = merge(
    { "Name" = "${local.name_prefix}" },
    var.custom_tags
  )

  depends_on = [aws_lb_target_group.this]
}

resource "aws_lb_target_group" "this" {
  for_each    = { for k, v in var.target_groups : k => v if var.create || var.use_existing_load_balancer }
  name        = try(each.value.name, "${local.name_prefix}-tg")
  target_type = try(each.value.target_type, null)
  port        = try(each.value.container_port, each.value.port, var.default_port)
  protocol    = try(each.value.protocol, var.default_protocol)
  vpc_id      = try(each.value.vpc_id, var.vpc_id)

  connection_termination        = try(each.value.connection_termination, null)
  deregistration_delay          = try(each.value.deregistration_delay, null)
  load_balancing_algorithm_type = try(each.value.load_balancing_algorithm_type, null)

  dynamic "health_check" {
    for_each = try([each.value.health_check], [])

    content {
      enabled             = try(health_check.value.enabled, null)
      healthy_threshold   = try(health_check.value.healthy_threshold, null)
      unhealthy_threshold = try(health_check.value.unhealthy_threshold, null)
      interval            = try(health_check.value.interval, null)
      path                = try(health_check.value.path, null)
      matcher             = try(health_check.value.matcher, null)
      port                = try(health_check.value.port, null)
      protocol            = try(health_check.value.protocol, null)
      timeout             = try(health_check.value.timeout, null)
    }
  }

  tags = merge(
    { "Name" = "${local.name_prefix}" },
    var.custom_tags
  )

  lifecycle {
    create_before_destroy = true
  }
}
