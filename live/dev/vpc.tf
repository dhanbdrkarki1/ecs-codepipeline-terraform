#================================
# Amazon VPC
#================================
module "vpc" {
  source = "../../modules/aws/vpc"
  create = true

  name                       = "vpc"
  availability_zones         = var.availability_zones
  cidr_block                 = "192.168.0.0/16"
  public_subnet_cidr_blocks  = ["192.168.0.0/23", "192.168.2.0/23"]
  private_subnet_cidr_blocks = ["192.168.4.0/24"]

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
