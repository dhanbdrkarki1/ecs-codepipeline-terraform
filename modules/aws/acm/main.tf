locals {
  name_prefix = "${var.custom_tags["Project"] != "" ? var.custom_tags["Project"] : "default-project"}-${var.custom_tags["Environment"] != "" ? var.custom_tags["Environment"] : "default-env"}"
}


# requesting Amazon-issued certificate from ACM
resource "aws_acm_certificate" "cert" {
  count = var.create ? 1 : 0
  # provider = aws.acm_default_region
  domain_name               = var.domain_name
  subject_alternative_names = try(var.alternative_names_to_domain, null)
  validation_method         = var.acm_validation_method

  lifecycle {
    create_before_destroy = true
  }
  tags = merge(
    { "Name" = "${local.name_prefix}" },
    var.custom_tags
  )
}
