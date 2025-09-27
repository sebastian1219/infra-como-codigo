output "alb_dns_name" {
  description = "DNS name of the ALB"
  value       = aws_lb.cheese_alb.dns_name
}

output "instance_ids" {
  description = "IDs of EC2 instances"
  value       = aws_instance.cheese[*].id
}
