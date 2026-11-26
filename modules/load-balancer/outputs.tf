output "url" {
  value = "http://${aws_lb.web.dns_name}"
}
output "target_arn" {
  value = aws_lb_target_group.web.arn
}
