#================================
# Global
#================================
variable "project_name" {
  description = "Name of the Project"
  type        = string
}

variable "environment" {
  description = "Environment of the project"
  default     = "test"
  type        = string
}

variable "aws_region" {
  default     = "us-east-1"
  description = "AWS Region to deploy resources"
  type        = string
}

variable "availability_zones" {
  description = "The list of availability zones names or ids in the region."
  type        = list(string)
  default     = []
}



#================================
# ECS
#================================
variable "create_ecs" {
  default     = false
  type        = bool
  description = "Specify whether to create resource or not"
}

variable "ecs_name" {
  description = "Name to be used on ECS cluster created"
  type        = string
  default     = ""
}

variable "ecs_task_family_name" {
  description = "The name of the family on ECS task definition."
  type        = string
  default     = ""
}

variable "ecs_container_name" {
  description = "The name of the container running ECS tasks"
  type        = string
  default     = ""
}

variable "ecs_container_port" {
  description = "Port exposed by the docker image to redirect traffic to"
  type        = number
  default     = 80
}


variable "ecs_app_cpu" {
  description = "Fargate instance CPU units to provision (1 vCPU = 1024 CPU units)"
  type        = string
  default     = "256"
}

variable "ecs_app_memory" {
  description = "Fargate instance memory to provision (in MiB)"
  type        = string
  default     = "512"
}

variable "ecs_desired_container_count" {
  description = "Number of instances of the task definition to place and keep running."
  type        = number
  default     = 2
}

# ECS Scaling
variable "ecs_min_capacity" {
  description = "Minimum capacity of the scalable target of ECS"
  type        = number
  default     = 2
}

variable "ecs_max_capacity" {
  description = "Maximum capacity of the scalable target of ECS"
  type        = number
  default     = 4
}

variable "ecs_scale_up_adjustment" {
  description = "Scale up adjustment value for ECS Auto scaling"
  type        = number
  default     = 1
}

variable "ecs_scale_down_adjustment" {
  description = "Scale down adjustment value for ECS Auto scaling"
  type        = number
  default     = -1
}

variable "ecs_cooldown_period" {
  description = "Cooldown period in seconds"
  type        = number
  default     = 60
}

variable "ecs_mount_efs_volume" {
  type        = bool
  default     = false
  description = "Specify whether to mount EFS volume in the ECS container or not."
}

variable "ecs_container_path" {
  type        = string
  default     = "/"
  description = "The path on the container to mount the host volume at."
}

variable "ecs_read_only_container_volume" {
  type        = bool
  default     = true
  description = "If this value is true, the container has read-only access to the volume. If this value is false, then the container can write to the volume."
}

variable "ecs_enable_container_insights" {
  description = "Whether to enable Amazon ECS container insights on Cluster"
  default     = false
  type        = bool
}

variable "ecs_deployment_controller_type" {
  type        = string
  default     = "ECS"
  description = "Type of deployment controller. Valid values: CODE_DEPLOY, ECS, EXTERNAL"
}

variable "ecs_health_check_grace_period" {
  description = "Seconds to ignore failing load balancer health checks on newly instantiated tasks to prevent premature shutdown"
  type        = number
  default     = 300
}
