terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

# Networking
module "networking" {
  source = "./modules/networking"
  
  project_name       = var.project_name
  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  enable_nat_gateway = var.enable_nat_gateway
}

# ECR not supported in AWS Academy - using Docker Hub instead

# RDS PostgreSQL
module "rds" {
  source = "./modules/rds"
  
  project_name        = var.project_name
  environment         = var.environment
  vpc_id              = module.networking.vpc_id
  private_subnet_ids  = module.networking.private_subnet_ids
  db_security_group_id = module.networking.db_security_group_id
  db_username         = var.db_username
  db_password         = var.db_password
  inventory_db_name   = var.inventory_db_name
  booking_db_name     = var.booking_db_name
}

# ElastiCache Redis
module "elasticache" {
  source = "./modules/elasticache"
  
  project_name            = var.project_name
  environment             = var.environment
  vpc_id                  = module.networking.vpc_id
  private_subnet_ids      = module.networking.private_subnet_ids
  redis_security_group_id = module.networking.redis_security_group_id
}

# Application Load Balancer
module "alb" {
  source = "./modules/alb"
  
  project_name           = var.project_name
  environment            = var.environment
  vpc_id                 = module.networking.vpc_id
  public_subnet_ids      = module.networking.public_subnet_ids
  alb_security_group_id  = module.networking.alb_security_group_id
}

# ECS Fargate
module "ecs" {
  source = "./modules/ecs"
  
  project_name              = var.project_name
  environment               = var.environment
  vpc_id                    = module.networking.vpc_id
  private_subnet_ids        = module.networking.private_subnet_ids
  ecs_security_group_id     = module.networking.ecs_security_group_id
  
  # Docker Hub images (change to your Docker Hub username)
  inventory_repository_url  = var.docker_hub_username != "" ? "${var.docker_hub_username}/inventory-service" : "inventory-service"
  booking_repository_url    = var.docker_hub_username != "" ? "${var.docker_hub_username}/booking-service" : "booking-service"
  
  # RDS
  rds_endpoint              = module.rds.db_instance_endpoint
  db_username               = var.db_username
  db_password               = var.db_password
  inventory_db_name         = var.inventory_db_name
  booking_db_name           = var.booking_db_name
  
  # Redis
  redis_endpoint            = module.elasticache.redis_endpoint
  
  # ALB
  inventory_target_group_arn = module.alb.inventory_target_group_arn
  booking_target_group_arn   = module.alb.booking_target_group_arn
  
  # Task configuration
  task_cpu                  = var.ecs_task_cpu
  task_memory               = var.ecs_task_memory
  desired_count             = var.desired_count
  
  # ALB DNS for internal communication
  alb_dns_name              = module.alb.alb_dns_name
}
