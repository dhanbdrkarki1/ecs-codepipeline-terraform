####################
# ALB
####################

# Load Balancer
variable "create" {
  default     = false
  type        = bool
  description = "Specify whether to create resource or not"
}

variable "name" {
  description = "The name of the load balancer."
  type        = string
  default     = "test-load-balancer"
}

variable "load_balancer_type" {
  description = "The type of load balancer to create. Possible values are `application`, `gateway`, or `network`. The default value is `application`"
  type        = string
  default     = "application"
}

variable "security_groups_ids" {
  description = "A list of security group IDs to assign to the ALB"
  type        = list(string)
  default     = []
}

variable "subnet_groups_ids" {
  description = "A list of subnet group IDs to assign to the ALB"
  type        = list(string)
  default     = []
}


variable "alb_target_group_name" {
  description = "The name of the load balancer's target group."
  default     = "test-lb-tg"
  type        = string
}

variable "vpc_id" {
  type        = string
  description = "The id of the VPC where ALB will be placed."
  default     = null
}


# Listener
variable "default_port" {
  description = "Default port used across the listener and target group"
  type        = number
  default     = 80
}

variable "default_protocol" {
  description = "Default protocol used across the listener and target group"
  type        = string
  default     = "HTTP"
}

variable "listeners" {
  description = "Map of listener configurations to create"
  type        = any
  default     = {}
}

################

# Target group
variable "target_groups" {
  description = "Map of target group configurations to create"
  type        = any
  default     = {}
}

##############


variable "container_port" {
  type        = number
  description = "The exposed port of the container."
  default     = null
}

variable "health_check_path" {
  type        = string
  description = "Path to confirm the availability of backend servers by load balancers."
  default     = "/"
}


variable "lb_tags" {
  description = "Tags to set on the Load Balancers."
  type        = map(string)
  default     = {}
}

variable "use_existing_load_balancer" {
  description = "Whether to use ARN of the existing load balancer, if any."
  type        = bool
  default     = false
}

variable "existing_lb_arn" {
  description = "ARN of the existing load balancer, if any."
  type        = string
  default     = null
}

variable "listener_protocol" {
  description = "The protocol for the listener. Supported values are HTTP and HTTPS."
  type        = string
  default     = "HTTP"
}


variable "custom_tags" {
  description = "Custom tags to set on all the resources."
  type        = map(string)
  default     = {}
}

variable "ssl_policy" {
  description = "Security policy to manage SSL connections with clients"
  type        = string
  default     = null
}


variable "certificate_arn" {
  description = "ARN of the existing Amazon ACM certificate, if any."
  type        = string
  default     = null
}
