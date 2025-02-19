####################
# Database
####################

variable "create" {
  default     = false
  type        = bool
  description = "Specify whether to create resource or not"
}

variable "identifier_prefix" {
  type        = string
  default     = "test"
  description = "Name of your DB cluster"
}

variable "instance_class" {
  type        = string
  default     = "db.t2.micro"
  description = "Type of storage class"
}

variable "db_storage_type" {
  type        = string
  default     = "io1"
  description = "Type of database storage"
}

# change this based on database engine type
variable "db_storage_throughput" {
  type        = number
  default     = 3000
  description = "The storage throughput value for the DB instance."
}

variable "db_storage" {
  type        = number
  default     = 10
  description = "Allocated storage size in GBs"
}

variable "max_allocated_storage" {
  default     = 100
  type        = number
  description = "When configured, the upper limit to which Amazon RDS can automatically scale the storage of the DB instance."

}

variable "storage_encrypted" {
  type        = bool
  default     = false
  description = "Specifies whether the DB instance is encrypted."
}

variable "engine" {
  type        = string
  default     = "mysql"
  description = "Name of database engine"
}

variable "engine_version" {
  type        = string
  default     = "5.7"
  description = "Database engine version"
}

variable "db_name" {
  type        = string
  default     = "test"
  description = "The name of the database to create when the DB instance is created"
}

variable "db_username" {
  description = "The username for the database"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "RDS root user password"
  type        = string
  sensitive   = true
}

variable "db_port" {
  type        = number
  default     = 5432
  description = "The port on which the DB accepts connections."
}

variable "db_subnet_group_name" {
  type        = string
  default     = "example-db-subnet-group"
  description = "Name of DB subnet group"
}

variable "db_security_groups_ids" {
  description = "List of VPC security group IDs to associate"
  type        = list(string)
  default     = []
}

variable "multi_az" {
  description = "Specifies if the RDS instance is multi-AZ"
  type        = bool
  default     = false
}


variable "publicly_accessible" {
  description = "Bool to control if instance is publicly accessible"
  type        = bool
  default     = false
}


variable "subnet_ids" {
  description = "List of subnet IDs for the RDS instance"
  type        = list(string)
  default     = []
}

variable "apply_immediately" {
  type        = bool
  default     = false
  description = "Specifies whether any database modifications are applied immediately, or during the next maintenance window."
}

# backup
variable "enable_backups" {
  description = "Specifies whether to enable or disable backups"
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "Number of days to keep the backup copies before deleting or overwriting them."
  type        = number
  default     = 7
}

variable "backup_window" {
  description = "Preferred backup window/backup scheduling (hh24:mi-hh24:mi format)"
  type        = string
  default     = "00:00-01:00"
}

variable "preferred_backup_window" {
  description = "Daily time range during which automated backups are created if automated backups are enabled."
  type        = string
  default     = "00:00-01:00"

}

variable "maintenance_window" {
  description = "Preferred maintenance window (ddd:hh24:mi-ddd:hh24:mi format)"
  type        = string
  default     = "sat:00:00-sat:01:00"
}

variable "skip_final_snapshot" {
  type        = bool
  default     = true
  description = "Determines whether a final DB snapshot is created before the DB instance is deleted"
}

# variable "final_snapshot_identifier" {
#   description = "Identifier for the final snapshot"
#   type        = string
#   default     = "final-snapshot"
# }

# Paramater Group
variable "parameter_group_family" {
  description = "The family of the DB parameter group."
  type        = string
}

variable "db_parameters_for_parameter_group" {
  description = "Map of database engine type to to apply to the DB parameter group"
  type = map(list(object({
    name  = string
    value = string
  })))
  default = {}
}

variable "copy_tags_to_snapshot" {
  default     = false
  type        = bool
  description = "Copy all Instance tags to snapshots."
}

# read replica
variable "enable_read_replicas" {
  type        = bool
  description = "Enable read replicas for the database"
  default     = false
}

variable "read_replica_count" {
  type        = number
  description = "Number of read replicas"
  default     = 0
}

variable "read_replica_config" {
  type = list(object({
    instance_class          = string
    storage_encrypted       = bool
    publicly_accessible     = bool
    skip_final_snapshot     = bool
    backup_retention_period = number
  }))
  default = [{
    instance_class          = "db.t3.small"
    storage_encrypted       = false
    publicly_accessible     = false
    skip_final_snapshot     = true
    backup_retention_period = 0
  }]
  description = "The configuration for the DB's read replica."
}



# deletion protection
variable "enable_deletion_protection" {
  default     = false
  type        = bool
  description = "The database can't be deleted when this value is set to true"

}

#monitoring
variable "enable_enhanced_monitoring" {
  default     = false
  type        = bool
  description = "Specify whether to enable enhanced monitoring in database or not."
}

variable "monitoring_interval" {
  default     = 0
  type        = number
  description = "The interval, in seconds, between points when Enhanced Monitoring metrics are collected for the DB instance. Valid Values: 0, 1, 5, 10, 15, 30, 60."
}

# Tags
variable "custom_tags" {
  description = "Custom tags to set on all the resources."
  type        = map(string)
  default     = {}
}
