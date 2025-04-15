variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "value"
  type        = string
  default     = "tux-racer-ts"
}

variable "cluster_version" {
  description = "eks version"
  type        = string
  default     = "1.32"
}

