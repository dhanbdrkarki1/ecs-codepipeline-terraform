locals {
  name_prefix            = "${var.custom_tags["Project"] != "" ? var.custom_tags["Project"] : "default-project"}-${var.custom_tags["Environment"] != "" ? var.custom_tags["Environment"] : "default-env"}-${var.name != "" ? var.name : "default-name"}"
  vpc_id                 = var.use_existing_vpc ? data.aws_vpc.existing[0].id : try(aws_vpc.this[0].id, "")
  create_public_subnets  = var.create && !var.use_existing_vpc && length(var.public_subnet_cidr_blocks) > 0
  create_private_subnets = var.create && !var.use_existing_vpc && length(var.private_subnet_cidr_blocks) > 0
  len_public_subnets     = length(var.public_subnet_cidr_blocks)
  len_private_subnets    = length(var.private_subnet_cidr_blocks)
  len_database_subnets   = length(var.database_subnet_cidr_blocks)
  all_ips                = "0.0.0.0/0"

  max_subnet_length = max(
    local.len_private_subnets,
    local.len_public_subnets,
    local.len_database_subnets
  )
}


# VPC
resource "aws_vpc" "this" {
  count                = var.create && !var.use_existing_vpc ? 1 : 0
  cidr_block           = var.cidr_block
  instance_tenancy     = var.tenancy
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support
  tags = merge(
    { Name = "${local.name_prefix}" },
    var.vpc_tags,
    var.custom_tags
  )
}


# public subnets
resource "aws_subnet" "public_subnet" {
  count                   = local.create_public_subnets ? local.len_public_subnets : 0
  vpc_id                  = local.vpc_id
  cidr_block              = var.public_subnet_cidr_blocks[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = var.map_public_ip_on_launch

  tags = merge(
    { Name = "${local.name_prefix}-public-subnet-${count.index + 1}" },
    var.public_subnet_tags,
    var.custom_tags
  )
}

resource "aws_route_table" "public_rtb" {
  count  = local.create_public_subnets ? 1 : 0
  vpc_id = local.vpc_id

  tags = merge(
    { "Name" = "${local.name_prefix}-public-rtb-${count.index + 1}" },
    var.custom_tags
  )
}


# Public Route Table Association with subnet
resource "aws_route_table_association" "public" {
  count          = local.create_public_subnets ? local.len_public_subnets : 0
  subnet_id      = element(aws_subnet.public_subnet[*].id, count.index)
  route_table_id = aws_route_table.public_rtb[0].id
}



# Internet Gateway
resource "aws_internet_gateway" "this" {
  count  = local.create_public_subnets && var.create_igw ? 1 : 0
  vpc_id = local.vpc_id

  tags = merge(
    { "Name" = "${local.name_prefix}-ig" },
    var.igw_tags,
    var.custom_tags,
  )
}

# Adding ig to route
resource "aws_route" "public_igw" {
  count                  = local.create_public_subnets && var.create_igw ? 1 : 0
  route_table_id         = aws_route_table.public_rtb[0].id
  destination_cidr_block = local.all_ips
  gateway_id             = aws_internet_gateway.this[0].id
}






#-------------------------
# Private subnets
#--------------------------
resource "aws_subnet" "private_subnet" {
  count             = local.create_private_subnets ? length(var.private_subnet_cidr_blocks) : 0
  vpc_id            = local.vpc_id
  cidr_block        = var.private_subnet_cidr_blocks[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(
    { Name = "${local.name_prefix}-private-subnet-${count.index + 1}" },
    var.private_subnet_tags,
    var.custom_tags
  )
}

resource "aws_route_table" "private_rtb" {
  vpc_id = local.vpc_id
  count  = local.create_private_subnets && local.max_subnet_length > 0 ? local.nat_gateway_count : 0

  tags = merge(
    { "Name" = "${local.name_prefix}-private-rtb-${count.index + 1}" },
    var.custom_tags
  )
}

# # Private Route Table Association with subnet
resource "aws_route_table_association" "private" {
  count     = local.create_private_subnets ? local.len_private_subnets : 0
  subnet_id = element(aws_subnet.private_subnet[*].id, count.index)
  route_table_id = element(
    aws_route_table.private_rtb[*].id, var.single_nat_gateway ? 0 : count.index
  )

}

# Adding NAT gateway to the route
resource "aws_route" "ngw_route" {
  count                  = var.create && !var.use_existing_vpc && var.enable_nat_gateway ? var.single_nat_gateway ? 1 : length(var.availability_zones) : 0
  route_table_id         = element(aws_route_table.private_rtb[*].id, count.index)
  destination_cidr_block = local.all_ips
  gateway_id             = element(aws_nat_gateway.this[*].id, count.index)
}

#-------------------
# NAT Gateway
#-------------------
locals {
  nat_gateway_count = var.single_nat_gateway ? 1 : var.one_nat_gateway_per_az ? length(var.availability_zones) : local.max_subnet_length
}

# Elastic IPs for NAT
resource "aws_eip" "eip" {
  count = var.create && !var.use_existing_vpc && var.enable_nat_gateway ? local.nat_gateway_count : 0
  # domain   = "vpc"
  depends_on = [aws_internet_gateway.this]

  tags = merge(
    { "Name" = "${local.name_prefix}-eip-${count.index + 1}" },
    var.nat_eip_tags,
    var.custom_tags
  )
}


# Create NAT Gateways
resource "aws_nat_gateway" "this" {
  depends_on    = [aws_internet_gateway.this]
  count         = var.create && !var.use_existing_vpc && var.enable_nat_gateway ? local.nat_gateway_count : 0
  allocation_id = element(aws_eip.eip[*].id, var.single_nat_gateway ? 0 : count.index)
  subnet_id     = element(aws_subnet.public_subnet[*].id, var.single_nat_gateway ? 0 : count.index)
  tags = merge({
    Name = "${local.name_prefix}-ngw-${count.index + 1}"
    },
    var.nat_gateway_tags,
    var.custom_tags
  )
}


#---------------------
# Public NACLs
#---------------------
resource "aws_network_acl" "public" {
  count      = local.create_public_subnets && !var.use_existing_vpc && var.create_public_custom_network_acl ? 1 : 0
  vpc_id     = local.vpc_id
  subnet_ids = aws_subnet.public_subnet[*].id
  tags = merge(
    { "Name" : "${local.name_prefix}-public-acl-${count.index + 1}" },
    var.public_acl_tags,
    var.custom_tags
  )
}

resource "aws_network_acl_rule" "public_inbound" {
  count = local.create_public_subnets && var.create_public_custom_network_acl ? length(var.public_inbound_acl_rules) : 0

  network_acl_id = aws_network_acl.public[0].id

  rule_number = var.public_inbound_acl_rules[count.index]["rule_number"]
  egress      = false
  protocol    = var.public_inbound_acl_rules[count.index]["protocol"]
  rule_action = var.public_inbound_acl_rules[count.index]["rule_action"]
  cidr_block  = lookup(var.public_inbound_acl_rules[count.index], "cidr_block", null)
  from_port   = lookup(var.public_inbound_acl_rules[count.index], "from_port", null)
  to_port     = lookup(var.public_inbound_acl_rules[count.index], "to_port", null)

  icmp_code       = lookup(var.public_inbound_acl_rules[count.index], "icmp_code", null)
  icmp_type       = lookup(var.public_inbound_acl_rules[count.index], "icmp_type", null)
  ipv6_cidr_block = lookup(var.public_inbound_acl_rules[count.index], "ipv6_cidr_block", null)
}



resource "aws_network_acl_rule" "public_outbound" {
  count = local.create_public_subnets && var.create_public_custom_network_acl ? length(var.public_outbound_acl_rules) : 0

  network_acl_id = aws_network_acl.public[0].id

  rule_number = var.public_outbound_acl_rules[count.index]["rule_number"]
  egress      = true
  protocol    = var.public_outbound_acl_rules[count.index]["protocol"]
  rule_action = var.public_outbound_acl_rules[count.index]["rule_action"]
  cidr_block  = lookup(var.public_outbound_acl_rules[count.index], "cidr_block", null)
  from_port   = lookup(var.public_outbound_acl_rules[count.index], "from_port", null)
  to_port     = lookup(var.public_outbound_acl_rules[count.index], "to_port", null)

  icmp_code       = lookup(var.public_outbound_acl_rules[count.index], "icmp_code", null)
  icmp_type       = lookup(var.public_outbound_acl_rules[count.index], "icmp_type", null)
  ipv6_cidr_block = lookup(var.public_outbound_acl_rules[count.index], "ipv6_cidr_block", null)
}

#------------------
# Private NACLs
#------------------
locals {
  create_private_network_acl = local.create_private_subnets && var.create_private_custom_network_acl
}

resource "aws_network_acl" "private" {
  count = local.create_private_network_acl ? 1 : 0

  vpc_id     = local.vpc_id
  subnet_ids = aws_subnet.private_subnet[*].id

  tags = merge(
    { "Name" : "${local.name_prefix}-private-acl-${count.index + 1}" },
    var.private_acl_tags,
    var.custom_tags,
  )
}


resource "aws_network_acl_rule" "private_inbound" {
  count = local.create_private_network_acl ? length(var.private_inbound_acl_rules) : 0

  network_acl_id = aws_network_acl.private[0].id

  egress      = false
  rule_number = var.private_inbound_acl_rules[count.index]["rule_number"]
  rule_action = var.private_inbound_acl_rules[count.index]["rule_action"]
  from_port   = lookup(var.private_inbound_acl_rules[count.index], "from_port", null)
  to_port     = lookup(var.private_inbound_acl_rules[count.index], "to_port", null)
  protocol    = var.private_inbound_acl_rules[count.index]["protocol"]
  cidr_block  = lookup(var.private_inbound_acl_rules[count.index], "cidr_block", null)

  icmp_code       = lookup(var.private_inbound_acl_rules[count.index], "icmp_code", null)
  icmp_type       = lookup(var.private_inbound_acl_rules[count.index], "icmp_type", null)
  ipv6_cidr_block = lookup(var.private_inbound_acl_rules[count.index], "ipv6_cidr_block", null)
}

resource "aws_network_acl_rule" "private_outbound" {
  count          = local.create_private_network_acl ? length(var.private_outbound_acl_rules) : 0
  network_acl_id = aws_network_acl.private[0].id

  egress      = true
  rule_number = var.private_outbound_acl_rules[count.index]["rule_number"]
  rule_action = var.private_outbound_acl_rules[count.index]["rule_action"]
  from_port   = lookup(var.private_outbound_acl_rules[count.index], "from_port", null)
  to_port     = lookup(var.private_outbound_acl_rules[count.index], "to_port", null)
  protocol    = var.private_outbound_acl_rules[count.index]["protocol"]
  cidr_block  = lookup(var.private_outbound_acl_rules[count.index], "cidr_block", null)

  icmp_code       = lookup(var.private_outbound_acl_rules[count.index], "icmp_code", null)
  icmp_type       = lookup(var.private_outbound_acl_rules[count.index], "icmp_type", null)
  ipv6_cidr_block = lookup(var.private_outbound_acl_rules[count.index], "ipv6_cidr_block", null)
}






#----------------------------
# Database Subnets
# ---------------------------
locals {
  create_database_subnets = var.create && !var.use_existing_vpc && local.len_database_subnets > 0
  create_database_rtb     = local.create_database_subnets && var.create_database_subnet_route_table
}

resource "aws_subnet" "database_subnet" {
  count             = local.create_database_subnets ? local.len_database_subnets : 0
  vpc_id            = local.vpc_id
  cidr_block        = var.database_subnet_cidr_blocks[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(
    { Name = "${local.name_prefix}-db-subnet-${count.index + 1}" },
    var.database_subnet_tags,
    var.custom_tags
  )
}


resource "aws_db_subnet_group" "database" {
  count = local.create_database_subnets && var.create_database_subnet_group ? 1 : 0

  name        = "${local.name_prefix}-db-subnet-group"
  description = "Database subnet group for ${var.name}"
  subnet_ids  = aws_subnet.database_subnet[*].id

  tags = merge(
    {
      Name = "${local.name_prefix}-db-subnet-group"
    },
    var.database_subnet_group_tags,
    var.custom_tags
  )
}



resource "aws_route_table" "database_rtb" {
  count  = local.create_database_rtb ? var.single_nat_gateway ? 1 : local.len_database_subnets : 0
  vpc_id = local.vpc_id

  tags = merge(
    { "Name" = "${local.name_prefix}-database-rtb-${count.index + 1}" },
    var.custom_tags
  )
}

# Database Route Table Association with subnet
resource "aws_route_table_association" "database" {
  count     = local.create_database_rtb ? local.len_database_subnets : 0
  subnet_id = element(aws_subnet.database_subnet[*].id, count.index)
  route_table_id = element(
    aws_route_table.database_rtb[*].id, var.single_nat_gateway ? 0 : count.index
  )
}

resource "aws_route" "database_nat_gateway" {
  count = local.create_database_rtb && var.create_database_nat_gateway_route && var.enable_nat_gateway ? var.single_nat_gateway ? 1 : local.len_database_subnets : 0

  route_table_id         = element(aws_route_table.database_rtb[*].id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.this[*].id, count.index)

  timeouts {
    create = "5m"
  }
}
