resource "aws_security_group" "ecs_alb_security_group" {
	name = "${var.ecs_cluster_name}-ALB-SG"
	description = "Security group for ALB to traffic for ECS cluster"
	vpc_id = data.terraform_remote_state.infrastructure.outputs.vpc_id

	ingress {
		description =  "Allow traffic from the Internet"
		from_port = 443
		protocol = "TCP"
		to_port = 443
		cidr_blocks = [var.internet_cidr_blocks]
	}

	egress {
		description = "Allow traffic to the Internet for all protocol"
		from_port = 0
		protocol = "-1" // all protocol
		to_port = 0
		cidr_blocks = [var.internet_cidr_blocks]
	}
}
