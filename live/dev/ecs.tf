# ECS
module "ecs" {
  source = "../../modules/aws/ecs"
  create = true
  name   = var.ecs_name

  # Cluster
  cluster_settings = [
    {
      name  = "containerInsights"
      value = "enabled" # Whether to enable Amazon ECS container insights on Cluster
    }
  ]

  # Container Definition
  container_definition_template = file("${path.root}/templates/ecs/container-definition.json.tpl")
  # app_image                     = "${module.ecr.repository_url}:latest"
  app_image = "public.ecr.aws/nginx/nginx:1.27-alpine3.21-slim"
  # port mapping
  container_port     = var.ecs_container_port
  host_port          = 80
  app_cpu            = var.ecs_app_cpu
  app_memory         = var.ecs_app_memory
  aws_region         = data.aws_region.current.name
  container_name     = var.ecs_container_name
  ecs_log_group_name = module.ecs_log_group.log_group_name
  # EFS
  mount_efs_volume = var.ecs_mount_efs_volume # if true, create efs and security group for efs
  # efs_file_system_id = module.efs.id 
  container_path = var.ecs_container_path             # path on the container to mount the host volume at e.g. /app
  read_only      = var.ecs_read_only_container_volume # read-only access to the volume


  # Task Definition
  ecs_task_family_name     = var.ecs_task_family_name
  ecs_task_execution_role  = module.ecs_task_execution_role.role_arn
  network_mode             = "bridge" # Use bridge for EC2 launch type, For Fargate, use "Fargate"
  requires_compatibilities = ["EC2"]
  # cpu = <crate variable for overall task definition cpu allocatio>
  # memory = <crate variable for overall task definition memory allocatio>


  # ECS Service
  desired_count             = 2
  scheduling_strategy       = "REPLICA"
  health_check_grace_period = 60
  load_balancer = {
    service = {
      target_group_arn = module.alb.target_group_arns["ec2-instance"]
      container_name   = var.ecs_container_name
      container_port   = var.ecs_container_port
    }
  }
  capacity_provider_strategy = {
    "test-app-cp1" = {
      weight = 1
      base   = 2 # Set base to 2 to maintain minimum 2 instances
    }
  }

  # Cluster capacity providers
  # Capacity provider - autoscaling groups
  default_capacity_provider_use_fargate = false
  autoscaling_capacity_providers = {
    # On-demand instances
    test-app-cp1 = {
      auto_scaling_group_arn = module.asg.asg_arn
      # If ENABLED, need to enable protect_from_scale_in in asg
      managed_termination_protection = "DISABLED"

      managed_scaling = {
        maximum_scaling_step_size = 5
        minimum_scaling_step_size = 1
        status                    = "ENABLED"
        target_capacity           = 100 # ECS tries to maintain 60% cluster utilization. If it's seeing higher utilization, it will scale up.
      }

      default_capacity_provider_strategy = {
        weight = 1
        base   = 2 # Match this with your desired minimum
      }
    }
  }

  custom_tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}
