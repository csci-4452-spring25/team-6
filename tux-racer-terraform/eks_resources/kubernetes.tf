

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

locals {
  region = data.terraform_remote_state.eks.outputs.region
  // use this variable to increment the version nubmer.
  version    = var.tux_racer_version
  image_name = var.image_name
}



# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster
# retrieves information about the eks who's name is passed in.  see url above
# then i can use this object to reference the other needed information about the 
# eks. 
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

# this is the pod deployment configs.  it essentially 
# is the blueprint of what the pods that eks deploys 
# should look like and be configured as. 
resource "kubernetes_deployment" "nginx" {
  metadata {
    name = "tux-racer-pod"
    labels = {
      App = "tuxracerprod"
    }
  }

  spec {
    replicas = 1
    selector {
      # reference to the meta data section? 
      match_labels = {
        App = "tuxracerprod"
      }
    }
    template {
      metadata {
        labels = {
          App = "tuxracerprod"
        }
      }
      spec {
        container {
          image = "${var.aws_account_id}.dkr.ecr.${local.region}.amazonaws.com/${local.image_name}:${local.version}"
          name  = "tux-racer-js"

          port {
            container_port = 80
          }

          resources {
            limits = {
              cpu    = "0.5"
              memory = "512Mi"
            }
            requests = {
              cpu    = "3m"
              memory = "50Mi"
            }
          }
        }
      }
    }
  }
}

# configs for doing horizontal scalling of pod resources.  
resource "kubernetes_horizontal_pod_autoscaler" "tux-autoscaler" {
  metadata {
    name = "tux-autoscaler"
  }

  spec {
    max_replicas = 5
    min_replicas = 1

    scale_target_ref {
      kind        = "Deployment"
      name        = kubernetes_deployment.nginx.metadata[0].name
      api_version = "apps/v1"
    }

    target_cpu_utilization_percentage = 3
  }
}


# This is the load balancer.  this is the 'service'
# that makes the application available to outside 
# traffic.  
resource "kubernetes_service" "nginx" {
  metadata {
    name = "nginx-example"
  }
  spec {
    selector = {
      App = kubernetes_deployment.nginx.spec.0.template.0.metadata[0].labels.App
    }
    port {
      port        = var.img_exposed_port
      target_port = 80
    }

    type = "LoadBalancer"
  }
}

output "lb_id" {
  value = kubernetes_service.nginx.status.0.load_balancer.0.ingress.0.hostname
}
