resource "aws_lb" "main" {
  name               = "${var.project_name}-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = false
  enable_http2              = true

  tags = {
    Name = "${var.project_name}-${var.environment}-alb"
  }
}

# Target Group - Inventory Service
resource "aws_lb_target_group" "inventory" {
  name        = "${var.project_name}-${var.environment}-inv-tg"
  port        = 5001
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = "/api/health"
    matcher             = "200"
  }

  deregistration_delay = 30

  tags = {
    Name = "${var.project_name}-${var.environment}-inventory-tg"
  }
}

# Target Group - Booking Service
resource "aws_lb_target_group" "booking" {
  name        = "${var.project_name}-${var.environment}-book-tg"
  port        = 5002
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = "/api/health"
    matcher             = "200"
  }

  deregistration_delay = 30

  tags = {
    Name = "${var.project_name}-${var.environment}-booking-tg"
  }
}

# Listener - Port 5001 (Inventory)
resource "aws_lb_listener" "inventory" {
  load_balancer_arn = aws_lb.main.arn
  port              = "5001"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.inventory.arn
  }
}

# Listener - Port 5002 (Booking)
resource "aws_lb_listener" "booking" {
  load_balancer_arn = aws_lb.main.arn
  port              = "5002"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.booking.arn
  }
}
