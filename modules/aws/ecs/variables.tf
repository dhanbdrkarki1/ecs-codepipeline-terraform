#########
# ECS
#########

# variable "create" {
#   default     = false
#   type        = bool
#   description = "Specify whether to create resource or not"
# }

variable "create_cluster" {
  default     = false
  type        = bool
  description = "Specify whether to create ECS cluster or not"
}

variable "create_services" {
  default     = false
  type        = bool
  description = "Specify whether to create ECS service or not"
}

variable "name" {
  description = "Name to be used on ECS cluster created"
  type        = string
  default     = ""
}

##############
# Cluster
##############
variable "cluster_id" {
  description = "The ID of the ECS Cluster"
  default     = null
  type        = string
}

variable "cluster_name" {
  description = "The Name of the ECS Cluster"
  default     = null
  type        = string
}

variable "cluster_configuration" {
  description = "The execute command configuration for the cluster"
  type        = any
  default     = {}
}

variable "cluster_settings" {
  description = "List of configuration block(s) with cluster settings. For example, this can be used to enable CloudWatch Container Insights for a cluster"
  type        = any
  default = [
    {
      name  = "containerInsights"
      value = "enabled"
    }
  ]
}

variable "cluster_service_connect_defaults" {
  description = "Configures a default Service Connect namespace"
  type        = map(string)
  default     = {}
}

##############
# Service
##############

####################
# Task Definition
#####################
variable "create_task_definition" {
  description = "Determines whether to create a task definition or use existing/provided"
  type        = bool
  default     = true
}

variable "task_definition_arn" {
  description = "Existing task definition ARN. Required when `create_task_definition` is `false`"
  type        = string
  default     = null
}

variable "network_mode" {
  description = "Docker networking mode to use for the containers in the task. Valid values are `none`, `bridge`, `awsvpc`, and `host`"
  type        = string
  default     = "awsvpc"
}

variable "requires_compatibilities" {
  description = "Set of launch types required by the task. The valid values are `EC2` and `FARGATE`"
  type        = list(string)
  default     = ["FARGATE"]
}


#---------------------------
# Container Task Definition
#---------------------------
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

variable "host_port" {
  description = "Port exposed by the Host Instance like EC2"
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

variable "desired_count" {
  description = "Number of instances of the task definition to place and keep running."
  type        = number
  default     = 2
}


variable "aws_region" {
  type        = string
  description = "The AWS region things are created in"
  default     = "us-east-1"
}

variable "container_definition_template" {
  description = "Template file for Container Definition to be used by ECS Service."
  default     = null
  type        = string
}

variable "container_definitions" {
  description = "A map of valid [container definitions](http://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_ContainerDefinition.html). Please note that you should only provide values that are part of the container definition document"
  type        = any
  default     = {}
}




variable "deployment_circuit_breaker" {
  description = "Configuration block for deployment circuit breaker"
  type        = any
  default     = {}
}

variable "deployment_controller" {
  description = "Configuration block for deployment controller configuration"
  type        = any
  default     = {}
}

variable "deployment_maximum_percent" {
  description = "Upper limit (as a percentage of the service's `desired_count`) of the number of running tasks that can be running in a service during a deployment"
  type        = number
  default     = 200
}

variable "deployment_minimum_healthy_percent" {
  description = "Lower limit (as a percentage of the service's `desired_count`) of the number of running tasks that must remain running and healthy in a service during a deployment"
  type        = number
  default     = 66
}

variable "load_balancer" {
  description = "Configuration block for load balancers"
  type        = any
  default     = {}
}

# variable "deployment_controller_type" {
#   type        = string
#   default     = "ECS"
#   description = "Type of deployment controller. Valid values: CODE_DEPLOY, ECS, EXTERNAL"
# }

# variable "enable_deployment_circuit_breaker" {
#   description = "Whether to enable the deployment circuit breaker logic for the service."
#   default     = false
#   type        = bool
# }

# variable "enable_deployment_circuit_breaker_rollback" {
#   description = "Whether to enable Amazon ECS to roll back the service if a service deployment fails. If rollback is enabled, when a service deployment fails, the service is rolled back to the last deployment that completed successfully."
#   default     = false
#   type        = bool
# }
















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

variable "assign_public_ip" {
  description = "Assign a public IP address to the ENI (Fargate launch type only)"
  type        = bool
  default     = false
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

#######################
# Capacity Providers
#######################
variable "capacity_provider_strategy" {
  description = "Capacity provider strategies to use for the service. Can be one or more"
  type        = any
  default     = {}
}

variable "default_capacity_provider_use_fargate" {
  description = "Determines whether to use Fargate or autoscaling for default capacity provider strategy"
  type        = bool
  default     = true
}

variable "fargate_capacity_providers" {
  description = "Map of Fargate capacity provider definitions to use for the cluster"
  type        = any
  default     = {}
}

variable "autoscaling_capacity_providers" {
  description = "Map of autoscaling capacity provider definitions to create for the cluster"
  type        = any
  default     = {}
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

# Log Group
variable "ecs_log_group_name" {
  description = "CloudWatch Log Group name for ECS logs"
  type        = string
  default     = null
}

# IAM Role
variable "ecs_task_execution_role" {
  description = "ARN of the IAM role that allows Amazon ECS to make calls to other AWS services."
  type        = string
  default     = null
}

variable "ecs_auto_scale_role" {
  description = "ARN of IAM role for ECS auto scaling"
  type        = string
  default     = null
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

# Service
variable "launch_type" {
  description = "Launch type on which to run your service. The valid values are `EC2`, `FARGATE`, and `EXTERNAL`. Defaults to `FARGATE`"
  type        = string
  default     = "FARGATE"
}

variable "scheduling_strategy" {
  description = "Scheduling strategy to use for the service. The valid values are `REPLICA` and `DAEMON`. Defaults to `REPLICA`"
  type        = string
  default     = "REPLICA"
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
