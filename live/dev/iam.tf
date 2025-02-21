#================================
# Instance Profile
#================================
module "instance_profile" {
  source                      = "../../modules/aws/iam"
  create                      = true
  create_ec2_instance_profile = true
  role_name                   = "EC2InstanceRole"
  role_description            = "IAM EC2 Instance role for ECS"

  # Trust relationship policy for EC2
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  role_policies = {
    ## Required for SSM Session Manager
    SSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  # ECS Instance Policy
  policy_document = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AmazonEC2ContainerServiceforEC2Role"
        Effect = "Allow"
        Action = [
          "ec2:DescribeTags",
          "ecs:CreateCluster",
          "ecs:DeregisterContainerInstance",
          "ecs:DiscoverPollEndpoint",
          "ecs:Poll",
          "ecs:RegisterContainerInstance",
          "ecs:StartTelemetrySession",
          "ecs:UpdateContainerInstancesState",
          "ecs:Submit*",
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
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
