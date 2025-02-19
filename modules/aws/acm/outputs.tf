output "certificate_arn" {
  value = try(aws_acm_certificate.cert[0].arn, null)
}

output "acm_validation_record" {
  value = try([for option in aws_acm_certificate.cert[0].domain_validation_options : option], null)
}
