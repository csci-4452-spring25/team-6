# IAM Roles
resource "aws_iam_role" "eks_role" {
  name = "tux-eks-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_policy" {
  role       = aws_iam_role.eks_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}



# EKS Cluster
resource "aws_eks_cluster" "tux_eks" {
  name     = "tux-racer-eks"
  role_arn = aws_iam_role.eks_role.arn
  vpc_config {
    subnet_ids = concat(var.eks_private_subnet_list, var.eks_public_subnet_list)
  }
  depends_on = [aws_iam_role_policy_attachment.eks_policy]
}

resource "aws_iam_role" "node_role" {
  name = "tux-node-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
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


resource "aws_eks_node_group" "tux_nodes" {
  cluster_name    = aws_eks_cluster.tux_eks.name
  node_group_name = "tux-nodes"
  node_role_arn   = aws_iam_role.node_role.arn
  subnet_ids      = var.eks_private_subnet_list
  scaling_config {
    desired_size = 2
    max_size     = 5
    min_size     = 2
  }
  instance_types = ["t3.micro"]
  depends_on     = [aws_iam_role_policy_attachment.node_policy]
}

