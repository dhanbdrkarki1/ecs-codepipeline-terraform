
locals {
  name_prefix = "${var.custom_tags["Project"] != "" ? var.custom_tags["Project"] : "default-project"}-${var.custom_tags["Environment"] != "" ? var.custom_tags["Environment"] : "default-env"}-${var.name != "" ? var.name : "default-name"}"

  # for efs volume
  source_volume_name = var.mount_efs_volume ? "${var.name != "" ? var.name : "default-name"}-efs-volume" : null
  mount_points = var.mount_efs_volume ? jsonencode([{
    "sourceVolume"  = local.source_volume_name,
    "containerPath" = var.container_path
    "readOnly"      = var.read_only
  }]) : jsonencode([])

  ecs_capacity_provider_names = [for k, v in aws_ecs_capacity_provider.this : v.name]

  account_id = data.aws_caller_identity.current.account_id
  partition  = data.aws_partition.current.partition
  region     = data.aws_region.current.name
}
