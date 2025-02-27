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
      service_name = module.ecs_services["group-dashboard"].service_name
    }
  ]

  # Load Balancer
  load_balancer_info = local.load_balancer_info

  # Rollback on Failure
  auto_rollback_configuration = {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  # Deployment settings
  deployment_style = {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  # Blue Green Deployment Config
  blue_green_deployment_config = {
    # defines what happens if the new deployment takes too long (i.e., timeout before success)
    deployment_ready_option = {
      action_on_timeout    = "STOP_DEPLOYMENT"
      wait_time_in_minutes = 3 # Set to 2-5 to allow time for health checks while still ensuring fast rollbacks. 
    }
    # handles what happens to the old (blue) version after a successful deployment
    terminate_blue_instances_on_deployment_success = {
      action                           = "TERMINATE" # The old version will be removed after a successful deployment.
      termination_wait_time_in_minutes = 2           # CodeDeploy will wait 2 minutes before shutting down old tasks.
    }
  }

  ## Set this config, If you need manual approval in your deployment process
  #   blue_green_deployment_config = {
  #     deployment_ready_option = {
  #       action_on_timeout    = "STOP_DEPLOYMENT"
  #       wait_time_in_minutes = 10
  #     }
  #     terminate_blue_instances_on_deployment_success = {
  #       action                           = "TERMINATE"
  #       termination_wait_time_in_minutes = 5
  #     }
  #   }

  custom_tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}
