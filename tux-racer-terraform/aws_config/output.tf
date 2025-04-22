output "aws_vpc_id" {
  description = "VPC reference from aws instrastructure"
  value       = aws_vpc.tux_vpc.id
}

output "aws_public_subnet_id_list" {
  description = "List of Public subnets ids"
  value = [
    aws_subnet.public_subnet_1.id,
    aws_subnet.public_subnet_2.id
  ]
}

output "aws_private_subnet_id_list" {
  description = "List of private subnets ids"
  value = [
    aws_subnet.private_subnet_1.id,
    aws_subnet.private_subnet_2.id
  ]
}

