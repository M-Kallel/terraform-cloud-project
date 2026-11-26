variable "prefix" {
  type        = string
  description = "Prefix for this environment."
}
variable "vpc_id" {
  type        = string
  description = "Vpc id for this environment."
}
variable "public_ids" {
  type        = list(string)
  description = "Public ids for this environment."
}
variable "alb_sg" {
  type        = string
  description = "Alb sg for this environment."
}
