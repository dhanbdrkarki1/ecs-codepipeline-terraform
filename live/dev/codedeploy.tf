#================================
# CodeDeploy Application
#================================
module "codedeploy" {
  source = "../../modules/aws/codedeploy"
  create = true
  # App
  name             = "codedeploy"
  compute_platform = "ECS"

  # Deployment Group
  deployment_config_name  = "CodeDeployDefault.ECSAllAtOnce"
  codedeploy_service_role = module.ecs_codedeploy_role.role_arn

  # ECS Services
  ecs_service = [
    {
      cluster_name = module.ecs_cluster.cluster_name
      service_name = module.ecs_service.service_name
    }
  ]

  # Load Balancer
  load_balancer_info = {
    target_group_pair_info = {
      # Production Listener
      prod_traffic_route = {
        listener_arns = [module.alb.listener_arns["group-dashboard"]]
      }
      # Test Listener
      test_traffic_route = {
        listener_arns = [module.alb.listener_arns["group-dashboard-green"]]
      }
      # Target Group for Blue
      blue_target_group = {
        name = module.alb.target_group_arns["group-dashboard"]
      }
      # Target Group for Green
      green_target_group = {
        name = module.alb.target_group_arns["group-dashboard-green"]
      }
    }
  }


  # Deployment settings
  deployment_style = {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  custom_tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}
