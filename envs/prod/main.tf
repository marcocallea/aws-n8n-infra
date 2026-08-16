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