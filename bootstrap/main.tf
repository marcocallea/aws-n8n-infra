terraform {
    required_providers {
        aws = {
        source  = "hashicorp/aws"
        version = "6.60.0"
        }
    }

    required_version = ">= 1.10"
}

provider "aws" {
    region = "eu-south-1"
}

resource "aws_s3_bucket" "tfstate" {

    # checkov:skip=CKV_AWS_144:replica cross-region non necessaria: state ricostruibile, ambiente demo mono-regione
    # checkov:skip=CKV_AWS_145:cifratura SSE-S3 (AES256) attiva; CMK dedicata non giustificata per un singolo file di state
    # checkov:skip=CKV_AWS_18:access logging richiederebbe un secondo bucket dedicato, costo>beneficio
    # checkov:skip=CKV2_AWS_62:event notification non previste: nessun consumatore a valle
    # checkov:skip=CKV2_AWS_61:lifecycle non necessaria: versioning attivo su un unico file di piccole dimensioni


    bucket = "marco-callea-tfstate"

}

resource "aws_s3_bucket_public_access_block" "tfmain-pba" {
    bucket = aws_s3_bucket.tfstate.id

    block_public_acls       = true
    block_public_policy     = true
    ignore_public_acls      = true
    restrict_public_buckets = true
}


resource "aws_s3_bucket_versioning" "versioning_enabled" {
    bucket = aws_s3_bucket.tfstate.id
    versioning_configuration {
        status = "Enabled"
    }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "aes256" {
    bucket = aws_s3_bucket.tfstate.id

    rule {
        apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
        }
    }
}

resource "aws_budgets_budget" "max" {
    name         = "budget-mensile"
    budget_type  = "COST"
    limit_amount = "30"
    limit_unit   = "USD"
    time_unit    = "MONTHLY"

    notification {
        comparison_operator        = "GREATER_THAN"
        threshold                  = 33
        threshold_type             = "PERCENTAGE"
        notification_type          = "ACTUAL"
        subscriber_email_addresses = ["callea9marco@outlook.it"]
    }

    notification {
        comparison_operator        = "GREATER_THAN"
        threshold                  = 80
        threshold_type             = "PERCENTAGE"
        notification_type          = "ACTUAL"
        subscriber_email_addresses = ["callea9marco@outlook.it"]
    }

}
