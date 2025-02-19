# Lunch template Config
resource "aws_launch_template" "this" {
  count       = var.create && var.create_launch_template ? 1 : 0
  name        = var.launch_template_name
  description = var.launch_template_description

  instance_type = var.instance_type
  image_id      = var.image_id
  key_name      = var.key_name
  user_data     = var.user_data != "" ? var.user_data : null

  vpc_security_group_ids = compact(coalesce(var.security_groups, []))
  default_version        = var.default_version
  update_default_version = var.update_default_version

  dynamic "iam_instance_profile" {
    for_each = var.iam_instance_profile != null ? [1] : []
    content {
      name = var.iam_instance_profile
    }
  }

  dynamic "block_device_mappings" {
    for_each = var.block_device_mappings
    content {
      device_name  = block_device_mappings.value.device_name
      no_device    = try(block_device_mappings.value.no_device, null)
      virtual_name = try(block_device_mappings.value.virtual_name, null)

      dynamic "ebs" {
        for_each = flatten([try(block_device_mappings.value.ebs, [])])
        content {
          delete_on_termination = try(ebs.value.delete_on_termination, null)
          volume_size           = try(ebs.value.volume_size, null)
          volume_type           = try(ebs.value.volume_type, null)
          encrypted             = try(ebs.value.encrypted, null)
          iops                  = try(ebs.value.iops, null)
          throughput            = try(ebs.value.throughput, null)
          kms_key_id            = try(ebs.value.kms_key_id, null)
          snapshot_id           = try(ebs.value.snapshot_id, null)
        }
      }
    }
  }

  dynamic "network_interfaces" {
    for_each = var.network_interfaces
    content {
      associate_public_ip_address = try(network_interfaces.value.associate_public_ip_address, null)
      delete_on_termination       = try(network_interfaces.value.delete_on_termination, null)
      description                 = try(network_interfaces.value.description, null)
      device_index                = try(network_interfaces.value.device_index, null)
      security_groups             = compact(concat(try(network_interfaces.value.security_groups, []), var.security_groups))
      subnet_id                   = try(network_interfaces.value.subnet_id, null)
    }
  }

  lifecycle {
    create_before_destroy = true // create new resources before destroy during update
  }

  tags = merge({
    Name = var.launch_template_name
    },

    var.custom_tags
  )
}
