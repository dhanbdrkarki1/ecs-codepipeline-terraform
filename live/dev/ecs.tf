# ECS
module "ecs" {
  source = "./modules/services/ecs"
  create = var.create_ecs
  name   = var.ecs_name

  security_groups_ids = [module.ecs_sg.security_group_id]
  subnet_groups_ids   = module.vpc.public_subnet_ids
  target_group        = module.alb.alb_target_group_arns["ip"]

  ecs_task_family_name = var.ecs_task_family_name
  container_name       = var.ecs_container_name
  # app_image            = module.ecr.repository_url
  app_image = "public.ecr.aws/nginx/nginx:1.27-alpine3.21-slim"

  container_port          = var.ecs_container_port
  app_cpu                 = var.ecs_app_cpu
  app_memory              = var.ecs_app_memory
  desired_container_count = var.ecs_desired_container_count

  #scaling
  min_capacity          = var.ecs_min_capacity
  max_capacity          = var.ecs_max_capacity
  scale_up_adjustment   = var.ecs_scale_up_adjustment
  scale_down_adjustment = var.ecs_scale_down_adjustment
  cooldown_period       = var.ecs_cooldown_period

  # ECS Log Group
  ecs_log_group_name = module.ecs_log_group.name

  # ECS Role
  ecs_task_execution_role = module.ecs_task_execution_role.role_arn
  ecs_auto_scale_role     = module.ecs_auto_scale_role.role_arn

  #S3 bucket -> used to acce
  # s3_bucket_arn = module.s3.bucket_arn

  container_path            = var.ecs_container_path             # path on the container to mount the host volume at e.g. /app
  read_only                 = var.ecs_read_only_container_volume # read-only access to the volume
  enable_container_insights = var.ecs_enable_container_insights

  # If CodeDeploy is used for deployment, set deployment_controller_type = "CODE_DEPLOY" otherwise "ECS" for ECS deployment type.
  deployment_controller_type = var.ecs_deployment_controller_type

  # require for health check to pass
  health_check_grace_period = var.ecs_health_check_grace_period

  aws_region = var.aws_region

  # EFS
  mount_efs_volume = var.ecs_mount_efs_volume # if true, create efs and security group for efs
  # efs_file_system_id = module.efs.id 

  custom_tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}
