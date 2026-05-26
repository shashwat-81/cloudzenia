output "nginx_access_log_group" {
  description = "CloudWatch Logs group for NGINX access logs"
  value       = module.ec2_cloudwatch.nginx_access_log_group
}

output "ssm_document_name" {
  description = "SSM document used to install the CloudWatch agent"
  value       = module.ec2_cloudwatch.ssm_document_name
}

output "verification" {
  description = "How to verify Challenge 3 in the AWS Console"
  value = {
    ram_metrics = "CloudWatch > Metrics > CWAgent > mem_used_percent (per InstanceId)"
    nginx_logs  = "CloudWatch > Log groups > ${module.ec2_cloudwatch.nginx_access_log_group}"
    note        = "Allow 5–10 minutes after apply for SSM to finish on both instances"
  }
}
