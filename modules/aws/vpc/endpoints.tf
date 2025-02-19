# Get current region - this needs to be declared before using it
data "aws_region" "current" {}

locals {
  endpoint_prefix = "${var.custom_tags["Project"] != "" ? var.custom_tags["Project"] : "default-project"}-${var.custom_tags["Environment"] != "" ? var.custom_tags["Environment"] : "default-env"}"
}

resource "aws_vpc_endpoint" "this" {
  for_each = var.create_vpc_endpoints ? var.endpoints : {}

  vpc_id            = try(var.vpc_id, aws_vpc.this[0].id, null)
  service_name      = "com.amazonaws.${data.aws_region.current.name}.${each.value.service}"
  vpc_endpoint_type = each.value.vpc_endpoint_type

  # Optional attributes for specific endpoint types
  private_dns_enabled = each.value.vpc_endpoint_type == "Interface" ? each.value.private_dns_enabled : null
  subnet_ids          = each.value.vpc_endpoint_type == "Interface" ? each.value.subnet_ids : null
  security_group_ids  = each.value.vpc_endpoint_type == "Interface" ? each.value.security_group_ids : null

  # Gateway-specific attributes
  route_table_ids = each.value.vpc_endpoint_type == "Gateway" ? each.value.route_table_ids : null

  tags = merge(
    {
      Name = "${local.endpoint_prefix}-vpce-${each.value.service}"
    },
    var.custom_tags
  )
}
