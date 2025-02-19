#########
# ECS
#########
resource "aws_ecs_cluster" "main" {
  count = var.create ? 1 : 0
  name  = local.name_prefix

  dynamic "service_connect_defaults" {
    for_each = length(var.cluster_service_connect_defaults) > 0 ? [var.cluster_service_connect_defaults] : []

    content {
      namespace = service_connect_defaults.value.namespace
    }
  }

  dynamic "setting" {
    for_each = flatten([var.cluster_settings])

    content {
      name  = setting.value.name
      value = setting.value.value
    }
  }

  tags = merge(
    { "Name" = "${local.name_prefix}" },
    var.ecs_tags,
    var.custom_tags
  )
}

data "template_file" "container-definition" {
  count    = var.create ? 1 : 0
  template = var.container_definition_template
  vars = {
    app_image      = var.app_image
    container_port = var.container_port
    app_cpu        = var.app_cpu
    app_memory     = var.app_memory
    aws_region     = var.aws_region
    container_name = var.container_name
    log_group_name = var.ecs_log_group_name

    # volume mount
    mount_points = local.mount_points
  }
}


resource "aws_ecs_task_definition" "app" {
  count                    = var.create ? 1 : 0
  family                   = var.ecs_task_family_name
  execution_role_arn       = try(var.ecs_task_execution_role, null)
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.app_cpu
  memory                   = var.app_memory
  container_definitions    = element(data.template_file.container-definition.*.rendered, count.index)

  dynamic "volume" {
    for_each = var.mount_efs_volume ? [1] : []
    content {
      name = local.source_volume_name

      efs_volume_configuration {
        file_system_id          = var.efs_file_system_id
        root_directory          = var.volume_root_directory
        transit_encryption      = var.enable_transit_encryption
        transit_encryption_port = var.transit_encryption_port
      }
    }
  }

  tags = merge(
    { "Name" = "${local.name_prefix}" },
    var.custom_tags
  )
}


resource "aws_ecs_service" "main" {
  count                             = var.create ? 1 : 0
  name                              = "${local.name_prefix}-service"
  cluster                           = aws_ecs_cluster.main[0].id
  task_definition                   = aws_ecs_task_definition.app[0].arn
  desired_count                     = var.desired_container_count
  launch_type                       = var.launch_type
  scheduling_strategy               = var.scheduling_strategy
  health_check_grace_period_seconds = var.health_check_grace_period

  dynamic "network_configuration" {
    for_each = var.network_mode == "awsvpc" ? [local.network_configuration] : []

    content {
      assign_public_ip = network_configuration.value.assign_public_ip
      security_groups  = network_configuration.value.security_groups
      subnets          = network_configuration.value.subnets
    }
  }

  # network_configuration {
  #   security_groups  = var.security_groups_ids
  #   subnets          = var.subnet_groups_ids
  #   assign_public_ip = false
  # }

  # load_balancer {
  #   target_group_arn = var.target_group
  #   container_name   = var.container_name
  #   container_port   = var.container_port
  # }

  # deployment_circuit_breaker {
  #   enable   = var.enable_deployment_circuit_breaker
  #   rollback = var.enable_deployment_circuit_breaker_rollback
  # }
  # deployment_controller {
  #   type = var.deployment_controller_type
  # }

  dynamic "load_balancer" {
    for_each = { for k, v in var.load_balancer : k => v }

    content {
      container_name   = load_balancer.value.container_name
      container_port   = load_balancer.value.container_port
      elb_name         = try(load_balancer.value.elb_name, null)
      target_group_arn = try(load_balancer.value.target_group_arn, null)
    }
  }

  dynamic "deployment_circuit_breaker" {
    for_each = length(var.deployment_circuit_breaker) > 0 ? [var.deployment_circuit_breaker] : []

    content {
      enable   = deployment_circuit_breaker.value.enable
      rollback = deployment_circuit_breaker.value.rollback
    }
  }

  dynamic "deployment_controller" {
    for_each = length(var.deployment_controller) > 0 ? [var.deployment_controller] : []

    content {
      type = try(deployment_controller.value.type, null)
    }
  }

  tags = merge(
    { "Name" = "${local.name_prefix}" },
    var.custom_tags
  )
}


################################################################################
# Cluster Capacity Providers
################################################################################

locals {
  default_capacity_providers = merge(
    { for k, v in var.fargate_capacity_providers : k => v if var.default_capacity_provider_use_fargate },
    { for k, v in var.autoscaling_capacity_providers : k => v if !var.default_capacity_provider_use_fargate }
  )
}

resource "aws_ecs_cluster_capacity_providers" "this" {
  count = var.create && length(merge(var.fargate_capacity_providers, var.autoscaling_capacity_providers)) > 0 ? 1 : 0

  cluster_name = aws_ecs_cluster.this[0].name
  capacity_providers = distinct(concat(
    [for k, v in var.fargate_capacity_providers : try(v.name, k)],
    [for k, v in var.autoscaling_capacity_providers : try(v.name, k)]
  ))

  # https://docs.aws.amazon.com/AmazonECS/latest/developerguide/cluster-capacity-providers.html#capacity-providers-considerations
  dynamic "default_capacity_provider_strategy" {
    for_each = local.default_capacity_providers
    iterator = strategy

    content {
      capacity_provider = try(strategy.value.name, strategy.key)
      base              = try(strategy.value.default_capacity_provider_strategy.base, null)
      weight            = try(strategy.value.default_capacity_provider_strategy.weight, null)
    }
  }

  depends_on = [
    aws_ecs_capacity_provider.this
  ]
}

################################################################################
# Capacity Provider - Autoscaling Group(s)
################################################################################

resource "aws_ecs_capacity_provider" "this" {
  for_each = { for k, v in var.autoscaling_capacity_providers : k => v if var.create }

  name = try(each.value.name, each.key)

  auto_scaling_group_provider {
    auto_scaling_group_arn = each.value.auto_scaling_group_arn
    # When you use managed termination protection, you must also use managed scaling otherwise managed termination protection won't work
    managed_termination_protection = length(try([each.value.managed_scaling], [])) == 0 ? "DISABLED" : try(each.value.managed_termination_protection, null)

    dynamic "managed_scaling" {
      for_each = try([each.value.managed_scaling], [])

      content {
        instance_warmup_period    = try(managed_scaling.value.instance_warmup_period, null)
        maximum_scaling_step_size = try(managed_scaling.value.maximum_scaling_step_size, null)
        minimum_scaling_step_size = try(managed_scaling.value.minimum_scaling_step_size, null)
        status                    = try(managed_scaling.value.status, null)
        target_capacity           = try(managed_scaling.value.target_capacity, null)
      }
    }
  }

  tags = merge(
    { "Name" = "${local.name_prefix}" },
    var.custom_tags
  )
}
