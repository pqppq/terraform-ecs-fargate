variable "region" {
	type = string
	default = "ap-northeast-1"
}

variable "remote_state_bucket" {
	type = string
}

variable "remote_state_key" {
	type = string
}

variable "ecs_cluster_name" {
	type = string
}

variable "internet_cidr_blocks" {
	type = string
}

variable "ecs_domain_name" {
	type = string
}
