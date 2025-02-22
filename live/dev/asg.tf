# #================================
# # EC2 Auto Scaling
# #================================
module "asgs" {
  source   = "../../modules/aws/asg"
  for_each = local.asg_services

  create = true
  name   = "${var.project_name}-${each.value.name}"

  # Auto Scaling
  min_size                  = each.value.min_size
  desired_capacity          = each.value.desired_capacity
  max_size                  = each.value.max_size
  vpc_zone_identifier       = module.vpc.public_subnet_ids
  health_check_type         = "ELB"
  health_check_grace_period = 300

  # Launch Template
  create_launch_template      = true
  launch_template_name        = "${var.project_name}-${each.value.name}-${var.environment}-lt"
  launch_template_description = "Launch Template for ${var.project_name}-${each.value.name}"
  user_data = base64encode(<<-EOF
    #!/bin/bash
    echo ECS_CLUSTER=${module.ecs_cluster.cluster_name} >> /etc/ecs/ecs.config
    echo ECS_ENABLE_TASK_IAM_ROLE=true >> /etc/ecs/ecs.config
    echo ECS_LOGLEVEL=debug >> /etc/ecs/ecs.config
  EOF
  )
  # add it in user_data
  # echo ECS_CONTAINER_INSTANCE_TAGS={"Service":"${each.value.name}"} >> /etc/ecs/ecs.config
  update_default_version = true
  image_id               = local.ecs_ami_id
  key_name               = "dhan-demo"
  instance_type          = each.value.instance_type

  network_interfaces = [{
    associate_public_ip_address = true
    security_groups             = [module.ecs_sg.security_group_id]
    delete_on_termination       = true
    device_index                = 0
  }]

  iam_instance_profile = module.instance_profile.instance_profile_name

  block_device_mappings = [
    {
      device_name = "/dev/xvda"
      no_device   = 0
      ebs = {
        delete_on_termination = true
        encrypted             = true
        volume_size           = each.value.volume_size
        volume_type           = "gp3"
      }
    }
  ]

  protect_from_scale_in = false

  # Scaling Policy
  create_auto_scaling_policy = false
  auto_scaling_policies = {
    "cpu-policy" = {
      policy_type               = "TargetTrackingScaling"
      metric_type               = "ASGAverageCPUUtilization"
      target_value              = 85
      estimated_instance_warmup = 300
    }
    "network-in-policy" = {
      policy_type               = "TargetTrackingScaling"
      metric_type               = "ASGAverageNetworkIn"
      target_value              = 100000000
      estimated_instance_warmup = 300
    }
  }

  # Instance refresh
  instance_refresh = {
    strategy = "Rolling"
    preferences = {
      checkpoint_delay             = 600
      checkpoint_percentages       = [35, 70, 100]
      instance_warmup              = 300
      min_healthy_percentage       = 50
      max_healthy_percentage       = 100
      auto_rollback                = true
      scale_in_protected_instances = "Refresh"
      standby_instances            = "Terminate"
      skip_matching                = false
    }
    triggers = []
  }

  custom_tags = {
    Environment      = var.environment
    Project          = var.project_name
    Service          = each.value.name
    AmazonECSManaged = true
  }
}
