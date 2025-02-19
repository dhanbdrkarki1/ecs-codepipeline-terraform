##########################
# SSM Parameter Store
##########################

resource "aws_ssm_parameter" "this" {
  for_each    = var.create ? var.ssm_parameters : {}
  name        = try(each.value.name, null)
  description = try(each.value.description, null)
  type        = try(each.value.type, null)
  value       = try(each.value.value, null)
  tags        = try(var.custom_tags, null)
}
