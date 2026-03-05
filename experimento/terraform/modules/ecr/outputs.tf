output "inventory_repository_url" {
  description = "Inventory service ECR repository URL"
  value       = aws_ecr_repository.inventory.repository_url
}

output "booking_repository_url" {
  description = "Booking service ECR repository URL"
  value       = aws_ecr_repository.booking.repository_url
}

output "inventory_repository_name" {
  description = "Inventory service ECR repository name"
  value       = aws_ecr_repository.inventory.name
}

output "booking_repository_name" {
  description = "Booking service ECR repository name"
  value       = aws_ecr_repository.booking.name
}
