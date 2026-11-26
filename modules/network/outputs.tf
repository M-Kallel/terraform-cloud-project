output "vpc_id" {
  value = aws_vpc.main.id
}
output "public_ids" {
  value = [for i in range(2) : aws_subnet.tier["public-${i}"].id]
}
output "app_ids" {
  value = [for i in range(2) : aws_subnet.tier["app-${i}"].id]
}
output "db_ids" {
  value = [for i in range(2) : aws_subnet.tier["db-${i}"].id]
}
