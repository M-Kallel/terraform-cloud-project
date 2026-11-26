output "alb_url" {
  value = module.load_balancer.url
}
output "target_arn" {
  value = module.load_balancer.target_arn
}
output "asg_name" {
  value = module.compute.asg_name
}
output "db_identifier" {
  value = module.database.db_identifier
}
output "application_bucket" {
  value = module.storage.bucket
}
