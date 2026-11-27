variable "prefix" {
  type        = string
  description = "Prefix for this environment."
}
variable "app_ids" {
  type        = list(string)
  description = "App ids for this environment."
}
variable "app_sg" {
  type        = string
  description = "App sg for this environment."
}
variable "target_arn" {
  type        = string
  description = "Target arn for this environment."
}
variable "instance_type" {
  type        = string
  description = "Instance type for this environment."
}
variable "min_size" {
  type        = number
  description = "Min size for this environment."
}
variable "max_size" {
  type        = number
  description = "Max size for this environment."
}
variable "desired_capacity" {
  type        = number
  description = "Desired capacity for this environment."
}
variable "tags" {
  type        = map(string)
  description = "Tags for this environment."
}
variable "ami_id" {
  description = "AMI to use for EC2 instances. Defaults to the latest matching Amazon Linux image."
  type        = string
  default     = null
}