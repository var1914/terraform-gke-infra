provider "google" {
  project = var.project_id
  region  = var.region
}

# VPC Network
resource "google_compute_network" "vpc" {
  name                    = "${var.cluster_name}-vpc"
  auto_create_subnetworks = false
}

# Subnet for GKE nodes
resource "google_compute_subnetwork" "subnet" {
  name          = "${var.cluster_name}-subnet"
  region        = var.region
  network       = google_compute_network.vpc.name
  ip_cidr_range = var.subnet_cidr

  # Secondary IP ranges for pods and services
  secondary_ip_range {
    range_name    = "pod-range"
    ip_cidr_range = var.pod_cidr
  }

  secondary_ip_range {
    range_name    = "service-range"
    ip_cidr_range = var.service_cidr
  }
}

# Cloud Router for NAT gateway (allows private nodes to access internet)
resource "google_compute_router" "router" {
  name    = "${var.cluster_name}-router"
  region  = var.region
  network = google_compute_network.vpc.name
}

# NAT Gateway
resource "google_compute_router_nat" "nat" {
  name                               = "${var.cluster_name}-nat"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

# GKE Cluster
resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.region

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1

  network    = google_compute_network.vpc.name
  subnetwork = google_compute_subnetwork.subnet.name

  # Enable VPC-native cluster (using alias IPs)
  ip_allocation_policy {
    cluster_secondary_range_name  = "pod-range"
    services_secondary_range_name = "service-range"
  }

  # Enable private nodes (no public IPs for nodes)
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false  # Allow public access to master
    master_ipv4_cidr_block  = var.master_cidr
  }

  # Enable network policy for the cluster
  network_policy {
    enabled  = true
    provider = "CALICO"
  }

  # Disable basic authentication and client certificate
  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }
  deletion_protection = false
}

# Separately Managed Node Pool
resource "google_container_node_pool" "primary_nodes" {
  name       = "${var.cluster_name}-node-pool"
  location   = var.region
  cluster    = google_container_cluster.primary.name
  node_count = var.node_count

  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/devstorage.read_only"
    ]

    labels = {
      env = var.env
    }

    machine_type = var.machine_type
    disk_size_gb = var.disk_size
    disk_type    = "pd-standard"

    metadata = {
      disable-legacy-endpoints = "true"
    }

    tags = ["gke-node", "${var.cluster_name}-node"]
  }
}