#================================
# Web Security Groups
#================================
module "ecs_sg" {
  source              = "../../modules/aws/sg"
  create              = true
  name                = "ecs-sg"
  description         = "Security group for ECS."
  vpc_id              = module.vpc.vpc_id
  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["ssh-tcp", "http-80-tcp", "https-443-tcp"]
  egress_rules        = ["all-all"]
  custom_tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

#================================
# ALB Security Groups
#================================
module "alb_sg" {
  source              = "../../modules/aws/sg"
  create              = true
  name                = "alb-sg"
  description         = "Security group for ALB."
  vpc_id              = module.vpc.vpc_id
  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["http-80-tcp", "https-443-tcp"]
  egress_rules        = ["all-all"]
  custom_tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}
