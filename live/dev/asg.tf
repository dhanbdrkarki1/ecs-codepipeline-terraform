#================================
# EC2 Auto Scaling
#================================
module "asg" {
  source = "../../modules/aws/asg"
  create = true
  name   = var.project_name

  # Auto Scaling
  min_size                  = 2
  desired_capacity          = 2
  max_size                  = 4
  vpc_zone_identifier       = module.vpc.public_subnet_ids
  health_check_type         = "ELB"
  health_check_grace_period = 300
  # If Load Balanacer Target type is "ip" and ECS service is used, target group arn is defined in ECS Service Definition. 
  # If Load Balanacer Target type is "instance", then provide the target_group_arns here.
  # target_group_arns         = module.alb.target_group_arns

  # Launch Template
  create_launch_template      = true
  launch_template_name        = "${var.project_name}-${var.environment}-lt"
  launch_template_description = "Launch Template for ${var.project_name}"
  user_data = base64encode(<<-EOF
    #!/bin/bash
    echo ECS_CLUSTER=${module.ecs.ecs_cluster_name} >> /etc/ecs/ecs.config
  EOF
  )
  update_default_version = true
  image_id               = local.ecs_ami_id
  key_name               = "dhan-demo"
  instance_type          = "t3.small"
  # Remove security_groups from root level
  # security_groups      = [module.ecs_sg.security_group_id]
  network_interfaces = [{
    associate_public_ip_address = true
    security_groups             = [module.ecs_sg.security_group_id]
    delete_on_termination       = true
    device_index                = 0
  }]
  iam_instance_profile = module.instance_profile.instance_profile_name # disable if you don't want to use it


  # Required for  managed_termination_protection = "ENABLED" in ECS
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
      target_value              = 100000000 # 100 MB in bytes
      estimated_instance_warmup = 300
    }
  }

  # Feature to automate rolling updates for an ASG
  instance_refresh = {
    strategy = "Rolling" # Strategy to use for instance refresh
    preferences = {
      checkpoint_delay             = 600           # seconds to wait after a checkpoint
      checkpoint_percentages       = [35, 70, 100] # List of percentages for each checkpoint. To replace all instances, the final number must be 100
      instance_warmup              = 300           # Number of seconds until a newly launched instance is configured and ready to use.
      min_healthy_percentage       = 50
      max_healthy_percentage       = 100
      auto_rollback                = true        #  Automatically rollback if instance refresh fails
      scale_in_protected_instances = "Refresh"   # Behavior when encountering instances protected from scale in are found
      standby_instances            = "Terminate" # Behavior when encountering instances in the Standby state in are found
      skip_matching                = false       # Replace instances that already have your desired configuration
    }
    triggers = [] # List of triggers to use for instance refresh. Default: Launch Template
  }

  block_device_mappings = [
    {
      # Root volume
      device_name = "/dev/xvda"
      no_device   = 0
      ebs = {
        delete_on_termination = true
        encrypted             = true
        volume_size           = 30
        volume_type           = "gp3"
      }
    },
    # {
    #   device_name = "/dev/sda1"
    #   no_device   = 1
    #   ebs = {
    #     delete_on_termination = true
    #     encrypted             = true
    #     volume_size           = 30
    #     volume_type           = "gp3"
    #   }
    # }
  ]
  custom_tags = {
    Environment      = var.environment
    Project          = var.project_name
    AmazonECSManaged = true # Important for ECS to recognize the instance
  }
}
