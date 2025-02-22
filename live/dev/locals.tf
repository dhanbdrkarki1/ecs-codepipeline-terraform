locals {
  # AWS Account ID
  account_id = "664418970145"
  ecs_ami_id = jsondecode(data.aws_ssm_parameter.ecs_optimized_ami.value)["image_id"]

  # ASG Services
  asg_services = {
    "nginx" = {
      name             = "nginx"
      instance_type    = "t3.large" # "t3.large" has 8 GiB memory
      min_size         = 2
      desired_capacity = 2
      max_size         = 4
      volume_size      = 30
    },
    "rep_dashboard" = {
      name             = "rep-dashboard"
      instance_type    = "t3.medium" // t3.medium has 4 GiB total memory 
      min_size         = 1
      desired_capacity = 1
      max_size         = 3
      volume_size      = 50
    }
  }
  # Target Groups

  # Listener Rules

  # ECS Services
  ecs_services = {
    nginx = {
      desired_count = 2
      cpu           = 1024
      memory        = 2048 // Reduce to 2 GiB per task

      # Container definition(s)
      container_definitions = [
        {
          name      = "nginx"
          cpu       = 256
          memory    = 512
          essential = true
          image     = "public.ecr.aws/nginx/nginx:1.27-alpine3.21-slim"
          # healthCheck = { # Changed from health_check to healthCheck
          #   command = ["CMD-SHELL", "curl -f http://localhost:80/health || exit 1"]
          # }
          portMappings = [
            {
              containerPort = 80
              hostPort      = 80
              protocol      = "tcp"
            }
          ]
          readonlyRootFilesystem = false
          logConfiguration = {
            logDriver = "awslogs"
            options = {
              "awslogs-group"         = module.ecs_log_group.log_group_name
              "awslogs-region"        = data.aws_region.current.name
              "awslogs-stream-prefix" = "nginx"
            }
          }
          memoryReservation = 100
        }
      ]
      container_name = "nginx"
      container_port = 80
      target_group   = "nginx"
      capacity_provider = {
        name    = "nginx-cp"
        asg_arn = module.asgs["nginx"].asg_arn
        weight  = 1
        base    = 2
      }
    }
    rep_dashboard = {
      desired_count = 2
      cpu           = 1024 // 1 vCPU
      memory        = 2048 // 2 GiB for task

      container_definitions = [
        {
          name      = "rep-dashboard"
          cpu       = 256
          memory    = 512 // Container memory
          essential = true
          image     = "public.ecr.aws/e1z1p8n3/dhan/rep-dashboard:latest"
          # healthCheck = {
          #   command = ["CMD-SHELL", "curl -f http://localhost:80/health || exit 1"]
          # }
          portMappings = [
            {
              containerPort = 80
              hostPort      = 80
              protocol      = "tcp"
            }
          ]
          readonlyRootFilesystem = false
          logConfiguration = {
            logDriver = "awslogs"
            options = {
              "awslogs-group"         = module.ecs_log_group.log_group_name
              "awslogs-region"        = data.aws_region.current.name
              "awslogs-stream-prefix" = "rep-dashboard"
            }
          }
          memoryReservation = 100
        }
      ]
      container_name = "rep-dashboard"
      container_port = 80
      target_group   = "rep_dashboard"
      capacity_provider = {
        name    = "rep-dashboard-cp"
        asg_arn = module.asgs["rep_dashboard"].asg_arn
        weight  = 1
        base    = 1
      }
    }
  }
}

