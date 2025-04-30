
variable "aws_account_id" {
  type      = string
  sensitive = true
}

variable "img_exposed_port" {
  type      = number
  sensitive = true
}

variable "tux_racer_version" {
  description = "the version number in vX.YY.ZZ format to deploy on in the cluster"
  type        = string
}

variable "image_name" {
  description = "the name of the image container in ecr"
  type        = string
  default     = "tux-racer-ts"
}
