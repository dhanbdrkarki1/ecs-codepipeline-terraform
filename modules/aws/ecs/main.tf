#########
# ECS
#########
# ECS Cluster
resource "aws_ecs_cluster" "main" {
  count = var.create_cluster ? 1 : 0
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

# Task Definition
resource "aws_ecs_task_definition" "app" {
  count                    = var.create_services ? 1 : 0
  family                   = var.ecs_task_family_name
  execution_role_arn       = try(var.ecs_task_execution_role, null)
  network_mode             = var.network_mode
  requires_compatibilities = var.requires_compatibilities
  cpu                      = var.cpu
  memory                   = var.memory
  container_definitions    = var.container_definitions

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

  dynamic "runtime_platform" {
    for_each = length(var.runtime_platform) > 0 ? [var.runtime_platform] : []

    content {
      cpu_architecture        = try(runtime_platform.value.cpu_architecture, null)
      operating_system_family = try(runtime_platform.value.operating_system_family, null)
    }
  }

  tags = merge(
    { "Name" = "${local.name_prefix}" },
    var.custom_tags
  )
}

# ECS Service
resource "aws_ecs_service" "main" {
  count           = var.create_services ? 1 : 0
  name            = "${local.name_prefix}-service"
  cluster         = try(aws_ecs_cluster.main[0].id, var.cluster_id)
  task_definition = aws_ecs_task_definition.app[0].arn
  desired_count   = var.desired_count
  # Remove launch_type completely when using capacity providers
  # launch_type                       = var.launch_type
  scheduling_strategy               = var.scheduling_strategy
  health_check_grace_period_seconds = var.health_check_grace_period

  dynamic "load_balancer" {
    for_each = { for k, v in var.load_balancer : k => v }

    content {
      target_group_arn = try(load_balancer.value.target_group_arn, null)
      elb_name         = try(load_balancer.value.elb_name, null)
      container_name   = load_balancer.value.container_name
      container_port   = load_balancer.value.container_port
    }
  }

  dynamic "capacity_provider_strategy" {
    for_each = local.ecs_capacity_provider_names

    content {
      capacity_provider = capacity_provider_strategy.value
      weight            = try(var.capacity_provider_strategy[capacity_provider_strategy.value].weight, 1)
      base              = try(var.capacity_provider_strategy[capacity_provider_strategy.value].base, null)
    }
  }


  dynamic "network_configuration" {
    for_each = var.network_mode == "awsvpc" ? [var.network_configuration] : []

    content {
      assign_public_ip = network_configuration.value.assign_public_ip
      security_groups  = network_configuration.value.security_groups
      subnets          = network_configuration.value.subnets
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
