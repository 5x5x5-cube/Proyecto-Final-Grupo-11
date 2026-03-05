output "alb_dns_name" {
  description = "ALB DNS name"
  value       = aws_lb.main.dns_name
}

output "alb_arn" {
  description = "ALB ARN"
  value       = aws_lb.main.arn
}

output "inventory_target_group_arn" {
  description = "Inventory target group ARN"
  value       = aws_lb_target_group.inventory.arn
}

output "booking_target_group_arn" {
  description = "Booking target group ARN"
  value       = aws_lb_target_group.booking.arn
}
