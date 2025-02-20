#================================
# Amazon VPC
#================================
module "vpc" {
  source = "../../modules/aws/vpc"
  create = true

  name                       = "dhan-vpc"
  cidr_block                 = "10.0.0.0/16"
  availability_zones         = var.availability_zones
  public_subnet_cidr_blocks  = ["10.0.0.0/24", "10.0.1.0/24"]
  private_subnet_cidr_blocks = ["10.0.2.0/24", "10.0.3.0/24"]
  # database_subnet_cidr_blocks = ["10.0.10.0/24", "10.0.11.0/24"]

  enable_dns_hostnames = true
  enable_dns_support   = true

  enable_nat_gateway     = false
  one_nat_gateway_per_az = false
  single_nat_gateway     = false

  custom_tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}
