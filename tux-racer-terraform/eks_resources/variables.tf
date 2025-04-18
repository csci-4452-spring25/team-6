
variable "aws_account_id" {
  type      = string
  sensitive = true
}

variable "img_exposed_port" {
  type      = number
  sensitive = true
}
