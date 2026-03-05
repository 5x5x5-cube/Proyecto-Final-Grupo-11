variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "booking-experiment"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "dbadmin"
  sensitive   = true
}

variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
}

variable "inventory_db_name" {
  description = "Inventory database name"
  type        = string
  default     = "inventory_db"
}

variable "booking_db_name" {
  description = "Booking database name"
  type        = string
  default     = "booking_db"
}

variable "ecs_task_cpu" {
  description = "ECS task CPU units"
  type        = string
  default     = "256"
}

variable "ecs_task_memory" {
  description = "ECS task memory in MB"
  type        = string
  default     = "512"
}

variable "desired_count" {
  description = "Desired number of ECS tasks"
  type        = number
  default     = 2
}

variable "docker_hub_username" {
  description = "Docker Hub username for container images (leave empty for local images)"
  type        = string
  default     = ""
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway (costs money)"
  type        = bool
  default     = true
}
