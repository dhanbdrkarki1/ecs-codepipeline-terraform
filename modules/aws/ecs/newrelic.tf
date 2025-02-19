# Parameter Store
data "aws_ssm_parameter" "newrelic_license_key" {
  count = var.create && var.enable_newrelic_monitoring ? 1 : 0
  name = var.newrelic_license_key_parameter_name
}

# IAM Policy for reading License Key

resource "aws_iam_policy" "newrelic_ssm_license_key_read_access" {
  count = var.create && var.enable_newrelic_monitoring ? 1 : 0
  name = "NewRelicSSMLicenseKeyReadAccess"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ssm:GetParameters"
      ],
      "Resource": [
        "${data.aws_ssm_parameter.newrelic_license_key[0].arn}"
      ]
    }
  ]
}
EOF
}


# IAM Role for Task Execution

resource "aws_iam_role" "newrelic_ecs_task_execution_role" {
  count = var.create && var.enable_newrelic_monitoring ? 1 : 0
  name = "NewRelicECSTaskExecutionRole"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# Attach Policies to Role
resource "aws_iam_role_policy_attachment" "newrelic_license_key_access" {
  count = var.create && var.enable_newrelic_monitoring ? 1 : 0
  role       = aws_iam_role.newrelic_ecs_task_execution_role[0].name
  policy_arn = aws_iam_policy.newrelic_ssm_license_key_read_access[0].arn
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role" {
  count = var.create && var.enable_newrelic_monitoring ? 1 : 0
  role       = aws_iam_role.newrelic_ecs_task_execution_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}