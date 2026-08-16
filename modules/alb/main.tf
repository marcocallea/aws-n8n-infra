resource "aws_lb" "main" {
    name               = "${var.project_name}-alb"
    load_balancer_type = "application"
    internal           = false
    subnets            = var.public_subnet_ids
    security_groups    = [var.security_group_id]

    tags = {
        Name = "${var.project_name}-alb"
    }
}

resource "aws_lb_target_group" "n8n" {
    name        = "${var.project_name}-tg"
    port        = 5678
    protocol    = "HTTP"
    vpc_id      = var.vpc_id
    target_type = "ip"

    health_check {
        path                = "/healthz"
        matcher             = "200"
        interval            = 30
        timeout             = 5
        healthy_threshold   = 2
        unhealthy_threshold = 3
    }
}

resource "aws_lb_listener" "http" {
    load_balancer_arn = aws_lb.main.arn
    port              = 80
    protocol          = "HTTP"

    default_action {
        type             = "forward"
        target_group_arn = aws_lb_target_group.n8n.arn
    }
}