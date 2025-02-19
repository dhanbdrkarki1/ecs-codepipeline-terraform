#================================
# ECS Task Execution Role and Policy
#================================
module "ecs_task_execution_role" {
  source           = "../../modules/aws/iam"
  create           = true
  role_name        = "TaskExectionRole"
  role_description = "IAM role for ECS Task"

  # Trust relationship policy for ECS Task
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  # ECS permissions policy
  policy_document = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CloudWatchLogsPermissions"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      },
      {
        Sid    = "ECRAuthorizationToken"
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      },
      {
        Sid    = "ECRRepositoryAccess"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = "*"
      }
    ]
  })

  custom_tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}



#================================
# ECS Auto Scaling Role and Policy
#================================
module "ecs_auto_scale_role" {
  source           = "../../modules/aws/iam"
  create           = true
  role_name        = "ECSAutoScalingRole"
  role_description = "IAM role for ECS Auto Scaling"

  # Trust relationship policy for ECS Auto Scaling
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "application-autoscaling.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  # managed policies
  role_policies = {
    AmazonEC2ContainerServiceAutoscaleRole = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceAutoscaleRole"
  }

  custom_tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}
