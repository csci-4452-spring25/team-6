output "region" {
  value = var.region
}

output "eks_cluster_name" {
  value = var.cluster_name
}

output "eks_cluster_cert_auth_data" {
  value = module.eks.cluster_certificate_authority_data
}

# output "hostname" {
#   value = module.eks.host
# }
