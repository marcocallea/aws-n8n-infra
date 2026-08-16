output "target_group_arn" {
    value = aws_lb_target_group.n8n.arn
}

output "alb_dns_name" {
    value = aws_lb.main.dns_name
}