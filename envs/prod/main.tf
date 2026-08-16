module "network" {
    source       = "../../modules/network"
    project_name = "aws-n8n-infra"
    vpc_cidr     = "10.0.0.0/16"
    az_count     = 2
}

module "security" {
    source       = "../../modules/security"
    project_name = "aws-n8n-infra"
    vpc_id       = module.network.vpc_id
}

module "rds" {
    source             = "../../modules/rds"
    project_name       = "aws-n8n-infra"
    private_subnet_ids = module.network.private_subnet_ids
    security_group_id  = module.security.rds_sg_id
    db_name            = "n8n"
    db_username        = "n8n"
}

module "ecs-n8n" {
    source              = "../../modules/ecs-n8n"
    project_name        = "aws-n8n-infra"
    private_subnet_ids  = module.network.private_subnet_ids
    security_group_id   = module.security.ecs_sg_id
    db_endpoint         = module.rds.db_endpoint
    db_name             = module.rds.db_name
    db_username         = module.rds.db_username
    db_password_ssm_arn = module.rds.db_password_ssm_arn
    cpu                 = 512
    memory              = 1024
    target_group_arn = module.alb.target_group_arn 
    depends_on = [module.alb]
}

module "alb" {
    source            = "../../modules/alb"
    project_name      = "aws-n8n-infra"
    vpc_id            = module.network.vpc_id
    public_subnet_ids = module.network.public_subnet_ids
    security_group_id = module.security.alb_sg_id
}