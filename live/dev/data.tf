data "aws_region" "current" {}
# data "aws_partition" "current" {}
# data "aws_caller_identity" "current" {}

data "aws_ssm_parameter" "ecs_optimized_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended"
}

# # Fetch the default VPC
# data "aws_vpc" "default" {
#   default = true
# }

# # Fetch the default subnets
# data "aws_subnets" "default" {
#   filter {
#     name   = "vpc-id"
#     values = [data.aws_vpc.default.id]
#   }
# }
