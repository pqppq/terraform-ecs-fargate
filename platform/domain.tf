resource "aws_acm_certificate" "ecs_domain_certificate" {
  domain_name       = "*.${var.ecs_domain_name}"
  validation_method = "DNS"

  tags = {
    Name = "${var.ecs_cluster_name}-Certificate"
  }
}

data "aws_route53_zone" "ecs_domain" {
  name         = var.ecs_domain_name
  private_zone = false
}

#	records = [aws_acm_certificate.ecs_domain_certificate.domain_validation_options.0.resource_record_value]
resource "aws_route53_record" "ecs_cert_validation_record" {
  for_each = {
    for ecs in aws_acm_certificate.ecs_domain_certificate.domain_validation_options : ecs.domain_name => {
      name   = ecs.resource_record_name
      record = ecs.resource_record_value
      type   = ecs.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.ecs_domain.zone_id
}

resource "aws_acm_certificate_validation" "ecs_domain_certificate_validation" {
  certificate_arn         = aws_acm_certificate.ecs_domain_certificate.arn
  validation_record_fqdns = [for record in aws_route53_record.ecs_cert_validation_record : record.fqdn]
}

resource "aws_iam_role" "ecs_cluster_role" {
  name               = "${var.ecs_cluster_name}-IAM-Role"
  assume_role_policy = <<EOF
{
"Version": "2012-10-17",
"Statement": [
 {
   "Effect": "Allow",
   "Principal": {
     "Service": ["ecs.amazonaws.com", "ec2.amazonaws.com", "application-autoscaling.amazonaws.com"]
   },
   "Action": "sts:AssumeRole"
  }
  ]
 }
EOF
}

resource "aws_iam_role_policy" "ecs_cluster_policy" {
  name   = "${var.ecs_cluster_name}-IAM-Policy"
  role   = aws_iam_role.ecs_cluster_role.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecs:*",
        "ec2:*",
        "elasticloadbalancing:*",
        "ecr:*",
        "dynamodb:*",
        "cloudwatch:*",
        "s3:*",
        "rds:*",
        "sqs:*",
        "sns:*",
        "logs:*",
        "ssm:*"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}
