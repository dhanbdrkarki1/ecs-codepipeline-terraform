locals {
  env_name           = "dev"
  region             = "us-east-2"
  availability_zones = ["us-east-2a", "us-east-2b"]
  project            = "dhan-cicd-pipeline"
  # AWS Account ID
  account_id = "664418970145"
  ecs_ami_id = jsondecode(data.aws_ssm_parameter.ecs_optimized_ami.value)["image_id"]
}
