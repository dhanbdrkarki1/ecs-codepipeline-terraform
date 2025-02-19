#########
# ECS
#########

locals {
  name_prefix    = "${var.custom_tags["Project"] != "" ? var.custom_tags["Project"] : "default-project"}-${var.custom_tags["Environment"] != "" ? var.custom_tags["Environment"] : "default-env"}-${var.name != "" ? var.name : "default-name"}-cluster"
  log_group_name = "ecs/${local.name_prefix}"
  # new relic
  new_relic_log_group_name = "newrelic/${local.name_prefix}"

  # Calculating the required fargate_cpu and fargate_memory based on the container specification for app and new relic.
  fargate_cpu    = var.enable_newrelic_monitoring ? var.app_cpu + var.new_relic_cpu : var.app_cpu
  fargate_memory = var.enable_newrelic_monitoring ? var.app_memory + var.new_relic_memory : var.app_memory

  # for efs volume
  source_volume_name = var.mount_efs_volume ? "${var.name != "" ? var.name : "default-name"}-efs-volume" : null
  mount_points = var.mount_efs_volume ? jsonencode([{
    "sourceVolume"  = local.source_volume_name,
    "containerPath" = var.container_path
    "readOnly"      = var.read_only
  }]) : jsonencode([])
}

resource "aws_ecs_cluster" "main" {
  count = var.create ? 1 : 0
  name  = local.name_prefix

  setting {
    name  = "containerInsights"
    value = var.enable_container_insights ? "enabled" : "disabled"
  }
  tags = merge(
    { "Name" = "${local.name_prefix}" },
    var.ecs_tags,
    var.custom_tags
  )
}

data "template_file" "container-definition" {
  count    = var.create ? 1 : 0
  template = file("${path.module}/templates/ecs/container-definition.json.tpl")
  vars = {
    app_image      = var.app_image
    container_port = var.container_port
    app_cpu        = var.app_cpu
    app_memory     = var.app_memory
    aws_region     = var.aws_region
    container_name = var.container_name
    log_group_name = local.log_group_name

    # volume mount
    mount_points = local.mount_points

    #monitoring
    enable_newrelic_monitoring = var.enable_newrelic_monitoring
    new_relic_image            = var.new_relic_image
    new_relic_cpu              = var.new_relic_cpu
    new_relic_memory           = var.new_relic_memory
    new_relic_log_group_name   = local.new_relic_log_group_name

    # ssm for new relic
    ssm_license_parameter_name = var.enable_newrelic_monitoring ? element(data.aws_ssm_parameter.new_relic_secret[*].name, 0) : ""
  }
}


resource "aws_ecs_task_definition" "app" {
  count                    = var.create ? 1 : 0
  family                   = var.ecs_task_family_name
  execution_role_arn       = aws_iam_role.task_execution_role[0].arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = local.fargate_cpu
  memory                   = local.fargate_memory
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
  launch_type                       = "FARGATE"
  scheduling_strategy               = "REPLICA"
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
