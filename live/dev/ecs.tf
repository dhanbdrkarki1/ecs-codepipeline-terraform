# ECS
module "ecs" {
  source = "./modules/services/ecs"
  create = var.create_ecs
  name   = var.ecs_name

  security_groups_ids = [module.sg_ecs_task.security_group_id]
  subnet_groups_ids   = module.vpc_data.private_subnet_ids
  target_group        = module.alb_data.alb_target_group_arns["ip"]

  ecs_task_family_name = var.ecs_task_family_name
  container_name       = var.ecs_container_name
  app_image            = module.ecr.repository_url

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

  #S3 bucket
  s3_bucket_arn = module.s3.bucket_arn

  # efs - need to set create=true in efs.hcl and sg_efs.hcl
  mount_efs_volume = var.ecs_mount_efs_volume
  # efs_file_system_id = dependency.efs.outputs.id 
  container_path            = var.ecs_container_path             # path on the container to mount the host volume at e.g. /app
  read_only                 = var.ecs_read_only_container_volume # read-only access to the volume
  enable_container_insights = var.ecs_enable_container_insights

  # If CodeDeploy is used for deployment, set deployment_controller_type = "CODE_DEPLOY" otherwise "ECS" for ECS deployment type.
  deployment_controller_type = var.ecs_deployment_controller_type

  # require for health check to pass
  health_check_grace_period = var.ecs_health_check_grace_period
  aws_region                = var.aws_region
  custom_tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}
