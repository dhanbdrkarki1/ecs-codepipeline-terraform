#================================
# CloudWatch Log Groups
#================================
module "cloudwatch_log_groups" {
  source   = "../../modules/aws/cloudwatch"
  for_each = local.log_groups
  create   = true
  # Format: /ecs/<type>/<service-name>/<environment>/<project>
  name              = "${each.value.name}/${var.environment}/${var.project_name}"
  retention_in_days = each.value.retention_in_days
  custom_tags = {
    Name        = "${each.value.name}/${var.environment}/${var.project_name}"
    Environment = var.environment
    Project     = var.project_name
  }
}
