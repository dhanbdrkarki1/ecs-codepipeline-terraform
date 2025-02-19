# Retrieve existing VPC based on filters
data "aws_vpc" "existing" {
  count = var.use_existing_vpc ? 1 : 0
  filter {
    name   = var.existing_vpc_filters[0].name
    values = var.existing_vpc_filters[0].values
  }
}

# Retrieve existing public subnets based on filters
data "aws_subnets" "public_subnets" {
  count = var.use_existing_vpc ? 1 : 0
  filter {
    name   = var.existing_public_subnet_filters[0].name
    values = var.existing_public_subnet_filters[0].values
  }
}

# Retrieve existing private subnets based on filters
data "aws_subnets" "private_subnets" {
  count = var.use_existing_vpc ? 1 : 0
  filter {
    name   = var.existing_private_subnet_filters[0].name
    values = var.existing_private_subnet_filters[0].values
  }
}

# Data source for existing route tables if using existing VPC
data "aws_route_table" "private_rtb" {
  count  = var.use_existing_vpc ? 1 : 0
  vpc_id = var.vpc_id

  filter {
    name   = "tag:Name"
    values = ["*private*"]
  }
}
