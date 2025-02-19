data "aws_lb" "existing_lb" {
  count = var.use_existing_load_balancer ? 1 : 0
  arn   = var.existing_lb_arn
}
