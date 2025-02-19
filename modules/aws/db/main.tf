locals {
  name_prefix               = "${var.custom_tags["Project"] != "" ? var.custom_tags["Project"] : "default-project"}-${var.custom_tags["Environment"] != "" ? var.custom_tags["Environment"] : "default-env"}-${var.identifier_prefix != "" ? var.identifier_prefix : "default-name"}"
  monitoring_role_arn       = var.enable_enhanced_monitoring ? try(aws_iam_role.rds_enhanced_monitoring[0].arn, null) : null
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${local.name_prefix}"
  create                    = var.create ? 1 : 0
}

resource "aws_db_subnet_group" "db_subnet_group" {
  count      = var.create ? 1 : 0
  name       = "${local.name_prefix}-db-subnet-group"
  subnet_ids = var.subnet_ids
  tags = merge(
    { "Name" = "${local.name_prefix}" },
    var.custom_tags
  )
}

# Use a custom parameter group since default ones can't be modified and changes require a reboot.
resource "aws_db_parameter_group" "this" {
  count  = var.create ? 1 : 0
  name   = local.name_prefix
  family = var.parameter_group_family

  dynamic "parameter" {
    for_each = lookup(var.db_parameters_for_parameter_group, var.engine, [])
    content {
      name  = parameter.value.name
      value = parameter.value.value
    }
  }

  # true for prod.
  lifecycle {
    create_before_destroy = false
  }
  tags = merge(
    { "Name" = "${local.name_prefix}" },
    var.custom_tags
  )
}

# Database Instance
resource "aws_db_instance" "db" {
  count                  = var.create ? 1 : 0
  identifier             = local.name_prefix
  instance_class         = var.instance_class
  allocated_storage      = var.db_storage
  max_allocated_storage  = var.max_allocated_storage
  engine                 = var.engine
  engine_version         = var.engine_version
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  port                   = var.db_port
  parameter_group_name   = aws_db_parameter_group.this[0].name
  multi_az               = var.multi_az
  storage_encrypted      = var.storage_encrypted
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group[0].name
  vpc_security_group_ids = var.db_security_groups_ids
  publicly_accessible    = var.publicly_accessible
  depends_on             = [aws_db_subnet_group.db_subnet_group]
  apply_immediately      = var.apply_immediately # set to true to make the changes take effect immediately

  # Enable automated backups
  backup_retention_period   = var.enable_backups ? var.backup_retention_period : 0
  backup_window             = var.enable_backups ? var.backup_window : null
  maintenance_window        = var.maintenance_window
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = local.final_snapshot_identifier

  copy_tags_to_snapshot = var.copy_tags_to_snapshot

  #monitoring
  monitoring_interval = var.monitoring_interval
  monitoring_role_arn = local.monitoring_role_arn


  # performance_insights_enabled          = true
  # performance_insights_retention_period = 7
  # create_monitoring_role                = true

  # prevent from deletion
  deletion_protection = var.enable_deletion_protection
  lifecycle {
    prevent_destroy = false
  }

  timeouts {
    create = "40m"
    delete = "40m"
    update = "40m"
  }

  tags = merge(
    { "Name" = "${local.name_prefix}" },
    var.custom_tags
  )
}



resource "aws_db_instance" "read_replica" {
  count             = var.create && var.enable_read_replicas ? var.read_replica_count : 0
  identifier_prefix = "${local.name_prefix}-read-replica-${0}"
  instance_class    = var.read_replica_config[0].instance_class
  engine            = var.engine
  engine_version    = var.engine_version

  # for replication
  replicate_source_db = aws_db_instance.db[0].identifier

  parameter_group_name   = aws_db_parameter_group.this[0].name
  multi_az               = var.multi_az
  storage_encrypted      = var.read_replica_config[0].storage_encrypted
  vpc_security_group_ids = var.db_security_groups_ids
  publicly_accessible    = var.read_replica_config[0].publicly_accessible
  skip_final_snapshot    = var.read_replica_config[0].skip_final_snapshot

  # disable backups to create DB faster
  backup_retention_period = var.read_replica_config[0].backup_retention_period

  tags = merge(
    { "Name" = "${local.name_prefix}-read-replica-${count.index}" },
    var.custom_tags
  )
}
