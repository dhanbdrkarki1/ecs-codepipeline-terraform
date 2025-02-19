#---------------
# ECS Tasks
#---------------

resource "aws_iam_role" "task_execution_role" {
  count              = var.create ? 1 : 0
  name               = "${local.name_prefix}-task-execution-role"
  assume_role_policy = file("${path.module}/templates/ecs/ecs-tasks-assume-role-policy.json")
  tags = merge(
    { "Name" = "${local.name_prefix}" },
    var.custom_tags
  )
}

resource "aws_iam_policy" "task_execution_role_policy" {
  count       = var.create ? 1 : 0
  name        = "${local.name_prefix}-task-exec-role-policy"
  path        = "/"
  description = "Allow retrieving images and adding to logs"
  policy      = file("${path.module}/templates/ecs/task-exec-role.json")
  tags = merge(
    { "Name" = "${local.name_prefix}" },
    var.custom_tags
  )
}

resource "aws_iam_role_policy_attachment" "task_execution_role" {
  count      = var.create ? 1 : 0
  role       = aws_iam_role.task_execution_role[0].name
  policy_arn = aws_iam_policy.task_execution_role_policy[0].arn
}


#----------------------
# ECS Auto Scaling
#----------------------
# ECS Auto Scale Role
resource "aws_iam_role" "ecs_auto_scale_role" {
  count              = var.create ? 1 : 0
  name               = "${local.name_prefix}-ecs-auto-scale-role"
  assume_role_policy = file("${path.module}/templates/ecs/ecs-auto-scale-assume-role-policy.json")
  tags = merge(
    { "Name" = "${local.name_prefix}" },
    var.custom_tags
  )
}

# ECS auto scale role policy attachment
resource "aws_iam_role_policy_attachment" "ecs_auto_scale_role" {
  count      = var.create ? 1 : 0
  role       = aws_iam_role.ecs_auto_scale_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceAutoscaleRole"
}


#----------------------
# ECS S3 Access
#----------------------

data "template_file" "s3_access_policy" {
  template = file("${path.module}/templates/ecs/s3-policy.json.tpl")
  vars = {
    s3_bucket_arn = var.s3_bucket_arn
  }
}

resource "aws_iam_policy" "s3_access_policy" {
  count       = var.create ? 1 : 0
  name        = "${local.name_prefix}-s3-access-policy"
  description = "Allow retrieving, updating and deleting files from S3."
  policy      = data.template_file.s3_access_policy.rendered
  tags = merge(
    { "Name" = "${local.name_prefix}" },
    var.custom_tags
  )
}

# Attaching S3 access IAM policy to ECS IAM Role
resource "aws_iam_role_policy_attachment" "ecs_role_s3_access_policy_attach" {
  count      = var.create ? 1 : 0
  role       = aws_iam_role.task_execution_role[0].name
  policy_arn = aws_iam_policy.s3_access_policy[0].arn
}



# CloudWatch Role for monitoring logs
resource "aws_iam_role" "cloudwatch_role" {
  name = "cloudwatch_${var.name}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "logs.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}


resource "aws_iam_policy" "cloudwatch_policy" {
  name        = "CloudWatchPolicy_${var.name}"
  description = "Policy for cloudwatch logs to stream to Kinesis Firehose"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:PutLogEvents",
          "logs:CreateLogStream",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:PutSubscriptionFilter",
          "firehose:PutRecord",
          "firehose:PutRecordBatch"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "firehose_cloudwatch_policy_attach" {
  role       = aws_iam_role.cloudwatch_role.name
  policy_arn = aws_iam_policy.cloudwatch_policy.arn
}

