resource "aws_db_subnet_group" "db" {
    subnet_ids = var.private_subnet_ids

    name = "${var.project_name}-db-subnet-group"

    tags = {
        Name = "${var.project_name}-db_sg"
    }
}

resource "random_password" "db" {
    length = 32
    special = false
}

resource "aws_ssm_parameter" "db_password" {
    name = "/n8n/db/password"
    type = "SecureString"
    value = random_password.db.result
}

resource "aws_db_instance" "main" {
    engine = "postgres"
    engine_version = "16"
    instance_class = "db.t4g.micro"
    allocated_storage = 20
    storage_type = "gp3" 
    storage_encrypted = true
    db_name = var.db_name
    username = var.db_username 
    password = random_password.db.result 
    vpc_security_group_ids = [var.security_group_id] 
    publicly_accessible = false 
    multi_az = false 
    backup_retention_period = 1
    skip_final_snapshot = true  
    deletion_protection = false
    db_subnet_group_name = aws_db_subnet_group.db.name
    identifier = "${var.project_name}-db"

    tags = {
        Name = "${var.project_name}-db_inst"
    }
}