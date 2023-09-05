terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {}
}

provider "aws" {
  region = var.region
}

data "terraform_remote_state" "platform" {
  backend = "s3"

  config = {
    key    = var.remote_state_key
    bucket = var.remote_state_bucket
    region = var.region
  }
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition
resource "aws_ecs_task_definition" "helloworld-app" {
  family                   = var.ecs_service_name
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 512
  execution_role_arn       = aws_iam_role.fargate_iam_role.arn
  task_role_arn            = aws_iam_role.fargate_iam_role.arn
  memory                   = var.memory

  container_definitions = jsonencode([
    {
      name      = var.ecs_task_definition_name
      image     = var.docker_image_url
      essential = var.essential
      portMappings = [
        {
          containerPort = var.docker_container_port
          # hostPort      = 0
        }
      ]
    }
  ])
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role
resource "aws_iam_role" "fargate_iam_role" {
  name        = "${var.ecs_service_name}-IAM-Role-PolicyIAM-Role"
  description = "Fargate IAM Role"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = ["ecs.amazonaws.com", "ecs-tasks.amazonaws.com"]
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    tag-key = "tag-value"
  }
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy
resource "aws_iam_policy" "fargate_iam_role_policy" {
  name        = "${var.ecs_service_name}-IAM-Role-Policy"
  path        = "/"
  description = "Fargate IAM Role Policy"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ecs:*",
          "ecr:*",
          "logs:*",
          "cloudwatch:*",
          "elasticloadbalancing:*"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy_attachment
resource "aws_iam_policy_attachment" "fargate_iam_role_policy_attachment" {
	name = "${var.ecs_service_name}-IAM-Role-Policy-Attachment"
	roles = [aws_iam_role.fargate_iam_role.name]
	policy_arn = aws_iam_policy.fargate_iam_role_policy.arn
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group
resource "aws_security_group" "app-security-group" {
  name        = "${var.ecs_service_name}-SG"
  description = "Security group for ECS helloworld-app to communicate in and out"
  vpc_id      = data.terraform_remote_state.platform.outputs.vpc_id

  ingress {
    protocol    = "tcp"
    from_port   = 8080
    to_port     = 8080
    cidr_blocks = [data.terraform_remote_state.platform.outputs.vpc_cidr_block]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.ecs_service_name}-SG"
  }
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group
resource "aws_lb_target_group" "ecs_app_tareget_group" {
  name        = "${var.ecs_service_name}-TG"
  port        = var.docker_container_port
  protocol    = "HTTP"
  vpc_id      = data.terraform_remote_state.platform.outputs.vpc_id
  target_type = "ip"

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 30
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = 5
  }

  tags = {
    Name = "${var.ecs_service_name}-TG"
  }
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service
resource "aws_ecs_service" "ecs_service" {
  depends_on = [aws_ecs_task_definition.helloworld-app]

  name            = var.ecs_service_name
  task_definition = aws_ecs_task_definition.helloworld-app.arn
  launch_type     = "FARGATE"
  cluster         = data.terraform_remote_state.platform.outputs.ecs_cluster_id
  desired_count   = var.desired_task_number

  network_configuration {
    subnets          = data.terraform_remote_state.platform.outputs.ecs_public_subnets
    security_groups  = [aws_security_group.app-security-group.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs_app_tareget_group.arn
    container_name   = var.ecs_task_definition_name
    container_port   = var.docker_container_port
  }
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener_rule
resource "aws_lb_listener_rule" "ecs_service_lb_listener_rule" {
  listener_arn = data.terraform_remote_state.platform.outputs.ecs_alb_listener_arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs_app_tareget_group.arn
  }

  condition {
    host_header {
      values = ["${lower(var.ecs_service_name)}.${data.terraform_remote_state.platform.outputs.ecs_domain_name}"]
    }
  }
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group
resource "aws_cloudwatch_log_group" "helloworld_app_log_group" {
  name = "${var.ecs_service_name}-LogGroup"
}
