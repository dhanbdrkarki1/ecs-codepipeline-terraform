#########
# ECS
#########

variable "create" {
  default     = false
  type        = bool
  description = "Specify whether to create resource or not"
}

variable "name" {
  description = "Name to be used on ECS cluster created"
  type        = string
  default     = ""
}

variable "security_groups_ids" {
  description = "A list of security group IDs to assign to the ECS Task"
  type        = list(string)
  default     = []
}

variable "subnet_groups_ids" {
  description = "A list of subnet group IDs to assign to the ECS Task"
  type        = list(string)
  default     = []
}


variable "ecs_task_family_name" {
  description = "The name of the family on ECS task definition."
  type        = string
  default     = ""
}
#load balancer

variable "target_group" {
  description = "ARN of the Target Group to which to route traffic. "
  type        = string
  default     = ""
}


variable "health_check_grace_period" {
  description = "Seconds to ignore failing load balancer health checks on newly instantiated tasks to prevent premature shutdown"
  type        = number
  default     = 300
}


# S3 Bucket
variable "s3_bucket_arn" {
  type        = string
  description = "The ARN of the S3 bucket where ecs task access files from"
  default     = ""
}

# Auto Scaling
variable "service_namespace" {
  type        = string
  default     = "ecs"
  description = "AWS service namespace of the scalable target."
}


variable "scalable_dimension" {
  type        = string
  default     = "ecs:service:DesiredCount"
  description = "Scalable dimension of the scalable target."
}


variable "min_capacity" {
  description = "Minimum capacity of the scalable target of ECS"
  type        = number
  default     = 2
}

variable "max_capacity" {
  description = "Maximum capacity of the scalable target of ECS"
  type        = number
  default     = 4
}

# Step scaling
variable "scale_up_adjustment" {
  description = "Scale up adjustment value for ECS Auto scaling"
  type        = number
  default     = 1
}

variable "scale_down_adjustment" {
  description = "Scale down adjustment value for ECS Auto scaling"
  type        = number
  default     = -1
}

variable "cooldown_period" {
  description = "Cooldown period in seconds"
  type        = number
  default     = 60
}

variable "step_scaling_metric_aggregation_type" {
  description = "Aggregation type for the policy's metrics."
  type        = string
  default     = "Maximum"
}

variable "step_scaling_adjustment_type" {
  description = "Whether the adjustment is an absolute number or a percentage of the current capacity. Valid values are ChangeInCapacity, ExactCapacity, and PercentChangeInCapacity."
  type        = string
  default     = "ChangeInCapacity"
}


variable "log_retention_in_days" {
  type        = number
  description = "Specifies the number of days you want to retain log events in the specified log group."
  default     = 30
}


# EFS
variable "mount_efs_volume" {
  type        = bool
  default     = false
  description = "Specify whether to mount EFS volume in the ECS container or not."
}

variable "efs_file_system_id" {
  type        = string
  description = "The id of the EFS file system"
  default     = null

}

variable "volume_root_directory" {
  type        = string
  description = "The root directory of the EFS file system to be attached with ECS task."
  default     = "/"
}

variable "enable_transit_encryption" {
  type        = string
  description = "Whether or not to enable encryption for Amazon EFS data in transit between the Amazon ECS host and the Amazon EFS server. "
  default     = "ENABLED"
}

variable "transit_encryption_port" {
  type        = number
  description = "Port to use for transit encryption in Amazon EFS"
  default     = 2049
}

#---------------------------
# Container Task Definition
#---------------------------
#container
variable "container_name" {
  description = "The name of the container running ECS tasks"
  type        = string
  default     = ""
}


variable "app_image" {
  description = "Docker image to run in the ECS cluster"
  type        = string
  default     = ""
}


variable "container_port" {
  description = "Port exposed by the docker image to redirect traffic to"
  type        = number
  default     = 80

}

variable "app_cpu" {
  description = "Fargate instance CPU units to provision (1 vCPU = 1024 CPU units)"
  type        = string
  default     = "256"
}

variable "app_memory" {
  description = "Fargate instance memory to provision (in MiB)"
  type        = string
  default     = "512"
}

variable "desired_container_count" {
  description = "Number of instances of the task definition to place and keep running."
  type        = number
  default     = 2
}


variable "aws_region" {
  type        = string
  description = "The AWS region things are created in"
  default     = "us-east-1"
}


# Mount Points
variable "container_path" {
  type        = string
  default     = "/"
  description = "The path on the container to mount the host volume at."
}

variable "read_only" {
  type        = bool
  default     = true
  description = "If this value is true, the container has read-only access to the volume. If this value is false, then the container can write to the volume."
}

# variable "source_volume" {
#   type = string
#   default = null
#   description = "The name of the volume to mount. Must be a volume name referenced in the name parameter of task definition volume"
# }


# Deployment
variable "deployment_controller_type" {
  type        = string
  default     = "ECS"
  description = "Type of deployment controller. Valid values: CODE_DEPLOY, ECS, EXTERNAL"
}

variable "enable_deployment_circuit_breaker" {
  description = "Whether to enable the deployment circuit breaker logic for the service."
  default     = false
  type        = bool
}

variable "enable_deployment_circuit_breaker_rollback" {
  description = "Whether to enable Amazon ECS to roll back the service if a service deployment fails. If rollback is enabled, when a service deployment fails, the service is rolled back to the last deployment that completed successfully."
  default     = false
  type        = bool
}

variable "enable_container_insights" {
  description = "Whether to enable Amazon ECS container insights on Cluster"
  default     = false
  type        = bool
}

# New Relic Monitoring
variable "enable_newrelic_monitoring" {
  type        = bool
  default     = true
  description = "Specify whether to enable new relic sidecar container for monitoring or not."
}

variable "newrelic_license_key_parameter_name" {
  type        = string
  default     = "/newrelic-infra/ecs/license-key"
  description = "The parameter name for New Relic license key. Get it from new relic one."
  sensitive   = true
}

variable "new_relic_image" {
  type        = string
  default     = "newrelic/nri-ecs:1.11.6"
  description = "The name of the new relic infrastructure image used as a sidecar container with the main container."
}

variable "new_relic_cpu" {
  description = "CPU units for the New Relic sidecar container"
  type        = number
  default     = 256
}

variable "new_relic_memory" {
  description = "Memory in MiB for the New Relic sidecar container"
  type        = number
  default     = 512
}


# Tags
variable "ecs_tags" {
  description = "Tags to set on the ECS."
  type        = map(string)
  default     = {}
}

variable "custom_tags" {
  description = "Custom tags to set on all the resources."
  type        = map(string)
  default     = {}
}
