variable "region" {
  type    = string
  default = "ap-northeast-1"
}

variable "remote_state_key" {
  type = string
}

variable "remote_state_bucket" {
  type = string
}

# application variables for task
variable "ecs_task_definition_name" {
  type = string
}

variable "ecs_service_name" {
  type = string
}

variable "docker_image_url" {
  type = string
}

variable "essential" {
  type = bool
}

variable "memory" {
  type = number
}

variable "docker_container_port" {
  type = number
}

variable "desired_task_number" {
  type = number
}
