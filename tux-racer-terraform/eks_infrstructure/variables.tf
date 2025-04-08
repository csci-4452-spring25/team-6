
variable "eks_public_subnet_list" {
  description = "A list of public subnets for the eks cluster"
  type        = list(string)
}

variable "eks_private_subnet_list" {
  description = "A list of private subnets for the eks cluster"
  type        = list(string)
}

