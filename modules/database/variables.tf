variable "prefix" {
  type        = string
  description = "Prefix for this environment."
}
variable "db_ids" {
  type        = list(string)
  description = "Db ids for this environment."
}
variable "db_sg" {
  type        = string
  description = "Db sg for this environment."
}
variable "db_instance_class" {
  type        = string
  description = "Db instance class for this environment."
}
variable "production" {
  type        = bool
  description = "Production for this environment."
}
