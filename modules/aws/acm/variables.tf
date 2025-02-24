#=======================
# Amazon ACM
#=======================
variable "create" {
  description = "Whether to create Amazon ACM certificate and validate it or not"
  type        = bool
  default     = false
}

variable "domain_name" {
  description = "Name of the root domain"
  type        = string
}

variable "subject_alternative_names" {
  description = "Set of domains that should be SANs in the issued certificate."
  type        = list(string)
  default     = null
}

variable "acm_validation_method" {
  type        = string
  default     = "DNS"
  description = "Which method to use for validation. DNS or EMAIL are valid. This parameter must not be set for certificates that were imported into ACM and then into Terraform."
}

variable "custom_tags" {
  type        = map(string)
  default     = {}
  description = "Tags to assign to the Route53 Hosted Zone."
}
