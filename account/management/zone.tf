locals {
  main  = "nixfra.ca"
  zones = ["infra", "infra", "production"]
}

resource "aws_route53_zone" "main" {
  name = local.main
}

output "main_zone_id" {
  value = aws_route53_zone.main.zone_id
}

output "main_ns" {
  value = aws_route53_zone.main.name_servers
}

resource "aws_route53_zone" "infra" {
  provider = aws.infra
  name     = "infra.${local.main}"
}

resource "aws_route53_record" "infra" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "infra.${local.main}"
  type    = "NS"
  ttl     = "30"
  records = aws_route53_zone.infra.name_servers
}

resource "aws_route53_zone" "staging" {
  provider = aws.staging
  name     = "staging.${local.main}"
}

resource "aws_route53_record" "staging" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "staging.${local.main}"
  type    = "NS"
  ttl     = "30"
  records = aws_route53_zone.staging.name_servers
}

resource "aws_route53_zone" "production" {
  provider = aws.production
  name     = "production.${local.main}"
}

resource "aws_route53_record" "production" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "production.${local.main}"
  type    = "NS"
  ttl     = "30"
  records = aws_route53_zone.production.name_servers
}

resource "local_file" "zone_ids" {
  content  = <<EOF
output "main_zone_name" {
  value = "${local.main}"
}
output "infra_zone_id" {
  value = "${aws_route53_zone.infra.zone_id}"
}
output "staging_zone_id" {
  value = "${aws_route53_zone.staging.zone_id}"
}
output "production_zone_id" {
  value = "${aws_route53_zone.production.zone_id}"
}
EOF
  filename = "../management-state/zone_ids.tf"
}
