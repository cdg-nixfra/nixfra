module "management_state" {
  source = "../management-state"
}

resource "aws_key_pair" "cees" {
  key_name   = "cees-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC3ezI+JP1lrdI6FYd1ynnCPv/IZS4wrxZXnXGpMBvJIZ5fvtHC/8pnHkZiFR64IZvd0Irrh+aJ79ahLa2EToqq9pLVmWx8vIGPZzpE6d/buBg1qjlzKn8iWjlJc938WlvqiqCkcMjLKKkfBmMDg2pUFxPE5QPxAHcaszxxEO59/l9C7tOpqDeX7CozlYoUtIVCvOLLgMPIbRTjPbJ6Qax8bmqoB5/F5Arm7GGckgJ9kQblBncy1sCsykQtvos7MbBbsPmjGEBvGEbvyxORlMBLFMyhEnUt+fVipOyFqiMv6LgVA7l73cOmGMOeWX5/PwxmNxUNAjhAy/1t1koxnZ3GT+IvKQSq3v3B14ZJTHCpsiQMRoz/fpj8BBY4tv8eTfzGljlJGEOV2Q/ju1ewBtFsSDugXylqfj2DQjt7PrFDH1t4l/sxt5IhicQr6Ljg/e9egcXTEcI8DRETnIf1963e8HyLccNGO1ZSMD5CRUa3R2ih74yjyGDCRpmwAJJ9IvE= cees@system76-pc"
}

locals {
  azs = ["ca-central-1a", "ca-central-1b"]
}

resource "aws_vpc" "_" {
  cidr_block                       = "10.2.0.0/16"
  assign_generated_ipv6_cidr_block = true

  enable_dns_support   = true
  enable_dns_hostnames = true
}

resource "aws_subnet" "backend" {
  count                                          = length(local.azs)
  vpc_id                                         = aws_vpc._.id
  availability_zone                              = local.azs[count.index]
  ipv6_cidr_block                                = cidrsubnet(aws_vpc._.ipv6_cidr_block, 8, count.index + 1)
  cidr_block                                     = "10.2.${count.index + 1}.0/24"
  enable_resource_name_dns_aaaa_record_on_launch = true
  map_public_ip_on_launch                        = true
}

resource "aws_internet_gateway" "_" {
  vpc_id = aws_vpc._.id
}

resource "aws_route_table" "_" {
  vpc_id = aws_vpc._.id
}

resource "aws_route_table_association" "backend" {
  count          = length(local.azs)
  subnet_id      = aws_subnet.backend[count.index].id
  route_table_id = aws_route_table._.id
}

resource "aws_route" "default" {
  route_table_id         = aws_route_table._.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway._.id
}

resource "aws_route" "default6" {
  route_table_id              = aws_route_table._.id
  destination_ipv6_cidr_block = "::/0"
  gateway_id                  = aws_internet_gateway._.id
}

locals {
  infra_bucket = "nixfra-infra-tfstate"
}

data "aws_s3_object" "builder_rsa_host_key" {
  bucket = local.infra_bucket
  key    = "infra/builder/rsa_host_key.pub"
}

data "aws_s3_object" "builder_ed25519_host_key" {
  bucket = local.infra_bucket
  key    = "infra/builder/ed25519_host_key.pub"
}


module "nix_configuration" {
  source = "../../common/modules/mustache"
  vars = {
    builder_rsa_host_key     = data.aws_s3_object.builder_rsa_host_key.body
    builder_ed25519_host_key     = data.aws_s3_object.builder_ed25519_host_key.body
  }
  template_file = "deployinator.nix.tpl"
}

resource "aws_security_group" "backend" {
  vpc_id = aws_vpc._.id
}

resource "aws_security_group_rule" "ssh-in" {
  type              = "ingress"
  security_group_id = aws_security_group.backend.id
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
}

# TODO probably want to tighten this down a bit to just
# clustering traffic? Handy for debugging though.
resource "aws_security_group_rule" "all-self" {
  type              = "ingress"
  security_group_id = aws_security_group.backend.id
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  self              = true
}

resource "aws_security_group_rule" "all-out" {
  security_group_id = aws_security_group.backend.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
}

resource "aws_iam_role" "deployinator" {
  name = "deployinator"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  inline_policy {
    name = "deployinator"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = "s3:GetObject"
          Effect = "Allow"
          Resource = [
            "arn:aws:s3:::nixfra-infra-tfstate/infra/builder/*"
          ]
        }
      ]
    })
  }

}
resource "aws_iam_instance_profile" "deployinator" {
  name = "deployinator"
  role = aws_iam_role.deployinator.name
}


resource "aws_instance" "backend" {
  count = length(local.azs)

  # TODO how can we pull that out of NixPkgs?
  ami = "ami-031821b5f83896474"

  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.backend[count.index].id
  vpc_security_group_ids      = [aws_security_group.backend.id]
  ipv6_address_count          = 1
  iam_instance_profile        = aws_iam_instance_profile.deployinator.name
  key_name                    = aws_key_pair.cees.key_name
  user_data                   = module.nix_configuration.rendered
  user_data_replace_on_change = true
  root_block_device {
    volume_size = 25
  }
  tags = {
    nixfra_environment = "staging"
    nixfra_app         = "nixfra_phx"
  }

  connection {
    type = "ssh"
    user = "root"
    host = self.public_ip
  }
  provisioner "remote-exec" {
    script = "./setup-deployinator-keys.sh"
  }
}


resource "aws_acm_certificate" "backend" {
  domain_name       = "backend.staging.${module.management_state.main_zone_name}"
  validation_method = "DNS"
}

resource "aws_route53_record" "backend_cert_rrs" {
  for_each = {
    for dvo in aws_acm_certificate.backend.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = module.management_state.staging_zone_id
}
resource "aws_acm_certificate_validation" "backend" {
  certificate_arn         = aws_acm_certificate.backend.arn
  validation_record_fqdns = [for record in aws_route53_record.backend_cert_rrs : record.fqdn]
}

resource "aws_lb" "backend" {
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.backend.id]
  ip_address_type    = "dualstack"
  subnets            = [for subnet in aws_subnet.backend : subnet.id]
}
resource "aws_lb_target_group" "backend" {
  port     = 4000
  protocol = "HTTP"
  vpc_id   = aws_vpc._.id

  deregistration_delay = 5
  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 5
    path                = "/"
    timeout             = 2
    unhealthy_threshold = 2
  }

}
#resource "aws_lb_target_group_attachment" "backend" {
#count            = length(local.azs)
#target_group_arn = aws_lb_target_group.backend.arn
#target_id        = aws_instance.backend[count.index].id
#}
resource "aws_lb_listener" "backend_tls" {
  load_balancer_arn = aws_lb.backend.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate_validation.backend.certificate_arn
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }
}
resource "aws_lb_listener" "backend_redir" {
  load_balancer_arn = aws_lb.backend.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}
resource "aws_route53_record" "backend" {
  name    = aws_acm_certificate.backend.domain_name
  type    = "CNAME"
  zone_id = module.management_state.staging_zone_id
  ttl     = 60
  records = [
    aws_lb.backend.dns_name
  ]
}

output "backend_ips" {
  value = [for i in aws_instance.backend : i.public_ip]
}
