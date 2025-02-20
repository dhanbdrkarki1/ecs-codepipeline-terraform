#================================
# Global
#================================
project_name       = "dhan-custom"
aws_region         = "us-east-2"
availability_zones = ["us-east-2a", "us-east-2b"]
environment        = "dev"


#================================
# Elastic Container Service (ECS)
#================================
create_ecs           = true
ecs_name             = "todo-ecs-test"
ecs_task_family_name = "todo-test"

ecs_container_name = "todo-test"
ecs_container_port = 80
ecs_app_cpu        = 256
ecs_app_memory     = 512

ecs_desired_count         = 0
ecs_min_capacity          = 0
ecs_max_capacity          = 4
ecs_scale_up_adjustment   = 1
ecs_scale_down_adjustment = -1
ecs_cooldown_period       = 60

# efs - need to set create=true in efs.hcl and sg_efs.hcl
ecs_mount_efs_volume = false
# efs_file_system_id = dependency.efs.outputs.id 
ecs_container_path             = "/"   # path on the container to mount the host volume at e.g. /app
ecs_read_only_container_volume = false # read-only access to the volume
ecs_enable_container_insights  = true

# If CodeDeploy is used for deployment, set deployment_controller_type = "CODE_DEPLOY" otherwise "ECS" for ECS deployment type.
ecs_deployment_controller_type = "ECS"
