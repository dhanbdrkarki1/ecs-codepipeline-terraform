locals {
  ecs_ami_id = jsondecode(data.aws_ssm_parameter.ecs_optimized_ami.value)["image_id"]

  domain_name = "*.karkidhan.com.np"

  ###########################
  # Auto Scaling Groups
  ###########################
  asg_services = {
    group-dashboard = {
      name             = "group-dashboard"
      instance_type    = "t3.small" # 2 vCPU (2048 CPU units), 2GB (2048 MB) memory
      min_size         = 1
      desired_capacity = 1
      max_size         = 2
      volume_size      = 30
    }
  }

  ###########################
  # Application Load Balancer
  ###########################

  # Target Groups
  alb_target_groups = {
    # Blue
    group-dashboard = {
      name                 = "group-dashboard-tg"
      protocol             = "HTTP"
      port                 = 80
      target_type          = "instance"
      deregistration_delay = 10

      health_check = {
        enabled             = true           # Enables health checks for the target group
        interval            = 60             # Time in seconds between each health check. Every 60 seconds, AWS will send a health check request
        path                = "/"            # The endpoint AWS will call to check health. In this case, it's checking the root path
        port                = "traffic-port" # Which port to use for health checks. "traffic-port" means use the same port as your application
        healthy_threshold   = 2              # Number of consecutive successful health checks. required before considering an unhealthy target healthy. Here, needs 2 successful checks to mark as healthy
        unhealthy_threshold = 2              # Number of consecutive failed health checks. required before considering a healthy target unhealthy. Here, needs 2 failed checks to mark as unhealthy
        timeout             = 5              # Number of seconds to wait for a response. If no response within 5 seconds, counts as a failed check
        protocol            = "HTTP"         # Protocol to use for health checks. Could also be HTTPS, TCP, etc.
        matcher             = "200-399"      # HTTP response codes that count as successful. Any response code between 200-399 is considered healthy
      }
    }
    group-dashboard-green = {
      name                 = "group-dashboard-green-tg"
      protocol             = "HTTP"
      port                 = 8080
      target_type          = "instance"
      deregistration_delay = 10

      health_check = {
        enabled             = true           # Enables health checks for the target group
        interval            = 60             # Time in seconds between each health check. Every 60 seconds, AWS will send a health check request
        path                = "/"            # The endpoint AWS will call to check health. In this case, it's checking the root path
        port                = "traffic-port" # Which port to use for health checks. "traffic-port" means use the same port as your application
        healthy_threshold   = 2              # Number of consecutive successful health checks. required before considering an unhealthy target healthy. Here, needs 2 successful checks to mark as healthy
        unhealthy_threshold = 2              # Number of consecutive failed health checks. required before considering a healthy target unhealthy. Here, needs 2 failed checks to mark as unhealthy
        timeout             = 5              # Number of seconds to wait for a response. If no response within 5 seconds, counts as a failed check
        protocol            = "HTTP"         # Protocol to use for health checks. Could also be HTTPS, TCP, etc.
        matcher             = "200-399"      # HTTP response codes that count as successful. Any response code between 200-399 is considered healthy
      }
    }
  }

  # Listener Rules (Blue)
  alb_listeners = {
    # HTTPS Production Listener
    https = {
      port       = 443
      protocol   = "HTTPS"
      ssl_policy = "ELBSecurityPolicy-TLS13-1-2-2021-06"
      # certificate_arn = module.acm.certificate_arn
      certificate_arn = data.aws_acm_certificate.amazon_issued.arn
      fixed_response = {
        content_type = "text/plain"
        message_body = "404: page not found"
        status_code  = "404"
      }
      rules = {
        group-dashboard = {
          priority = 100
          actions = [
            {
              type             = "forward"
              target_group_arn = try(module.alb.target_group_arns["group-dashboard"], null)
            }
          ]
          conditions = [{
            host_header = {
              values = ["group-dashboard.karkidhan.com.np"]
            }
          }]
        }
      }
    }

    # HTTPS Test Listener (Green)
    https-test = {
      port       = 8443 # Different port for test traffic
      protocol   = "HTTPS"
      ssl_policy = "ELBSecurityPolicy-TLS13-1-2-2021-06"
      # certificate_arn = module.acm.certificate_arn
      certificate_arn = data.aws_acm_certificate.amazon_issued.arn
      fixed_response = {
        content_type = "text/plain"
        message_body = "404: page not found"
        status_code  = "404"
      }
      rules = {
        group-dashboard-green = {
          priority = 100
          actions = [
            {
              type             = "forward"
              target_group_arn = try(module.alb.target_group_arns["group-dashboard-green"], null)
            }
          ]
          conditions = [{
            host_header = {
              values = ["test-group-dashboard.karkidhan.com.np"]
            }
          }]
        }
      }
    }

    # Redirect http to https
    http-to-https = {
      port     = 80
      protocol = "HTTP"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
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

    # ECS Execute Command Configuration - keeps an audit trail of all commands executed within the containers
    ecs-exec-command = {
      name              = "/aws/ecs/exec-command-logs"
      retention_in_days = 30
    }
  }

  ###########################
  # ECS
  ###########################
  # ECS Services
  ecs_services = {
    group-dashboard = {
      desired_count = 1
      cpu           = 512
      memory        = 512

      # Container definition(s)
      container_definitions = [
        {
          name              = "group-dashboard"
          cpu               = 512
          memory            = 512
          memoryReservation = 256 # Ensures memory flexibility & prevents out-of-memory kills.
          essential         = true
          image             = "public.ecr.aws/e1z1p8n3/dhan/group-app-web:latest"
          # healthCheck = { # Changed from health_check to healthCheck
          #   command     = ["CMD-SHELL", "curl -f http://localhost:80/health || exit 1"]
          #   interval    = 30
          #   timeout     = 5
          #   retries     = 3
          #   startPeriod = 60 # Give enough time for application to start
          # }

          # Regular environment variables
          # environment = [
          #   {
          #     name  = "NODE_ENV"
          #     value = "production"
          #   },
          #   {
          #     name  = "PORT"
          #     value = "80"
          #   }
          # ]

          # Sensitive environment (update task role permission if used)
          # secrets = [
          #   {
          #     name      = "DB_PASSWORD"
          #     valueFrom = ""
          #   }
          # ]
          portMappings = [
            {
              containerPort = 80
              hostPort      = 80 # no need if network mode is set to awsvpc
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
        weight  = 100
        base    = 0 # Setting base to 0 lets ECS scale based on actual need. The capacity provider with base = 1 tells ECS to maintain at least one instance worth of capacity
      }
    }
  }

  # CodeDeploy Load Balancer
  load_balancer_info = {
    target_group_pair_info = {
      # Production Listener
      prod_traffic_route = {
        listener_arns = [module.alb.listener_arns["https"]]
      }
      # Test Listener
      test_traffic_route = {
        listener_arns = [module.alb.listener_arns["https-test"]]
      }
      # Blue Target Group
      blue_target_group = {
        name = "group-dashboard-tg"
      }
      # Green Target Group
      green_target_group = {
        name = "group-dashboard-green-tg"
      }
    }
  }
}


