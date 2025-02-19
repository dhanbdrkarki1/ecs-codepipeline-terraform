# vpc
variable "create" {
  description = "If true, allow creating vpc."
  type        = bool
  default     = true
}

variable "name" {
  description = "The name of the VPC."
  type        = string
  default     = ""
}

variable "vpc_id" {
  description = "The ID of the VPC endpoint."
  type        = string
  default     = ""
}

variable "vpc_endpoint_type" {
  description = "The type of VPC endpoint."
  type        = string
  default     = "Interface"
}

variable "cidr_block" {
  description = "The IPv4 CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}


variable "tenancy" {
  description = "The tenancy option for instances launched into the VPC."
  type        = string
  default     = "default"
}

variable "enable_dns_hostnames" {
  description = "If true, enable DNS hostnames in the VPC."
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "If true, enable DNS support in the VPC."
  type        = bool
  default     = true
}

variable "vpc_tags" {
  description = "The additional tags for the VPC."
  type        = map(string)
  default     = {}
}





variable "availability_zones" {
  description = "The list of availability zones names or ids in the region."
  type        = list(string)
  default     = []
}

# VPC Endpoints
variable "create_vpc_endpoints" {
  description = "Whether to create VPC endpoints"
  type        = bool
  default     = false
}

variable "endpoints" {
  description = "A map of VPC endpoints configuration"
  type = map(object({
    service             = string
    vpc_endpoint_type   = string
    private_dns_enabled = optional(bool, null)
    subnet_ids          = optional(list(string), [])
    security_group_ids  = optional(list(string), [])
    route_table_ids     = optional(list(string), [])
  }))
  default = {}
}


#----------------
# public subnets
#----------------

variable "public_subnet_cidr_blocks" {
  description = "The list of cidr blocks for public subnets."
  type        = list(string)
  default     = []
}

variable "map_public_ip_on_launch" {
  description = "If true, indicate that instances launched into the public subnet should be assigned a public IP address."
  type        = bool
  default     = false
}


variable "public_subnet_tags" {
  description = "The tags for public subnet in a VPC."
  type        = map(string)
  default     = {}
}


#----------------
# internet gateway
#----------------

variable "create_igw" {
  description = "If true, allow creating internet gateway for VPC."
  type        = bool
  default     = true
}

variable "igw_tags" {
  description = "The tags for internet gateway."
  type        = map(string)
  default     = {}
}

#------------------
# private subnets
#------------------

variable "private_subnet_cidr_blocks" {
  description = "The list of cidr blocks for private subnets."
  type        = list(string)
  default     = []
}

variable "private_subnet_tags" {
  description = "The tags for private subnet in a VPC."
  type        = map(string)
  default     = {}
}


#------------
# NAT
#------------

variable "enable_nat_gateway" {
  description = "If true,provision NAT Gateways for each of private networks"
  type        = bool
  default     = false
}

variable "nat_gateway_destination_cidr_block" {
  description = "Used to pass a custom destination route for private NAT Gateway. If not specified, the default 0.0.0.0/0 is used as a destination route"
  type        = string
  default     = "0.0.0.0/0"
}

variable "single_nat_gateway" {
  description = "If true, provision a single shared NAT Gateway across all of the private networks"
  type        = bool
  default     = false
}

variable "one_nat_gateway_per_az" {
  description = "If true, provision one NAT Gateway per AZ. Requires var.availability_zones set, with public_subnets count >= specified var.availability_zones."
  type        = bool
  default     = false
}

variable "nat_gateway_tags" {
  description = "Additional tags for the NAT gateways"
  type        = map(string)
  default     = {}
}

variable "nat_eip_tags" {
  description = "Additional tags for the NAT EIP"
  type        = map(string)
  default     = {}
}


#---------------------
# Public NACLs
#---------------------
variable "create_public_custom_network_acl" {
  description = "If true, allow to create custom rules for public subnets."
  type        = bool
  default     = false

}

variable "public_inbound_acl_rules" {
  description = "The inbound ACLs rules for public subnets."
  type        = list(map(string))
  default = [
    {
      rule_number = 100
      rule_action = "allow"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_block  = "0.0.0.0/0"
    },
  ]
}

variable "public_outbound_acl_rules" {
  description = "The outbound ACLs rules for public subnets."
  type        = list(map(string))
  default = [
    {
      rule_number = 100
      rule_action = "allow"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_block  = "0.0.0.0/0"
    },
  ]
}

variable "public_acl_tags" {
  description = "Additional tags for the public subnets network ACL"
  type        = map(string)
  default     = {}
}


#---------------------
# Private Network ACLs
#----------------------
variable "create_private_custom_network_acl" {
  description = "If true, allow to create custom rules for private subnets."
  type        = bool
  default     = false

}

variable "private_inbound_acl_rules" {
  description = "The inbound network ACLs for private subnets."
  type        = list(map(string))
  default = [
    {
      rule_number = 100
      rule_action = "allow"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_block  = "0.0.0.0/0"
    },
  ]
}

variable "private_outbound_acl_rules" {
  description = "The outbound network ACLs for private subnets."
  type        = list(map(string))
  default = [
    {
      rule_number = 100
      rule_action = "allow"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_block  = "0.0.0.0/0"
    },
  ]
}

variable "private_acl_tags" {
  description = "Additional tags for the private subnets network ACL"
  type        = map(string)
  default     = {}
}



#------------------
# database subnets
#------------------

variable "database_subnet_cidr_blocks" {
  description = "The list of cidr blocks for database subnets."
  type        = list(string)
  default     = []
}


variable "create_database_subnet_route_table" {
  description = "Controls if separate route table for database should be created"
  type        = bool
  default     = false
}

variable "create_database_nat_gateway_route" {
  description = "Controls if a nat gateway route should be created to give internet access to the database subnets"
  type        = bool
  default     = false
}

variable "database_route_table_tags" {
  description = "Additional tags for the database route tables"
  type        = map(string)
  default     = {}
}


variable "create_database_subnet_group" {
  description = "Controls if database subnet group should be created (n.b. database_subnets must also be set)"
  type        = bool
  default     = true
}

variable "database_subnet_group_name" {
  description = "Name of database subnet group"
  type        = string
  default     = null
}

variable "database_subnet_group_tags" {
  description = "Additional tags for the database subnet group"
  type        = map(string)
  default     = {}
}

variable "database_subnet_tags" {
  description = "Additional tags for the database subnets"
  type        = map(string)
  default     = {}
}

# VPC FloW Log
variable "enable_flow_log" {
  description = "Specify whether to capture IP traffic for a VPC or not and sent to  a CloudWatch Log Group, a S3 Bucket, or Amazon Kinesis Data Firehose."
  type        = bool
  default     = false
}

variable "traffic_type" {
  description = "The type of traffic to capture. Valid values: ACCEPT,REJECT, ALL."
  type        = string
  default     = "ALL"
}

variable "iam_role_arn" {
  description = "The ARN for the IAM role that's used to post flow logs to a CloudWatch Logs log group"
  type        = string
  default     = null
}

variable "log_destination_type" {
  description = "The type of the logging destination. Valid values: cloud-watch-logs, s3, kinesis-data-firehose. Default: cloud-watch-logs."
  type        = string
  default     = "cloud-watch-logs"
}

variable "log_destination" {
  description = "The ARN of the logging destination. Either log_destination or log_group_name must be set."
  type        = string
  default     = null
}

variable "log_format" {
  description = "The fields to include in the flow log record."
  type        = string
  default     = "$${version} $${interface-id} $${srcaddr} $${dstaddr} $${srcport} $${dstport} $${protocol} $${packets} $${bytes} $${start} $${end} $${action} $${log-status}"
}

variable "max_aggregation_interval" {
  description = "The maximum interval of time during which a flow of packets is captured and aggregated into a flow log record. Valid Values: 60 seconds (1 minute) or 600 seconds (10 minutes)."
  type        = number
  default     = 600
}

# Tags
variable "custom_tags" {
  description = "The custom tags for all the resources."
  type        = map(string)
  default     = {}
}



# Existing Resources
variable "use_existing_vpc" {
  description = "Flag to indicate whether to use an existing VPC"
  type        = bool
  default     = false
}

variable "existing_vpc_filters" {
  description = "Filters for existing VPC"
  type = list(object({
    name   = string
    values = list(string)
  }))
  default = []
}

variable "existing_public_subnet_filters" {
  description = "Filters for existing public subnets"
  type = list(object({
    name   = string
    values = list(string)
  }))
  default = []
}

variable "existing_private_subnet_filters" {
  description = "Filters for existing private subnets"
  type = list(object({
    name   = string
    values = list(string)
  }))
  default = []
}

# variable "existing_vpc_name" {
#   description = "Name tag of the existing VPC to use"
#   type        = string
#   default     = ""
# }

# variable "use_existing_subnets" {
#   description = "Flag to indicate whether to use existing subnets"
#   type        = bool
#   default     = false
# }

# variable "use_existing_subnets" {
#   description = "Flag to indicate whether to use existing subnets"
#   type        = bool
#   default     = false
# }
