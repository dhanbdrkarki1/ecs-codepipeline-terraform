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

#================================
# Amazon ACM
#================================
# variable "create_acm_certificate" {
#   description = "Specify whether to create acm certificate or not."
#   default     = false
#   type        = bool
# }

# variable "domain_name" {
#   description = "Name of the root domain"
#   type        = string
# }

# variable "subject_alternative_names" {
#   description = "Set of domains that should be SANs in the issued certificate."
#   type        = list(string)
#   default     = null
# }

# variable "acm_validation_method" {
#   type        = string
#   default     = "DNS"
#   description = "Which method to use for validation. DNS or EMAIL are valid. This parameter must not be set for certificates that were imported into ACM and then into Terraform."
# }
