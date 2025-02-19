#================================
# AWS Load Balancer
#================================
module "alb" {
  source              = "../../modules/aws/alb"
  create              = true
  name                = "web-app-lb"
  vpc_id              = module.vpc.vpc_id
  subnet_groups_ids   = module.vpc.public_subnet_ids
  security_groups_ids = [module.alb_sg.security_group_id]
  # container_port      = 80 # no need
  health_check_path = "/"

  target_groups = {
    ec2-instance = {
      protocol             = "HTTP"
      port                 = 80
      target_type          = "instance"
      deregistration_delay = 10

      health_check = {
        enabled             = true
        interval            = 30
        path                = "/"
        port                = "traffic-port"
        healthy_threshold   = 2
        unhealthy_threshold = 2
        timeout             = 6
        protocol            = "HTTP"
        matcher             = "200-399"
      }
    }
  }

  listeners = {
    fixed-response = {
      port     = 80
      protocol = "HTTP"
      fixed_response = {
        content_type = "text/plain"
        message_body = "404: page not found"
        status_code  = "404"
      }

      rules = {
        fixed-response = {
          priority = 100
          actions = [
            {
              type = "forward"
              # for EC2 Target (Instance)
              target_group_arn = try(module.alb.target_group_arns["ec2-instance"], null) # For EC2 Type

              # For ECS Target (ip)
              # target_group_key = "ip"
            }
          ]

          conditions = [{
            path_pattern = {
              values = ["*"]
            }
          }]
        }
      }
    }
  }

  custom_tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}
