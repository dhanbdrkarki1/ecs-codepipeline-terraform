locals {
  # AWS Account ID
  account_id = "664418970145"
  ecs_ami_id = jsondecode(data.aws_ssm_parameter.ecs_optimized_ami.value)["image_id"]

  # ASG Services
  asg_services = {
    "nginx" = {
      name             = "nginx"
      instance_type    = "t3.small"
      min_size         = 2
      desired_capacity = 2
      max_size         = 4
      volume_size      = 30
    },
    "rep_dashboard" = {
      name             = "rep-dashboard"
      instance_type    = "t3.medium"
      min_size         = 1
      desired_capacity = 1
      max_size         = 3
      volume_size      = 50
    }
  }
}
