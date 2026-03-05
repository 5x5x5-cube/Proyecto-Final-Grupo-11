variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs"
  type        = list(string)
}

variable "ecs_security_group_id" {
  description = "ECS security group ID"
  type        = string
}

variable "inventory_repository_url" {
  description = "Inventory ECR repository URL"
  type        = string
}

variable "booking_repository_url" {
  description = "Booking ECR repository URL"
  type        = string
}

variable "rds_endpoint" {
  description = "RDS endpoint"
  type        = string
}

variable "db_username" {
  description = "Database username"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "inventory_db_name" {
  description = "Inventory database name"
  type        = string
}

variable "booking_db_name" {
  description = "Booking database name"
  type        = string
}

variable "redis_endpoint" {
  description = "Redis endpoint"
  type        = string
}

variable "inventory_target_group_arn" {
  description = "Inventory target group ARN"
  type        = string
}

variable "booking_target_group_arn" {
  description = "Booking target group ARN"
  type        = string
}

variable "task_cpu" {
  description = "Task CPU units"
  type        = string
  default     = "256"
}

variable "task_memory" {
  description = "Task memory in MB"
  type        = string
  default     = "512"
}

variable "desired_count" {
  description = "Desired number of tasks"
  type        = number
  default     = 2
}

variable "alb_dns_name" {
  description = "ALB DNS name for internal service communication"
  type        = string
}
