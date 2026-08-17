variable "project_name" {
  description = "Prefisso"
  type        = string
}

variable "private_subnet_ids" {
  description = "id subnet private"
  type        = list(string)
}

variable "security_group_id" {
  description = "id security group"
  type        = string
}

variable "db_endpoint" {
  description = "endpoint db"
  type        = string
}

variable "db_name" {
  description = "name db"
  type        = string
}

variable "db_username" {
  description = "username db"
  type        = string
}

variable "db_password_ssm_arn" {
  description = "arn' ssm pass db"
  type        = string
}

variable "cpu" {
  description = "cpu number"
  type        = number
}

variable "memory" {
  description = "memory number"
  type        = number
}

variable "target_group_arn" {
  description = "target group arn"
  type        = string
}


variable "public_url" {
  description = "URL n8n (CloudFront)"
  type        = string
}
