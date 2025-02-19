#================================
# ECS Log Group for ECS Tasks
#================================
module "ecs_log_group" {
  source            = "../../modules/aws/cloudwatch"
  create            = true
  name              = "/ecs/${var.project_name}-${var.environment}"
  retention_in_days = 30

  custom_tags = {
    Name        = "/ecs/${var.project_name}-${var.environment}"
    Environment = var.environment
  }
}
