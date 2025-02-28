#================================
# CodePipeline Artifact Store
#================================
module "codepipeline_artifact_bucket" {
  source               = "../../modules/aws/s3"
  create               = true
  bucket_name          = "codepipeline-artifact"
  enable_versioning    = false
  force_destroy        = true
  create_bucket_policy = true
  bucket_policy = jsonencode({
    Version = "2012-10-17"
    Id      = "SSEAndSSLPolicy"
    Statement = [
      {
        Sid       = "DenyUnEncryptedObjectUploads"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:PutObject"
        Resource  = "${module.codepipeline_artifact_bucket.bucket_arn}/*"
        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption" = "aws:kms"
          }
        }
      },
      {
        Sid       = "DenyInsecureConnections"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource  = "${module.codepipeline_artifact_bucket.bucket_arn}/*"
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      },
      {
        Sid    = "CodePipelineAccess"
        Effect = "Allow"
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:ListBucket",
          "s3:GetBucketAcl",
          "s3:GetBucketLocation"
        ]
        Resource = [
          module.codepipeline_artifact_bucket.bucket_arn,
          "${module.codepipeline_artifact_bucket.bucket_arn}/*"
        ]
      }
    ]
  })

  # Block public access
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  custom_tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

#================================
# SNS Notification
#================================
module "sns_notification" {
  source       = "../../modules/aws/sns"
  create       = true
  name         = "codepipeline-sns-topic"
  display_name = "codepipeline-sns-topic"

  subscriptions = [
    {
      protocol = "email"
      endpoint = "dhan@cloudtechservice.com"
    }
  ]

  create_topic_policy = true
  topic_policy_statements = {
    allow_codepipeline = {
      sid    = "AllowCodePipelineToPublish"
      effect = "Allow"
      principals = [{
        type        = "Service"
        identifiers = ["codepipeline.amazonaws.com"]
      }]
      actions  = ["sns:Publish"]
      resource = module.sns_notification.topic_arn
      condition = {
        ArnEquals = {
          "aws:SourceArn" = [
            module.codepipeline.arn
          ]
        }
      }
    }
  }

  custom_tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

#================================
# CodePipeline Service Role
#================================
module "codepipeline_service_role" {
  source           = "../../modules/aws/iam"
  create           = true
  role_name        = "CodePipelineServiceRole"
  role_description = "IAM role for CodePipeline"

  # Trust relationship policy for CodePipeline
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  # CodePipeline permissions policy
  policy_document = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "iam:PassRole"
        ]
        Resource = "*"
        Effect   = "Allow"
        Condition = {
          StringEqualsIfExists = {
            "iam:PassedToService" = [
              "ecs-tasks.amazonaws.com",
              "codedeploy.amazonaws.com",
              "ec2.amazonaws.com"
            ]
          }
        }
      },
      # ECS Permissions
      {
        Sid    = "ECSAccess"
        Effect = "Allow"
        Action = [
          "ecs:RegisterTaskDefinition",
          "ecs:ListTaskDefinitions",
          "ecs:DescribeTaskDefinition",
          "ecs:DescribeServices",
          "ecs:UpdateService",
          "ecs:DeleteTaskDefinitions",
          "ecs:TagResource",
          "ecs:UntagResource",
          "ecs:ListTagsForResource"
        ]
        Resource = "*"
      },
      # ECR Permissions
      {
        Sid    = "ECRAccess"
        Effect = "Allow"
        Action = [
          "ecr:DescribeImages",
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer"
        ]
        Resource = "*"
      },
      # Approval Policy
      {
        Sid    = "CodePipelineApprovalPolicy"
        Effect = "Allow"
        Action = [
          "codepipeline:GetPipeline",
          "codepipeline:GetPipelineExecution",
          "codepipeline:ListActionExecutions",
          "codepipeline:PutApprovalResult"
        ]
        Resource = try(module.codepipeline.arn, "*")
      },
      # SNS Notification
      {
        Sid      = "CodePipelineSNSPublishPolicy"
        Effect   = "Allow"
        Action   = "sns:Publish"
        Resource = [module.sns_notification.topic_arn]
      },
      {
        Sid    = "S3ArtifactAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetBucketVersioning",
          "s3:PutObject",
          "s3:ListBucket",
          "s3:DeleteObject"
        ]
        Resource = [
          "${module.codepipeline_artifact_bucket.bucket_arn}",
          "${module.codepipeline_artifact_bucket.bucket_arn}/*"
        ]
      },
      {
        Sid    = "CodeConnection"
        Effect = "Allow"
        Action = [
          "codestar-connections:UseConnection"
        ]
        Resource = "*"
        # Action = [
        #   "codeconnections:UseConnection"
        # ]
        # Resource = try(var.codeconnection_arn, "*")
      },
      {
        Sid    = "CodeDeployAccess"
        Effect = "Allow"
        Action = [
          "codedeploy:CreateDeployment",
          "codedeploy:GetApplication",
          "codedeploy:GetApplicationRevision",
          "codedeploy:GetDeployment",
          "codedeploy:GetDeploymentConfig",
          "codedeploy:RegisterApplicationRevision",
          "codedeploy:BatchGetApplicationRevisions",
          "codedeploy:BatchGetDeploymentGroups",
          "codedeploy:BatchGetDeployments",
          "codedeploy:ContinueDeployment",
          "codedeploy:StopDeployment"
        ]
        Resource = try(module.codedeploy.arn, "*")
      },
      {
        Sid    = "CodeBuildAccess"
        Effect = "Allow"
        Action = [
          "codebuild:BatchGetBuilds",
          "codebuild:StartBuild",
        ]
        Resource = try(module.codebuild.arn, "*")
      },
      {
        Sid    = "EC2andELBAccess"
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceStatus",
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:DescribeTargetHealth",
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DescribeListeners",
          "elasticloadbalancing:DescribeRules"
        ]
        Resource = "*"
      },
      {
        Sid    = "CloudWatchAccess"
        Effect = "Allow"
        Action = [
          "cloudwatch:DescribeAlarms",
          "cloudwatch:GetMetricStatistics"
        ]
        Resource = "*"
      }

      # {
      #   Sid    = "KMSAccess"
      #   Effect = "Allow"
      #   Action = [
      #     "kms:DescribeKey",
      #     "kms:GenerateDataKey*",
      #     "kms:Encrypt",
      #     "kms:ReEncrypt*",
      #     "kms:Decrypt"
      #   ]
      #   Resource = "*"
      # },
    ]
  })

  custom_tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}


#================================
# AWS CodePipeline
#================================

module "codepipeline" {
  source = "../../modules/aws/codepipeline"
  create = var.create_codepipeline
  # Pipeline
  pipeline_type           = "V2"
  pipeline_execution_mode = "QUEUED"
  # CodePipeline Artifact Bucket
  codepipeline_artifact_bucket = module.codepipeline_artifact_bucket.bucket_name
  # CodePipeline IAM Role
  codepipeline_service_role_arn = module.codepipeline_service_role.role_arn

  stages = [
    {
      name = "Source"
      action = {
        name     = "Source"
        category = "Source"
        owner    = "AWS"
        provider = "CodeStarSourceConnection"
        version  = "1"
        configuration = {
          ConnectionArn    = var.codeconnection_arn
          FullRepositoryId = var.github_repo_id
          BranchName       = var.github_repo_branch
        }
        output_artifacts = ["SourceOutput"]
      }
    },
    {
      name = "Build"
      action = {
        name             = "Build"
        category         = "Build"
        owner            = "AWS"
        provider         = "CodeBuild"
        version          = "1"
        input_artifacts  = ["SourceOutput"]
        output_artifacts = ["BuildOutput"]
        run_order        = 2
        configuration = {
          ProjectName = module.codebuild.name
        }
      }
    },
    {
      name = "Approval"
      action = {
        name      = "Approval"
        category  = "Approval"
        owner     = "AWS"
        provider  = "Manual"
        version   = "1"
        run_order = 1
        configuration = {
          CustomData = "Please review the build output and approve if everything looks correct"
          # SNS topic ARN
          NotificationArn    = try(module.sns_notification.topic_arn, null)
          ExternalEntityLink = "https://console.aws.amazon.com/codesuite/codebuild/projects/${try(module.codebuild.name, null)}" # Optional: Link to your build results
        }
      }
    },
    # Blue/Green Deployment
    {
      name = "Deploy"
      action = {
        name            = "Deploy"
        category        = "Deploy"
        owner           = "AWS"
        provider        = "CodeDeployToECS"
        version         = "1"
        input_artifacts = ["BuildOutput"]
        run_order       = 3
        configuration = {
          ApplicationName                = module.codedeploy.application_name
          DeploymentGroupName            = module.codedeploy.deployment_group_name
          TaskDefinitionTemplateArtifact = "BuildOutput"
          TaskDefinitionTemplatePath     = "taskdef.json"
          AppSpecTemplateArtifact        = "BuildOutput"
          AppSpecTemplatePath            = "appspec.yaml"
          Image1ArtifactName             = "BuildOutput"
          Image1ContainerName            = "IMAGE1_NAME" // must match the placeholder for image in taskdef.json
        }
      }
    }
  ]

  # Tags
  custom_tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}
