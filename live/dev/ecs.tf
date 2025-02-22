# ECS
module "ecs_cluster" {
  source         = "../../modules/aws/ecs"
  create_cluster = true
  name           = var.ecs_name

  cluster_settings = [
    {
      name  = "containerInsights"
      value = "enabled"
    }
  ]

  # Only cluster-related configurations here
  custom_tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

module "ecs_services" {
  source          = "../../modules/aws/ecs"
  for_each        = local.ecs_services
  create_services = true
  name            = "${var.project_name}-${each.key}"

  cluster_id   = module.ecs_cluster.cluster_id
  cluster_name = module.ecs_cluster.cluster_name

  # Container Definition (JSON-encoded)
  container_definitions = jsonencode(each.value.container_definitions)


  # Task Definition
  cpu                      = each.value.cpu
  memory                   = each.value.memory
  ecs_task_family_name     = "${each.key}-task"
  ecs_task_execution_role  = module.ecs_task_execution_role.role_arn
  network_mode             = "bridge"
  requires_compatibilities = ["EC2"]

  # EFS settings (if needed)
  mount_efs_volume = var.ecs_mount_efs_volume
  container_path   = var.ecs_container_path
  read_only        = var.ecs_read_only_container_volume

  # ECS Service
  desired_count             = each.value.desired_count
  scheduling_strategy       = "REPLICA"
  health_check_grace_period = 60

  # Load Balancer
  load_balancer = {
    service = {
      target_group_arn = module.alb.target_group_arns[each.value.target_group]
      container_name   = each.value.container_name
      container_port   = each.value.container_port
    }
  }

  # Capacity provider configuration
  capacity_provider_strategy = {
    "${each.value.capacity_provider.name}" = {
      weight = each.value.capacity_provider.weight
      base   = each.value.capacity_provider.base
    }
  }

  # Cluster capacity providers
  default_capacity_provider_use_fargate = false
  autoscaling_capacity_providers = {
    "${each.value.capacity_provider.name}" = {
      auto_scaling_group_arn         = each.value.capacity_provider.asg_arn
      managed_termination_protection = "DISABLED"
      managed_scaling = {
        maximum_scaling_step_size = 5
        minimum_scaling_step_size = 1
        status                    = "ENABLED"
        target_capacity           = 100
      }
      default_capacity_provider_strategy = {
        weight = each.value.capacity_provider.weight
        base   = each.value.capacity_provider.base
      }
    }
  }

  custom_tags = {
    Environment = var.environment
    Project     = var.project_name
    Service     = each.key
  }
}
