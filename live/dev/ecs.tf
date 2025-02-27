# ECS
module "ecs_cluster" {
  source         = "../../modules/aws/ecs"
  create_cluster = true
  name           = "ecs"

  cluster_settings = [
    {
      name  = "containerInsights"
      value = "enhanced" # Set to "enhanced" to view container level metrics. enabled - for service level and cluster
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
  name            = each.key

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
  runtime_platform = {
    cpu_architecture        = "X86_64"
    operating_system_family = "LINUX"
  }

  # # Network Configuration (required for network_mode set to awsvpc)
  # network_configuration = {
  #   subnets          = module.vpc.public_subnet_ids
  #   assign_public_ip = true
  #   security_groups = [
  #     module.ecs_sg.security_group_id
  #   ]
  # }


  # EFS settings (if needed)
  mount_efs_volume = false
  container_path   = "/"   # path on the container to mount the host volume at e.g. /app
  read_only        = false # read-only access to the volume

  # ECS Service
  desired_count             = each.value.desired_count
  scheduling_strategy       = "REPLICA"
  health_check_grace_period = 60

  # Deployment Type
  deployment_controller = {
    type = "CODE_DEPLOY" # Set to ECS, if don't want to use Codedeploy
  }

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
    (each.value.capacity_provider.name) = {
      weight = each.value.capacity_provider.weight
      base   = each.value.capacity_provider.base
    }
  }

  # Cluster capacity providers
  default_capacity_provider_use_fargate = false
  autoscaling_capacity_providers = {
    (each.value.capacity_provider.name) = {
      auto_scaling_group_arn         = each.value.capacity_provider.asg_arn
      managed_termination_protection = "DISABLED"
      # managed_scaling = {
      #   minimum_scaling_step_size = 1 # Scale out by minimum 1 instance
      #   maximum_scaling_step_size = 1 # Scale out by maximum 1 instance
      #   status                    = "ENABLED"
      #   target_capacity           = 85 # Use 85% of instance capacity before scaling
      # }
      default_capacity_provider_strategy = {
        weight = each.value.capacity_provider.weight
        base   = each.value.capacity_provider.base
      }
    }
  }

  # # Deployment Circuit Breaker (only supported with ECS (rolling update) deployment controller)
  # deployment_circuit_breaker = {
  #   enable   = true
  #   rollback = true
  # }

  custom_tags = {
    Environment = var.environment
    Project     = var.project_name
    Service     = each.key
  }
}
