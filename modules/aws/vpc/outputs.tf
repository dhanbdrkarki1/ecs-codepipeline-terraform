output "vpc_id" {
  value = !var.use_existing_vpc ? try(aws_vpc.this[0].id, null) : try(data.aws_vpc.existing[0].id, null)
}

output "vpc_cidr_block" {
  value = !var.use_existing_vpc ? try(aws_vpc.this[0].cidr_block, null) : try(data.aws_vpc.existing[0].cidr_block, null)
}

output "public_subnet_ids" {
  value = !var.use_existing_vpc ? try(aws_subnet.public_subnet[*].id, null) : try(data.aws_subnets.public_subnets[0].ids, null)
}

output "private_subnet_ids" {
  value = !var.use_existing_vpc ? try(aws_subnet.private_subnet[*].id, null) : try(data.aws_subnets.private_subnets[0].ids, null)
}

output "private_route_table_ids" {
  value = !var.use_existing_vpc ? try(aws_route_table.private_rtb[*].id, null) : try(data.aws_route_table.private_rtb[0].id, null)
}

output "availability_zones" {
  value = try(var.availability_zones, null)
}
