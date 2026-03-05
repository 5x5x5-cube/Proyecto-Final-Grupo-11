output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.alb.alb_dns_name
}

output "alb_url" {
  description = "URL to access the booking service"
  value       = "http://${module.alb.alb_dns_name}"
}

output "inventory_service_url" {
  description = "Internal URL for inventory service"
  value       = "http://${module.alb.alb_dns_name}:5001"
}

output "booking_service_url" {
  description = "Public URL for booking service"
  value       = "http://${module.alb.alb_dns_name}:5002"
}

output "rds_endpoint" {
  description = "RDS PostgreSQL endpoint"
  value       = module.rds.db_instance_endpoint
  sensitive   = true
}

output "redis_endpoint" {
  description = "ElastiCache Redis endpoint"
  value       = module.elasticache.redis_endpoint
  sensitive   = true
}

# ECR not supported in AWS Academy

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = module.ecs.cluster_name
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.networking.vpc_id
}
