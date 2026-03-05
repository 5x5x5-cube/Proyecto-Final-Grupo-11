output "cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.main.name
}

output "cluster_arn" {
  description = "ECS cluster ARN"
  value       = aws_ecs_cluster.main.arn
}

output "inventory_service_name" {
  description = "Inventory service name"
  value       = aws_ecs_service.inventory.name
}

output "booking_service_name" {
  description = "Booking service name"
  value       = aws_ecs_service.booking.name
}
