data "aws_availability_zones" "available" {
  state = "available"
  filter {
    name   = "zone-type"
    values = ["availability-zone"]
  }
}
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = { Name = var.prefix }
}
locals {
  tiers = { public = 1, app = 11, db = 21 }
  subnets = merge([for tier, start in local.tiers : {
    for i in range(2) : "${tier}-${i}" => { index = i, net = start + i, tier = tier }
  }]...)
}
resource "aws_subnet" "tier" {
  for_each          = local.subnets
  vpc_id            = aws_vpc.main.id
  availability_zone = data.aws_availability_zones.available.names[each.value.index]
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, each.value.net)
  tags              = { Name = "${var.prefix}-${each.key}" }
}
resource "aws_internet_gateway" "public" {
  vpc_id = aws_vpc.main.id
}
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.public.id
  }
}
resource "aws_eip" "nat" {
  count  = var.dual_nat ? 2 : 1
  domain = "vpc"
}
resource "aws_nat_gateway" "app" {
  count         = length(aws_eip.nat)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.tier["public-${count.index}"].id
  depends_on    = [aws_internet_gateway.public]
}
resource "aws_route_table" "app" {
  count  = 2
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.app[var.dual_nat ? count.index : 0].id
  }
}
resource "aws_route_table" "db" {
  vpc_id = aws_vpc.main.id
}
resource "aws_route_table_association" "tier" {
  for_each       = local.subnets
  subnet_id      = aws_subnet.tier[each.key].id
  route_table_id = each.value.tier == "public" ? aws_route_table.public.id : each.value.tier == "db" ? aws_route_table.db.id : aws_route_table.app[each.value.index].id
}
