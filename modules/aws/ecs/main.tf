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

  network_configuration {
    security_groups  = var.security_groups_ids
    subnets          = var.subnet_groups_ids
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.target_group
    container_name   = var.container_name
    container_port   = var.container_port
  }

  deployment_circuit_breaker {
    enable   = var.enable_deployment_circuit_breaker
    rollback = var.enable_deployment_circuit_breaker_rollback
  }
  deployment_controller {
    type = var.deployment_controller_type
  }

  tags = merge(
    { "Name" = "${local.name_prefix}" },
    var.custom_tags
  )
}
