resource "aws_lb" "main" {

  # checkov:skip=CKV_AWS_150:ambiente demo, apply/destroy quotidiano
  # checkov:skip=CKV_AWS_91:access log richiedono bucket S3 dedicato, costo>beneficio in demo
  # checkov:skip=CKV2_AWS_28:WAF fuori scope (costo); in roadmap v2
  # checkov:skip=CKV2_AWS_20:TLS termina su CloudFront; ALB raggiungibile solo da prefix list CloudFront


  name                       = "${var.project_name}-alb"
  load_balancer_type         = "application"
  internal                   = false
  subnets                    = var.public_subnet_ids
  security_groups            = [var.security_group_id]
  drop_invalid_header_fields = true

  tags = {
    Name = "${var.project_name}-alb"
  }
}

resource "aws_lb_target_group" "n8n" {

  # checkov:skip=CKV_AWS_378:traffico ALB->ECS interno alla VPC in subnet privata; TLS termina su CloudFront

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

  # checkov:skip=CKV_AWS_2:TLS termina su CloudFront; ALB accetta solo traffico dalla prefix list CloudFront
  # checkov:skip=CKV_AWS_103:il listener non espone TLS: la negoziazione avviene su CloudFront

  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.n8n.arn
  }
}