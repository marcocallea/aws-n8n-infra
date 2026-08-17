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

    # checkov:skip=CKV_AWS_337:SecureString con chiave gestita da AWS; CMK dedicata non giustificata in demo

    name = "/n8n/db/password"
    type = "SecureString"
    value = random_password.db.result
}

resource "aws_db_instance" "main" {

    # checkov:skip=CKV_AWS_293:deletion protection disattivata di proposito: ciclo apply/destroy quotidiano
    # checkov:skip=CKV_AWS_157:single-AZ per costo; Multi-AZ raddoppierebbe la spesa dell'istanza
    # checkov:skip=CKV_AWS_161:n8n non supporta l'autenticazione IAM verso Postgres; credenziali in SSM SecureString
    # checkov:skip=CKV_AWS_353:Performance Insights ha costo aggiuntivo, fuori scope in demo
    # checkov:skip=CKV_AWS_118:enhanced monitoring ha costo per istanza, fuori scope in demo
    # checkov:skip=CKV_AWS_129:export dei log RDS su CloudWatch fuori scope per costo
    # checkov:skip=CKV2_AWS_30:query logging non abilitato: costo di storage e nessun requisito di audit in demo

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
    copy_tags_to_snapshot = true
    auto_minor_version_upgrade = true

    tags = {
        Name = "${var.project_name}-db_inst"
    }
}