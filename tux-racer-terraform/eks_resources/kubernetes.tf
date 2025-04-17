terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.48.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.16.1"
    }
  }
}

# Data references 
data "terraform_remote_state" "eks" {
  backend = "local"

  config = {
    path = "../eks_cluster/terraform.tfstate"
  }
}

# Retrieve EKS cluster information
provider "aws" {
  region = data.terraform_remote_state.eks.outputs.region
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster
# retrieves information about the eks who's name is passed in.  See url above
# Then I can use this object to reference the other needed information about the 
# EKS. 
data "aws_eks_cluster" "cluster" {
  name = data.terraform_remote_state.eks.outputs.eks_cluster_name
}

provider "kubernetes" {
  host = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(
    data.aws_eks_cluster.cluster.certificate_authority.0.data
  )
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks", "get-token", "--cluster-name", data.aws_eks_cluster.cluster.name
    ]
  }
}

resource "kubernetes_deployment" "nginx" {
  metadata {
    name = "tux-racer-pod"
    labels = {
      App = "TuxRacerProd"
    }
  }

  spec {
    replicas = 2
    selector {
      # reference to the meta data section? 
      match_labels = {
        App = "TuxRacerProd"
      }
    }
    template {
      metadata {
        labels = {
          App = "TuxRacerProd"
        }
      }
      spec {
        container {
          image = "nginx:1.7.8"
          name  = "example"

          port {
            container_port = 80
          }

          resources {
            limits = {
              cpu    = "0.5"
              memory = "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "50Mi"
            }
          }
        }
      }
    }
  }
}
