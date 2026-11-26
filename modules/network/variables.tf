variable "prefix" {
  type        = string
  description = "Prefix for this environment."
}
variable "vpc_cidr" {
  type        = string
  description = "Vpc cidr for this environment."
}
variable "dual_nat" {
  type        = bool
  description = "Dual nat for this environment."
}
