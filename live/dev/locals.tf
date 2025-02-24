locals {
  ecs_ami_id = jsondecode(data.aws_ssm_parameter.ecs_optimized_ami.value)["image_id"]

  ###########################
  # Auto Scaling Groups
  ###########################
  asg_services = {
    group-dashboard = {
      name             = "group-dashboard"
      instance_type    = "t3.large" # "t3.large" has 8 GiB memory
      min_size         = 2
      desired_capacity = 2
      max_size         = 4
      volume_size      = 30
    }
    # rep-dashboard = {
    #   name             = "rep-dashboard"
    #   instance_type    = "t3.medium" // t3.medium has 4 GiB total memory 
    #   min_size         = 2
    #   desired_capacity = 2
    #   max_size         = 3
    #   volume_size      = 50
    # }
  }

  ###########################
  # Application Load Balancer
  ###########################

  # Target Groups
  alb_target_groups = {
    group-dashboard = {
      name                 = "group-dashboard-tg"
      protocol             = "HTTP"
      port                 = 80
      target_type          = "instance"
      deregistration_delay = 10

      health_check = {
        enabled             = true
        interval            = 60
        path                = "/"
        port                = "traffic-port"
        healthy_threshold   = 2
        unhealthy_threshold = 2
        timeout             = 30
        protocol            = "HTTP"
        matcher             = "200-399"
      }
    }
    # rep-dashboard = {
    #   name                 = "rep-dashboard-tg"
    #   protocol             = "HTTP"
    #   port                 = 80
    #   target_type          = "instance"
    #   deregistration_delay = 10

    #   health_check = {
    #     enabled             = true
    #     interval            = 60
    #     path                = "/"
    #     port                = "traffic-port"
    #     healthy_threshold   = 2
    #     unhealthy_threshold = 2
    #     timeout             = 30
    #     protocol            = "HTTP"
    #     matcher             = "200-399"
    #   }
    # }
  }

  # Listener Rules
  alb_listeners = {
    fixed-response = {
      port     = 80
      protocol = "HTTP"
      fixed_response = {
        content_type = "text/plain"
        message_body = "404: page not found"
        status_code  = "404"
      }

      rules = {
        # Group Dashboard
        group-dashboard = {
          priority = 200
          actions = [
            {
              type             = "forward"
              target_group_arn = try(module.alb.target_group_arns["group-dashboard"], null)
            }
          ]
          conditions = [{
            host_header = {
              values = ["test-nginx.karkidhan.com.np"]
            }
          }]
        }
        # # Rep Dashboard
        # rep-dashboard = {
        #   priority = 300
        #   actions = [
        #     {
        #       type             = "forward"
        #       target_group_arn = try(module.alb.target_group_arns["rep-dashboard"], null)
        #     }
        #   ]
        #   conditions = [{
        #     host_header = {
        #       values = ["rep-dashboard.karkidhan.com.np"]
        #     }
        #   }]
        # }
      }
    }
  }

  ###########################
  # Cloudwatch Log Groups
  ###########################
  log_groups = {
    # Dashboard
    group-dashboard = {
      name              = "/ecs/service/group-dashboard"
      retention_in_days = 30
    }
    # rep-dashboard = {
    #   name              = "/ecs/service/rep-dashboard"
    #   retention_in_days = 30
    # }
  }

  ###########################
  # ECS
  ###########################
  # ECS Services
  ecs_services = {
    group-dashboard = {
      desired_count     = 2
      cpu               = 1024
      memory            = 2048 // Reduce to 2 GiB per task
      memoryReservation = 256

      # Container definition(s)
      container_definitions = [
        {
          name      = "group-dashboard"
          cpu       = 256
          memory    = 512
          essential = true
          image     = "public.ecr.aws/e1z1p8n3/dhan/group-app-web:latest"
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
              "awslogs-group"         = module.cloudwatch_log_groups["group-dashboard"].log_group_name
              "awslogs-region"        = data.aws_region.current.name
              "awslogs-stream-prefix" = "group-dashboard"
            }
          }
        }
      ]
      container_name = "group-dashboard"
      container_port = 80
      target_group   = "group-dashboard"
      capacity_provider = {
        name    = "group-dashboard-cp"
        asg_arn = module.asgs["group-dashboard"].asg_arn
        weight  = 1
        base    = 1
      }
    }
    # rep-dashboard = {
    #   desired_count     = 2
    #   cpu               = 1024 // 1 vCPU
    #   memory            = 1536 // 1.5 GiB instead of 2 GiB
    #   memoryReservation = 256

    #   container_definitions = [
    #     {
    #       name      = "rep-dashboard"
    #       cpu       = 256
    #       memory    = 512 // Container memory
    #       essential = true
    #       image     = "public.ecr.aws/e1z1p8n3/dhan/rep-dashboard:latest"
    #       # healthCheck = {
    #       #   command = ["CMD-SHELL", "curl -f http://localhost:80/health || exit 1"]
    #       # }
    #       portMappings = [
    #         {
    #           containerPort = 80
    #           hostPort      = 80
    #           protocol      = "tcp"
    #         }
    #       ]
    #       readonlyRootFilesystem = false
    #       logConfiguration = {
    #         logDriver = "awslogs"
    #         options = {
    #           "awslogs-group"         = module.cloudwatch_log_groups["rep-dashboard"].log_group_name
    #           "awslogs-region"        = data.aws_region.current.name
    #           "awslogs-stream-prefix" = "rep-dashboard"
    #         }
    #       }
    #     }
    #   ]
    #   container_name = "rep-dashboard"
    #   container_port = 80
    #   target_group   = "rep-dashboard"
    #   capacity_provider = {
    #     name    = "rep-dashboard-cp"
    #     asg_arn = module.asgs["rep-dashboard"].asg_arn
    #     weight  = 100
    #     base    = 1
    #   }
    # }
  }
}

