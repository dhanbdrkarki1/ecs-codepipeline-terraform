#================================
# Amazon ACM
#================================
module "acm" {
  source                = "../../modules/aws/acm"
  create                = true
  domain_name           = "karkidhan.com.np"
  acm_validation_method = "DNS"
  subject_alternative_names = [
    "*.karkidhan.com.np",
  ]
  custom_tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}
