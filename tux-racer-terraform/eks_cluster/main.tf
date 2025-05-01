# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0


# Filter out local zones, which are not currently supported 
# with managed node groups
data "aws_availability_zones" "available" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

data "terraform_remote_state" "vpc" {
  backend = "local"

  config = {
    path = "../aws_config/terraform.tfstate"
  }
}


module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.8.5"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version


  cluster_endpoint_public_access           = true
  enable_cluster_creator_admin_permissions = true

  cluster_addons = {
    # aws-ebs-csi-driver = {
    #   service_account_role_arn = module.irsa-ebs-csi.iam_role_arn
    # }
  }

  vpc_id = data.terraform_remote_state.vpc.outputs.aws_vpc_id
  subnet_ids = concat(
    data.terraform_remote_state.vpc.outputs.aws_public_subnet_id_list,
    data.terraform_remote_state.vpc.outputs.aws_private_subnet_id_list
  )

  eks_managed_node_group_defaults = {
    ami_type = var.ami_type

  }

  eks_managed_node_groups = {
    one = {
      name = "node-group-1"

      instance_types = [var.nodegroup_instance_type]

      iam_role_additional_policies = {
        ecr_read = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
      }

      min_size     = 1
      max_size     = 2
      desired_size = 1
    }

    two = {
      name = "node-group-2"

      instance_types = [var.nodegroup_instance_type]

      iam_role_additional_policies = {
        ecr_read = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
      }
      min_size     = 1
      max_size     = 2
      desired_size = 1
    }
  }
}


# https://aws.amazon.com/blogs/containers/amazon-ebs-csi-driver-is-now-generally-available-in-amazon-eks-add-ons/ 
# data "aws_iam_policy" "ebs_csi_policy" {
#   arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
# }
#
# module "irsa-ebs-csi" {
#   source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
#   version = "5.39.0"
#
#   create_role                   = true
#   role_name                     = "AmazonEKSTFEBSCSIRole-${module.eks.cluster_name}"
#   provider_url                  = module.eks.oidc_provider
#   role_policy_arns              = [data.aws_iam_policy.ebs_csi_policy.arn]
#   oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
# }

