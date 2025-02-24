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
      #   service_name = module.ecs_services["group-dashboard"].service_name
      service_name = module.ecs_services["group-dashboard"].service_name
    }
  ]

  # Load Balancer
  load_balancer_info = local.load_balancer_info

  # Deployment settings
  deployment_style = {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  # Blue Green Deployment Config
  blue_green_deployment_config = {
    deployment_ready_option = {
      action_on_timeout    = "STOP_DEPLOYMENT"
      wait_time_in_minutes = 10
    }
    terminate_blue_instances_on_deployment_success = {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 5
    }
  }

  custom_tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}
