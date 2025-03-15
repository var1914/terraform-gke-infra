output "kubernetes_cluster_name" {
  description = "GKE Cluster Name"
  value       = google_container_cluster.primary.name
}

output "kubernetes_cluster_host" {
  description = "GKE Cluster Host"
  value       = google_container_cluster.primary.endpoint
}

output "vpc_name" {
  description = "The VPC Name"
  value       = google_compute_network.vpc.name
}

output "subnet_name" {
  description = "The Subnet Name"
  value       = google_compute_subnetwork.subnet.name
}

output "kubectl_command" {
  description = "kubectl command to connect to the cluster"
  value       = "gcloud container clusters get-credentials ${var.cluster_name} --region ${var.region} --project ${var.project_id}"
}