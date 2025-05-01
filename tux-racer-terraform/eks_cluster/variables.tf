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

variable "ami_type" {
  description = "ami type for eks nodegroup"
  type        = string
  default     = "AL2_x86_64"
}

variable "nodegroup_instance_type" {
  description = "instance ec2 type for node group"
  type        = string
  default     = "t3.small"

}

