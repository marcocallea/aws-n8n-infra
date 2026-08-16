resource "aws_security_group" "alb" {
    name = "alb_sg"
    description = "alb security group"
    vpc_id = var.vpc_id

    tags = {
        Name = "${var.project_name}-alb_sg"
    }
}

resource "aws_security_group" "ecs" {
    name = "ecs_sg"
    description = "ecs security group"
    vpc_id = var.vpc_id

    tags = {
        Name = "${var.project_name}-ecs_sg"
    }
}

resource "aws_security_group" "rds" {
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

    ip_protocol = "tcp"
    from_port = 5432
    to_port = 5432
}