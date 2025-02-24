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

variable "availability_zones" {
  description = "The list of availability zones names or ids in the region."
  type        = list(string)
  default     = []
}



#================================
# ECS
#================================
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
