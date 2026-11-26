variable "aws_region" {
  type        = string
  description = "Aws region for this environment."
}
variable "environment" {
  type        = string
  description = "Environment belonging to this state."
  validation {
    condition     = var.environment == "prod"
    error_message = "Use prod variables with this root."
  }
}
variable "project_name" {
  type        = string
  description = "Project name for this environment."
}
variable "owner" {
  type        = string
  description = "Owner for this environment."
}
variable "vpc_cidr" {
  type        = string
  description = "Vpc cidr for this environment."
}
variable "instance_type" {
  type        = string
  description = "Instance type for this environment."
}
variable "min_size" {
  type        = number
  description = "Min size for this environment."
}
variable "desired_capacity" {
  type        = number
  description = "Desired capacity for this environment."
}
variable "max_size" {
  type        = number
  description = "Max size for this environment."
}
variable "db_instance_class" {
  type        = string
  description = "Db instance class for this environment."
}
