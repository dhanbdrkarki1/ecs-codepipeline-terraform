variable "create" {
  description = "Specify whether to create subscription filter or not."
  type        = bool
  default     = false
}

# CloudWatch Log Group
variable "name" {
  description = "Name of the CloudWatch log group"
  type        = string
  default     = null
}

variable "name_prefix" {
  description = "A name prefix for the log group"
  type        = string
  default     = null
}


variable "retention_in_days" {
  description = "Specifies the number of days you want to retain log events in the specified log group. Possible values are: 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, and 3653."
  type        = number
  default     = null

  validation {
    condition     = var.retention_in_days == null ? true : contains([0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.retention_in_days)
    error_message = "Must be 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653 or 0 (zero indicates never expire logs)."
  }
}

variable "kms_key_id" {
  type        = string
  description = "The KMS id for Cloudwatch logs group"
  default     = null
}

variable "log_group_class" {
  description = "Specified the log class of the log group. Possible values are: STANDARD or INFREQUENT_ACCESS"
  type        = string
  default     = null
}

variable "skip_destroy" {
  description = "Set to true if you do not wish the log group (and any logs it may contain) to be deleted at destroy time, and instead just remove the log group from the Terraform state"
  type        = bool
  default     = null
}


variable "subscription_filters" {
  description = "List of subscription filters to create"
  type = list(object({
    name            = string
    log_group_name  = string
    filter_pattern  = string
    destination_arn = string
    role_arn        = string
  }))
  default = []
}

variable "custom_tags" {
  description = "Custom tags to set on all the resources."
  type        = map(string)
  default     = {}
}

