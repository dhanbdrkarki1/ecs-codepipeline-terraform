locals {
  # AWS Account ID
  account_id = "664418970145"
  ecs_ami_id = jsondecode(data.aws_ssm_parameter.ecs_optimized_ami.value)["image_id"]

  # ASG Services
  asg_services = {
    "nginx" = {
      name             = "nginx"
      instance_type    = "t3.small"
      min_size         = 2
      desired_capacity = 2
      max_size         = 4
      volume_size      = 30
    },
    "rep_dashboard" = {
      name             = "rep-dashboard"
      instance_type    = "t3.medium"
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
      container_name = "nginx"
      container_port = 80
      host_port      = 80
      app_image      = "public.ecr.aws/nginx/nginx:1.27-alpine3.21-slim"
      app_cpu        = 256
      app_memory     = 512
      desired_count  = 2
      target_group   = module.alb.target_group_arns["nginx"]
      capacity_provider = {
        name    = "nginx-cp"
        asg_arn = module.asgs.asg_arns["nginx"]
        weight  = 1
        base    = 2
      }
    }
    rep_dashboard = {
      container_name = "rep-dashboard"
      container_port = 80
      host_port      = 80
      app_image      = "public.ecr.aws/e1z1p8n3/dhan/rep-dashboard:latest"
      app_cpu        = 256
      app_memory     = 512
      desired_count  = 1
      target_group   = module.alb.target_group_arns["rep_dashboard"]
      capacity_provider = {
        name    = "rep-dashboard-cp"
        asg_arn = module.asgs.asg_arns["rep_dashboard"]
        weight  = 1
        base    = 1
      }
    }
  }
}

