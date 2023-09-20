
resource "aws_vpc" "_" {
  cidr_block                       = "10.1.0.0/16"
  assign_generated_ipv6_cidr_block = true

  enable_dns_support   = true
  enable_dns_hostnames = true
}

resource "aws_subnet" "builder" {
  vpc_id                  = aws_vpc._.id
  ipv6_cidr_block         = cidrsubnet(aws_vpc._.ipv6_cidr_block, 8, 1)
  cidr_block              = "10.1.1.0/24"
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "_" {
  vpc_id = aws_vpc._.id
}

resource "aws_route_table" "_" {
  vpc_id = aws_vpc._.id
}

resource "aws_route_table_association" "builder" {
  subnet_id      = aws_subnet.builder.id
  route_table_id = aws_route_table._.id
}

resource "aws_route" "default" {
  route_table_id              = aws_route_table._.id
  destination_cidr_block      = "0.0.0.0/0"
  gateway_id                  = aws_internet_gateway._.id
}

resource "aws_route" "default6" {
  route_table_id              = aws_route_table._.id
  destination_ipv6_cidr_block = "::/0"
  gateway_id                  = aws_internet_gateway._.id
}

