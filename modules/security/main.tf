resource "aws_security_group" "alb" {

    # checkov:skip=CKV2_AWS_5:falso positivo; checkov non risolve i riferimenti cross-module

    name = "alb_sg"
    description = "alb security group"
    vpc_id = var.vpc_id

    tags = {
        Name = "${var.project_name}-alb_sg"
    }
}

resource "aws_security_group" "ecs" {

    # checkov:skip=CKV2_AWS_5:falso positivo; checkov non risolve i riferimenti cross-module

    name = "ecs_sg"
    description = "ecs security group"
    vpc_id = var.vpc_id

    tags = {
        Name = "${var.project_name}-ecs_sg"
    }
}

resource "aws_security_group" "rds" {

    # checkov:skip=CKV2_AWS_5:falso positivo; checkov non risolve i riferimenti cross-module

    name = "rds_sg"
    description = "rds security group"
    vpc_id = var.vpc_id

    tags = {
        Name = "${var.project_name}-rds_sg"
    }
}

resource "aws_vpc_security_group_ingress_rule" "db_ir" {
    referenced_security_group_id = aws_security_group.ecs.id
    security_group_id = aws_security_group.rds.id
    description = "Postgres dal security group di ECS"

    ip_protocol = "tcp"
    from_port = 5432
    to_port = 5432
}

resource "aws_vpc_security_group_ingress_rule" "ecs_from_alb" {
    security_group_id = aws_security_group.ecs.id
    referenced_security_group_id = aws_security_group.alb.id
    description = "ECS dal security group dell'ALB"

    ip_protocol = "tcp"
    from_port = 5678
    to_port = 5678
}

resource "aws_vpc_security_group_egress_rule" "ecs_all" {
    security_group_id = aws_security_group.ecs.id
    description = "Egress ECS"

    cidr_ipv4         = "0.0.0.0/0"
    ip_protocol       = "-1"
}

data "aws_ec2_managed_prefix_list" "cloudfront" {
    name = "com.amazonaws.global.cloudfront.origin-facing"
}

resource "aws_vpc_security_group_ingress_rule" "alb_from_cloudfront" {

    # checkov:skip=CKV_AWS_260:falso positivo - la regola usa prefix_list_id (CloudFront origin-facing), non 0.0.0.0/0

    security_group_id = aws_security_group.alb.id
    prefix_list_id    = data.aws_ec2_managed_prefix_list.cloudfront.id
    description = "ALB dal security group di Cloudfront"

    ip_protocol       = "tcp"
    from_port         = 80
    to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "alb_to_ecs" {
    security_group_id            = aws_security_group.alb.id
    referenced_security_group_id = aws_security_group.ecs.id
    description = "ECS dal security group dell'ALB"

    ip_protocol                  = "tcp"
    from_port                    = 5678
    to_port                      = 5678
}