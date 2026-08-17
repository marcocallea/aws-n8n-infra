resource "aws_ecs_cluster" "ecs_cluster" {

  # checkov:skip=CKV_AWS_65:Container Insights ha un costo per metrica; log applicativi su CloudWatch sufficienti in demo

  name = "${var.project_name}-ecs-cluster"

  tags = {
    Name = "${var.project_name}-ecs-cluster"
  }
}

resource "aws_cloudwatch_log_group" "n8n" {

  # checkov:skip=CKV_AWS_338:retention 7 giorni scelta di costo per ambiente demo
  # checkov:skip=CKV_AWS_158:log cifrati con chiave gestita da AWS; una CMK dedicata avrebbe costo ricorrente

  name              = "/ecs/${var.project_name}"
  retention_in_days = 7
}

resource "random_password" "n8n_key" {
  length  = 32
  special = false
}

resource "aws_ssm_parameter" "n8n_encryption_key" {

  # checkov:skip=CKV_AWS_337:SecureString con chiave gestita da AWS; CMK dedicata ~1$/mese non giustificata in demo

  name  = "/n8n/encryption-key"
  type  = "SecureString"
  value = random_password.n8n_key.result
}

resource "aws_iam_role" "execution" {
  name = "${var.project_name}-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "execution_managed" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "execution_ssm" {
  name = "${var.project_name}-ssm-read"
  role = aws_iam_role.execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = ["ssm:GetParameters"]
      Resource = [
        var.db_password_ssm_arn,
        aws_ssm_parameter.n8n_encryption_key.arn
      ]
    }]
  })
}

resource "aws_ecs_task_definition" "n8n" {

  # checkov:skip=CKV_AWS_336:n8n scrive dati applicativi in /home/node/.n8n; filesystem read-only romperebbe il container

  family                   = "${var.project_name}-n8n"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = aws_iam_role.execution.arn

  container_definitions = jsonencode([
    {
      name      = "n8n"
      image     = "docker.n8n.io/n8nio/n8n"
      essential = true

      portMappings = [
        { containerPort = 5678, protocol = "tcp" }
      ]

      environment = [
        { name = "DB_TYPE", value = "postgresdb" },
        { name = "DB_POSTGRESDB_HOST", value = var.db_endpoint },
        { name = "DB_POSTGRESDB_DATABASE", value = var.db_name },
        { name = "DB_POSTGRESDB_USER", value = var.db_username },
        { name = "GENERIC_TIMEZONE", value = "Europe/Rome" },
        { name = "DB_POSTGRESDB_SSL_ENABLED", value = "true" },
        { name = "DB_POSTGRESDB_SSL_REJECT_UNAUTHORIZED", value = "false" },
        { name = "N8N_HOST", value = replace(replace(var.public_url, "https://", ""), "/", "") },
        { name = "N8N_PROTOCOL", value = "https" },
        { name = "WEBHOOK_URL", value = var.public_url },
        { name = "N8N_PROXY_HOPS", value = "1" },
        { name = "N8N_SECURE_COOKIE", value = "true" }
      ]

      secrets = [
        { name = "DB_POSTGRESDB_PASSWORD", valueFrom = var.db_password_ssm_arn },
        { name = "N8N_ENCRYPTION_KEY", valueFrom = aws_ssm_parameter.n8n_encryption_key.arn }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.n8n.name
          "awslogs-region"        = "eu-south-1"
          "awslogs-stream-prefix" = "n8n"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "n8n" {
  name            = "${var.project_name}-n8n"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.n8n.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = "n8n"
    container_port   = 5678
  }

  health_check_grace_period_seconds = 180

}