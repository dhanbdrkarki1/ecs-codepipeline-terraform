variable "create" {
  description = "Specify whether to create resources or not"
  type        = bool
  default     = true
}

variable "ssm_parameters" {
  description = "A map of SSM parameters to create"
  type = map(object({
    name        = string
    description = string
    type        = string
    value       = string
  }))
  default = {}
}

variable "custom_tags" {
  description = "The custom tags for the security group."
  type        = map(string)
  default     = {}
}
