#================================
# EC2 Auto Scaling
#================================
module "asg" {
  source                    = "../../modules/services/asg"
  create                    = true
  name                      = var.project_name
  min_size                  = 2
  desired_capacity          = 2
  max_size                  = 4
  vpc_zone_identifier       = module.vpc.private_subnet_ids
  health_check_type         = "ELB"
  health_check_grace_period = 300
  target_group_arns         = module.alb.target_group_arns

  # Launch Template
  create_launch_template      = true
  launch_template_name        = "${var.project_name}-${var.environment}-lt"
  launch_template_description = "Launch Template for ${var.project_name}"
  # comment if no need
  # user_data              = base64encode(file("${path.root}/user-data/install-awscli.sh"))

  update_default_version = true
  image_id               = "ami-09ad6bca8b1dfb96b"
  key_name               = "dhan"
  instance_type          = "t2.micro"
  security_groups        = [module.web_sg.security_group_id]
  iam_instance_profile   = module.ec2_instance_profile.instance_profile_name # disable if you don't want to use it

  # Scaling Policy
  create_auto_scaling_policy = true
  auto_scaling_policies = {
    "cpu-policy" = {
      policy_type               = "TargetTrackingScaling"
      metric_type               = "ASGAverageCPUUtilization"
      target_value              = 70
      estimated_instance_warmup = 300
    }
    "network-in-policy" = {
      policy_type               = "TargetTrackingScaling"
      metric_type               = "ASGAverageNetworkIn"
      target_value              = 10000000 # 10 MB in bytes
      estimated_instance_warmup = 300
    }
    # "request-count-policy" = {
    #   policy_type               = "TargetTrackingScaling"
    #   metric_type               = "ALBRequestCountPerTarget"
    #   target_value              = 1000
    #   estimated_instance_warmup = 300
    #   resource_label            = "app/${module.alb.alb_name}/${module.alb.alb_arn_suffix}/targetgroup/${module.alb.target_group_name}/${module.alb.target_group_arn_suffix}"
    # }
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

  # block_device_mappings = [
  #   {
  #     # Root volume
  #     device_name = "/dev/xvda"
  #     no_device   = 0
  #     ebs = {
  #       delete_on_termination = true
  #       encrypted             = true
  #       volume_size           = 20
  #       volume_type           = "gp2"
  #     }
  #     }, {
  #     device_name = "/dev/sda1"
  #     no_device   = 1
  #     ebs = {
  #       delete_on_termination = true
  #       encrypted             = true
  #       volume_size           = 30
  #       volume_type           = "gp2"
  #     }
  #   }
  # ]
  custom_tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}
