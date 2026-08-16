variable "project_name"{
    description = "Prefisso"
    type = string
} 

variable "vpc_id"{
    description = "vpc id"
    type = string
} 

variable "public_subnet_ids"{
    description = "id subnet public"
    type = list(string)
} 

variable "security_group_id"{
    description = "id security group"
    type = string
} 