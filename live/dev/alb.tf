#================================
# AWS Load Balancer
#================================
module "alb" {
  source              = "../../modules/aws/alb"
  create              = true
  name                = "web-app-lb"
  vpc_id              = module.vpc.vpc_id
  subnet_groups_ids   = module.vpc.public_subnet_ids
  security_groups_ids = [module.alb_sg.security_group_id]
  health_check_path   = "/"

  target_groups = local.alb_target_groups

  listeners = local.alb_listeners

  custom_tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}
