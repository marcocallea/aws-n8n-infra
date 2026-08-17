variable "project_name" {
  description = "Prefisso"
  type        = string
}

variable "private_subnet_ids" {
  description = "lista id subnet private"
  type        = list(string)
}

variable "security_group_id" {
  description = "id sg"
  type        = string
}

variable "db_name" {
  description = "db name"
  type        = string
}

variable "db_username" {
  description = "db username"
  type        = string
}