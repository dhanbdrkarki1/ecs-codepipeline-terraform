# # ECS
# module "ecs" {
#   source = "../../modules/aws/ecs"
#   create = true
#   name   = var.ecs_name

#   # Cluster
#   cluster_settings = [
#     {
#       name  = "containerInsights"
#       value = "enabled" # Whether to enable Amazon ECS container insights on Cluster
#     }
#   ]

#   # Container Definition
#   container_definition_template = file("${path.root}/templates/ecs/container-definition.json.tpl")
#   # app_image                     = "${module.ecr.repository_url}:latest"
#   app_image = "public.ecr.aws/nginx/nginx:1.27-alpine3.21-slim"
#   # port mapping
#   container_port     = var.ecs_container_port
#   host_port          = 80
#   app_cpu            = var.ecs_app_cpu
#   app_memory         = var.ecs_app_memory
#   aws_region         = data.aws_region.current.name
#   container_name     = var.ecs_container_name
#   ecs_log_group_name = module.ecs_log_group.log_group_name
#   # EFS
#   mount_efs_volume = var.ecs_mount_efs_volume # if true, create efs and security group for efs
#   # efs_file_system_id = module.efs.id 
#   container_path = var.ecs_container_path             # path on the container to mount the host volume at e.g. /app
#   read_only      = var.ecs_read_only_container_volume # read-only access to the volume


#   # Task Definition
#   ecs_task_family_name     = var.ecs_task_family_name
#   ecs_task_execution_role  = module.ecs_task_execution_role.role_arn
#   network_mode             = "bridge" # Use bridge for EC2 launch type, For Fargate, use "Fargate"
#   requires_compatibilities = ["EC2"]
#   # cpu = <crate variable for overall task definition cpu allocatio>
#   # memory = <crate variable for overall task definition memory allocatio>


#   # ECS Service
#   desired_count             = 2
#   scheduling_strategy       = "REPLICA"
#   health_check_grace_period = 60
#   load_balancer = {
#     service = {
#       target_group_arn = module.alb.target_group_arns["ec2-instance"]
#       container_name   = var.ecs_container_name
#       container_port   = var.ecs_container_port
#     }
#   }
#   capacity_provider_strategy = {
#     "test-app-cp1" = {
#       weight = 1
#       base   = 2 # Set base to 2 to maintain minimum 2 instances
#     }
#   }

#   # Cluster capacity providers
#   # Capacity provider - autoscaling groups
#   default_capacity_provider_use_fargate = false
#   autoscaling_capacity_providers = {
#     # On-demand instances
#     test-app-cp1 = {
#       auto_scaling_group_arn = module.asg.asg_arn
#       # If ENABLED, need to enable protect_from_scale_in in asg
#       managed_termination_protection = "DISABLED"

#       managed_scaling = {
#         maximum_scaling_step_size = 5
#         minimum_scaling_step_size = 1
#         status                    = "ENABLED"
#         target_capacity           = 100 # ECS tries to maintain 60% cluster utilization. If it's seeing higher utilization, it will scale up.
#       }

#       default_capacity_provider_strategy = {
#         weight = 1
#         base   = 2 # Match this with your desired minimum
#       }
#     }
#   }

#   custom_tags = {
#     Environment = var.environment
#     Project     = var.project_name
#   }
# }

module "ecs_cluster" {
  source = "../../modules/aws/ecs"
  create = true
  name   = var.ecs_name

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


module "ecss" {
  source   = "../../modules/aws/ecs"
  for_each = local.ecs_services
  create   = true
  name     = var.ecs_name

  # Cluster
  cluster_settings = [
    {
      name  = "containerInsights"
      value = "enabled"
    }
  ]

  # Container Definition
  container_definition_template = file("${path.root}/templates/ecs/container-definition.json.tpl")
  app_image                     = each.value.app_image
  container_port                = each.value.container_port
  host_port                     = each.value.host_port
  app_cpu                       = each.value.app_cpu
  app_memory                    = each.value.app_memory
  aws_region                    = data.aws_region.current.name
  container_name                = each.value.container_name
  ecs_log_group_name            = module.ecs_log_group.log_group_name

  # EFS settings (if needed)
  mount_efs_volume = var.ecs_mount_efs_volume
  container_path   = var.ecs_container_path
  read_only        = var.ecs_read_only_container_volume

  # Task Definition
  ecs_task_family_name     = "${each.key}-task"
  ecs_task_execution_role  = module.ecs_task_execution_role.role_arn
  network_mode             = "bridge"
  requires_compatibilities = ["EC2"]

  # ECS Service
  desired_count             = each.value.desired_count
  scheduling_strategy       = "REPLICA"
  health_check_grace_period = 60

  load_balancer = {
    service = {
      target_group_arn = module.alb.target_group_arns[each.value.target_group]
      container_name   = each.value.container_name
      container_port   = each.value.container_port
    }
  }

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

