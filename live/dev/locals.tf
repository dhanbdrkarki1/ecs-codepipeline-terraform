locals {
  # AWS Account and Region Information
  account_id = data.aws_caller_identity.current.account_id                            # Current AWS account ID
  aws_region = data.aws_region.current.name                                           # Current AWS region
  ecs_ami_id = jsondecode(data.aws_ssm_parameter.ecs_optimized_ami.value)["image_id"] # Latest ECS-optimized AMI ID

  # Domain Name for ALB Listeners
  domain_name = "*.karkidhan.com.np" # Wildcard domain for ALB listener rules

  ###########################
  # Auto Scaling Groups (ASG)
  ###########################
  asg_services = {
    group-dashboard = {
      name             = "group-dashboard" # Name of the ASG
      instance_type    = "t3.small"        # Instance type: t3.small (2 vCPU, 2GB memory)
      min_size         = 1                 # Minimum number of instances
      desired_capacity = 1                 # Desired number of instances
      max_size         = 2                 # Maximum number of instances
      volume_size      = 30                # Root volume size in GB
    }
  }

  ###########################
  # Application Load Balancer (ALB)
  ###########################

  # Target Groups for ALB
  alb_target_groups = {
    # Blue Target Group (Production)
    group-dashboard = {
      name                 = "group-dashboard-tg" # Name of the target group
      protocol             = "HTTP"               # Protocol for the target group
      port                 = 80                   # Port for the target group
      target_type          = "instance"           # Target type (instance or IP)
      deregistration_delay = 10                   # Time to wait before deregistering targets

      # Health Check Configuration
      health_check = {
        enabled             = true           # Enable health checks
        interval            = 60             # Health check interval in seconds
        path                = "/"            # Health check path
        port                = "traffic-port" # Use the same port as the application
        healthy_threshold   = 2              # Consecutive successes to mark as healthy
        unhealthy_threshold = 2              # Consecutive failures to mark as unhealthy
        timeout             = 5              # Health check timeout in seconds
        protocol            = "HTTP"         # Health check protocol
        matcher             = "200-399"      # HTTP response codes considered healthy
      }
    }

    # Green Target Group (Test)
    group-dashboard-green = {
      name                 = "group-dashboard-green-tg" # Name of the target group
      protocol             = "HTTP"                     # Protocol for the target group
      port                 = 8080                       # Port for the target group
      target_type          = "instance"                 # Target type (instance or IP)
      deregistration_delay = 10                         # Time to wait before deregistering targets

      # Health Check Configuration
      health_check = {
        enabled             = true           # Enable health checks
        interval            = 60             # Health check interval in seconds
        path                = "/"            # Health check path
        port                = "traffic-port" # Use the same port as the application
        healthy_threshold   = 2              # Consecutive successes to mark as healthy
        unhealthy_threshold = 2              # Consecutive failures to mark as unhealthy
        timeout             = 5              # Health check timeout in seconds
        protocol            = "HTTP"         # Health check protocol
        matcher             = "200-399"      # HTTP response codes considered healthy
      }
    }
  }

  # ALB Listeners
  alb_listeners = {
    # HTTPS Production Listener (Blue)
    https = {
      port            = 443                                        # Listener port
      protocol        = "HTTPS"                                    # Listener protocol
      ssl_policy      = "ELBSecurityPolicy-TLS13-1-2-2021-06"      # SSL policy
      certificate_arn = data.aws_acm_certificate.amazon_issued.arn # ACM certificate ARN
      fixed_response = {
        content_type = "text/plain"          # Content type for fixed response
        message_body = "404: page not found" # Message body for fixed response
        status_code  = "404"                 # HTTP status code for fixed response
      }
      rules = {
        group-dashboard = {
          priority = 100 # Rule priority
          actions = [
            {
              type             = "forward"                                                  # Forward action
              target_group_arn = try(module.alb.target_group_arns["group-dashboard"], null) # Target group ARN
            }
          ]
          conditions = [{
            host_header = {
              values = ["group-dashboard.karkidhan.com.np"] # Host header condition
            }
          }]
        }
      }
    }

    # HTTPS Test Listener (Green)
    https-test = {
      port            = 8443                                       # Listener port for test traffic
      protocol        = "HTTPS"                                    # Listener protocol
      ssl_policy      = "ELBSecurityPolicy-TLS13-1-2-2021-06"      # SSL policy
      certificate_arn = data.aws_acm_certificate.amazon_issued.arn # ACM certificate ARN
      fixed_response = {
        content_type = "text/plain"          # Content type for fixed response
        message_body = "404: page not found" # Message body for fixed response
        status_code  = "404"                 # HTTP status code for fixed response
      }
      rules = {
        group-dashboard-green = {
          priority = 100 # Rule priority
          actions = [
            {
              type             = "forward"                                                        # Forward action
              target_group_arn = try(module.alb.target_group_arns["group-dashboard-green"], null) # Target group ARN
            }
          ]
          conditions = [{
            host_header = {
              values = ["test-group-dashboard.karkidhan.com.np"] # Host header condition
            }
          }]
        }
      }
    }

    # HTTP to HTTPS Redirect Listener
    http-to-https = {
      port     = 80     # Listener port
      protocol = "HTTP" # Listener protocol
      redirect = {
        port        = "443"      # Redirect to port 443
        protocol    = "HTTPS"    # Redirect to HTTPS
        status_code = "HTTP_301" # HTTP 301 redirect
      }
    }
  }

  ###########################
  # CloudWatch Log Groups
  ###########################
  log_groups = {
    # Log group for ECS service
    group-dashboard = {
      name              = "/ecs/service/group-dashboard" # Log group name
      retention_in_days = 30                             # Log retention period in days
    }

    # Log group for ECS Execute Command
    ecs-exec-command = {
      name              = "/aws/ecs/exec-command-logs" # Log group name
      retention_in_days = 30                           # Log retention period in days
    }
  }

  ###########################
  # ECS Services
  ###########################
  ecs_services = {
    group-dashboard = {
      desired_count = 1   # Desired number of tasks
      cpu           = 512 # CPU units for the task
      memory        = 512 # Memory in MB for the task

      # Container Definition
      container_definitions = [
        {
          name              = "group-dashboard"                                   # Container name
          cpu               = 512                                                 # CPU units for the container
          memory            = 512                                                 # Memory in MB for the container
          memoryReservation = 256                                                 # Memory reservation to prevent OOM kills
          essential         = true                                                # Mark container as essential
          image             = "public.ecr.aws/e1z1p8n3/dhan/group-app-web:latest" # Container image
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
              containerPort = 80    # Container port
              hostPort      = 80    # Host port (not needed if using awsvpc network mode)
              protocol      = "tcp" # Protocol (TCP)
            }
          ]
          readonlyRootFilesystem = false # Allow writing to the root filesystem
          logConfiguration = {
            logDriver = "awslogs" # Log driver (CloudWatch Logs)
            options = {
              "awslogs-group"         = module.cloudwatch_log_groups["group-dashboard"].log_group_name # Log group name
              "awslogs-region"        = data.aws_region.current.name                                   # AWS region
              "awslogs-stream-prefix" = "group-dashboard"                                              # Log stream prefix
            }
          }
        }
      ]
      container_name = "group-dashboard" # Name of the container
      container_port = 80                # Port exposed by the container
      target_group   = "group-dashboard" # Target group for the service
      capacity_provider = {
        name    = "group-dashboard-cp"                   # Capacity provider name
        asg_arn = module.asgs["group-dashboard"].asg_arn # ASG ARN for the capacity provider
        weight  = 100                                    # Weight for the capacity provider
        base    = 0                                      # Base capacity (0 allows ECS to scale dynamically)
      }
    }
  }

  # CodeDeploy Load Balancer Configuration
  load_balancer_info = {
    target_group_pair_info = {
      # Production Traffic Route (Blue)
      prod_traffic_route = {
        listener_arns = [module.alb.listener_arns["https"]] # Listener ARN for production traffic
      }
      # Test Traffic Route (Green)
      test_traffic_route = {
        listener_arns = [module.alb.listener_arns["https-test"]] # Listener ARN for test traffic
      }
      # Blue Target Group
      blue_target_group = {
        name = "group-dashboard-tg" # Name of the Blue target group
      }
      # Green Target Group
      green_target_group = {
        name = "group-dashboard-green-tg" # Name of the Green target group
      }
    }
  }
}
