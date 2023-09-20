module "management_state" {
  source = "../management-state"
}

resource "tls_private_key" "host_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_private_key" "nix_ssh_serve" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "cees" {
  key_name   = "cees-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC3ezI+JP1lrdI6FYd1ynnCPv/IZS4wrxZXnXGpMBvJIZ5fvtHC/8pnHkZiFR64IZvd0Irrh+aJ79ahLa2EToqq9pLVmWx8vIGPZzpE6d/buBg1qjlzKn8iWjlJc938WlvqiqCkcMjLKKkfBmMDg2pUFxPE5QPxAHcaszxxEO59/l9C7tOpqDeX7CozlYoUtIVCvOLLgMPIbRTjPbJ6Qax8bmqoB5/F5Arm7GGckgJ9kQblBncy1sCsykQtvos7MbBbsPmjGEBvGEbvyxORlMBLFMyhEnUt+fVipOyFqiMv6LgVA7l73cOmGMOeWX5/PwxmNxUNAjhAy/1t1koxnZ3GT+IvKQSq3v3B14ZJTHCpsiQMRoz/fpj8BBY4tv8eTfzGljlJGEOV2Q/ju1ewBtFsSDugXylqfj2DQjt7PrFDH1t4l/sxt5IhicQr6Ljg/e9egcXTEcI8DRETnIf1963e8HyLccNGO1ZSMD5CRUa3R2ih74yjyGDCRpmwAJJ9IvE= cees@system76-pc"
}

data "external" "gh_token" {
  program = [
    "sh", "-c",
    "gh api --method POST -H 'Accept: application/vnd.github+json' -H 'X-GitHub-Api-Version: 2022-11-28'   /orgs/cdg-nixfra/actions/runners/registration-token"
  ]
}

module "nix_configuration" {
  source = "../../common/modules/mustache"
  vars = {
    ssh_serve_key   = trimspace(tls_private_key.nix_ssh_serve.public_key_openssh),
    gh_runner_token = data.external.gh_token.result.token,
    host_rsa_key    = trimspace(tls_private_key.host_key.private_key_pem),
  }
  template_file = "builder.nix.tpl"
}

resource "aws_iam_role" "builder" {
  name = "builder"

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

  #inline_policy {
  #name = "allow-builder-token"
  #policy = jsonencode({
  #Version = "2012-10-17"
  #Statement = [
  #]
  #})
  #}
}
resource "aws_iam_instance_profile" "builder" {
  name = "builder"
  role = aws_iam_role.builder.name
}


resource "aws_security_group" "builder" {
  vpc_id = aws_vpc._.id

  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    self             = false
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_instance" "builder" {
  # TODO how can we pull that out of NixPkgs?
  ami = "ami-031821b5f83896474"

  instance_type               = "t3.medium"
  subnet_id                   = aws_subnet.builder.id
  vpc_security_group_ids      = [aws_security_group.builder.id]
  ipv6_address_count          = 1
  key_name                    = aws_key_pair.cees.key_name
  iam_instance_profile        = aws_iam_instance_profile.builder.name
  user_data                   = module.nix_configuration.rendered
  user_data_replace_on_change = true
  root_block_device {
    volume_size = 25
  }
}

resource "aws_route53_record" "builder_v4" {
  zone_id = module.management_state.infra_zone_id
  name    = "builder"
  type    = "A"
  ttl     = 30
  records = [aws_instance.builder.public_ip]
}

resource "aws_route53_record" "builder_v6" {
  zone_id = module.management_state.infra_zone_id
  name    = "builder"
  type    = "AAAA"
  ttl     = 30
  records = aws_instance.builder.ipv6_addresses
}

output "builder_ip" {
  value = aws_instance.builder.public_ip
}

output "builder_dns" {
  value = aws_instance.builder.public_dns
}
