# VPC FloW Log
resource "aws_flow_log" "this" {
  count                    = var.create && var.enable_flow_log ? 1 : 0
  log_destination          = var.log_destination
  log_destination_type     = var.log_destination_type
  traffic_type             = var.traffic_type
  log_format               = var.log_format
  max_aggregation_interval = var.max_aggregation_interval
  vpc_id                   = try(aws_vpc.this[0].id, null)
  tags = merge(
    { Name = "${local.name_prefix}-flow-logs" },
    var.vpc_tags,
    var.custom_tags
  )
}
