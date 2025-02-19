
locals {
  name_prefix    = "${var.custom_tags["Project"] != "" ? var.custom_tags["Project"] : "default-project"}-${var.custom_tags["Environment"] != "" ? var.custom_tags["Environment"] : "default-env"}-${var.name != "" ? var.name : "default-name"}-cluster"
  log_group_name = "ecs/${local.name_prefix}"

  fargate_cpu    = var.app_cpu
  fargate_memory = var.app_memory

  # for efs volume
  source_volume_name = var.mount_efs_volume ? "${var.name != "" ? var.name : "default-name"}-efs-volume" : null
  mount_points = var.mount_efs_volume ? jsonencode([{
    "sourceVolume"  = local.source_volume_name,
    "containerPath" = var.container_path
    "readOnly"      = var.read_only
  }]) : jsonencode([])
}
