#----------------------
# ECS SSM
#----------------------

data "aws_ssm_parameter" "new_relic_secret"{
  count = var.create ? 1 : 0
  name = var.newrelic_license_key_parameter_name
  with_decryption = false
}

data "aws_iam_policy_document" "ecs_task_ssm_policy" {
	count = var.create ? 1 : 0
	statement {
		actions = [
			"ssm:GetParameters"
		]
		resources = [
			data.aws_ssm_parameter.new_relic_secret[0].arn,
		]
	}
}

resource "aws_iam_role_policy" "ecs_task_role_ssm_policy" {
	count = var.create ? 1 : 0
    name        = "${local.name_prefix}-ecs-ssm-access-policy"
	role       = aws_iam_role.task_execution_role[0].name
	policy = 	element(data.aws_iam_policy_document.ecs_task_ssm_policy.*.json, count.index)
}

# resource "aws_iam_role_policy_attachment" "ecs_task_role_ssm_attachment" {
#   count = var.create ? 1 : 0
#   role       = aws_iam_role.task_execution_role[0].name
#   policy_arn = data.aws_iam_policy_document.ecs_task_ssm_policy.
# }