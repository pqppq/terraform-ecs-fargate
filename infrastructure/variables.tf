variable "region" {
  type        = string
  default     = "ap-northeast-1"
  description = "AWS Region"
}

variable "vpc_cidr" {
  type        = string
  default     = "10.0.0.0/16"
  description = "VPC CIDR Block"
}

variable "public_subnet_1_cidr" {
  type        = string
  description = "Public Subnet 1 CIDR"
}

variable "public_subnet_2_cidr" {
  type        = string
  description = "Public Subnet 2 CIDR"
}

variable "public_subnet_3_cidr" {
  type        = string
  description = "Public Subnet 3 CIDR"
}

variable "private_subnet_1_cidr" {
  type        = string
  description = "Private Subnet 1 CIDR"
}

variable "private_subnet_2_cidr" {
  type        = string
  description = "Private Subnet 1 CIDR"
}

variable "private_subnet_3_cidr" {
	type        = string
  description = "Private Subnet 1 CIDR"
}
