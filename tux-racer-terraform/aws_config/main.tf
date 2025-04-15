terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# VPC
resource "aws_vpc" "tux_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = { Name = "tux-racer-vpc" }
}

resource "aws_subnet" "public_subnet_1" {
  vpc_id            = aws_vpc.tux_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
  tags = { Name = "tux-public-subnet-1" }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id            = aws_vpc.tux_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true
  tags = { Name = "tux-public-subnet-2" }
}

resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.tux_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1a"
  tags = { Name = "tux-private-subnet-1" }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.tux_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-1b"
  tags = { Name = "tux-private-subnet-2" }
}

resource "aws_internet_gateway" "tux_igw" {
  vpc_id = aws_vpc.tux_vpc.id
  tags = { Name = "tux-igw" }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.tux_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.tux_igw.id
  }
  tags = { Name = "tux-public-rt" }
}

resource "aws_route_table_association" "public_assoc_1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_assoc_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_eip" "nat_eip" {
  vpc = true
}

resource "aws_nat_gateway" "tux_nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet_1.id
  tags = { Name = "tux-nat" }
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.tux_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.tux_nat.id
  }
  tags = { Name = "tux-private-rt" }
}

resource "aws_route_table_association" "private_assoc_1" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_assoc_2" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_rt.id
}

# IAM Roles
resource "aws_iam_role" "eks_role" {
  name = "tux-eks-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_policy" {
  role       = aws_iam_role.eks_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role" "node_role" {
  name = "tux-node-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "node_policy" {
  role       = aws_iam_role.node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "node_cni_policy" {
  role       = aws_iam_role.node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "node_ecr_policy" {
  role       = aws_iam_role.node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# EKS Cluster
resource "aws_eks_cluster" "tux_eks" {
  name     = "tux-racer-eks"
  role_arn = aws_iam_role.eks_role.arn
  vpc_config {
    subnet_ids = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id, aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
  }
  depends_on = [aws_iam_role_policy_attachment.eks_policy]
}

resource "aws_eks_node_group" "tux_nodes" {
  cluster_name    = aws_eks_cluster.tux_eks.name
  node_group_name = "tux-nodes"
  node_role_arn   = aws_iam_role.node_role.arn
  subnet_ids      = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
  scaling_config {
    desired_size = 2
    max_size     = 5
    min_size     = 2
  }
  instance_types = ["t3.micro"]
  depends_on = [aws_iam_role_policy_attachment.node_policy]
}

# ECR Repository
resource "aws_ecr_repository" "tux_ecr" {
  name = "tux-racer-js"
  image_tag_mutability = "MUTABLE"
}