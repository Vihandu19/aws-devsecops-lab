output "alb_dns_name" {
  value = module.alb.alb_dns_name
}

output "web_acl_arn" {
  value = module.waf.web_acl_arn
}

output "alb_log_bucket" {
  value = module.logging.alb_log_bucket
}