# GKE Terraform Learning & Debugging Environment

This repository contains Terraform configurations to set up a Google Kubernetes Engine (GKE) cluster with a complete networking setup, along with scenarios designed to break the cluster in controlled ways for learning and debugging purposes.

## Overview

This project helps you:
1. Deploy a production-ready GKE cluster using Terraform
2. Learn Kubernetes troubleshooting through intentional failure scenarios
3. Practice debugging common Kubernetes issues

## Architecture

The Terraform configuration creates:
- A custom VPC network
- Private GKE cluster with VPC-native networking (alias IPs)
- Separate node pools with configurable machine types
- NAT gateway for outbound internet access from private nodes
- Network policies enabled with Calico

## Prerequisites

- Google Cloud Platform account with billing enabled
- Terraform 1.0+
- `gcloud` CLI installed and configured
- Kubernetes CLI (`kubectl`) installed

## Getting Started

### 1. Clone the repository

```bash
git clone <repository-url>
cd gke-terraform-debugging
```

### 2. Configure variables

Create a `terraform.tfvars` file with your project-specific values:

```hcl
project_id    = "your-gcp-project-id"
region        = "us-central1"
cluster_name  = "debug-cluster"
env           = "dev"
subnet_cidr   = "10.0.0.0/24"
pod_cidr      = "10.1.0.0/16"
service_cidr  = "10.2.0.0/16"
master_cidr   = "172.16.0.0/28"
node_count    = 3
machine_type  = "e2-standard-2"
disk_size     = 100
```

### 3. Deploy the infrastructure

```bash
terraform init
terraform plan
terraform apply
```

### 4. Configure kubectl

After successful deployment, configure kubectl to connect to your new cluster:

```bash
gcloud container clusters get-credentials debug-cluster --region us-central1 --project your-gcp-project-id
```

### 5. Deploy the demo application

```bash
kubectl apply -f demo-app.yaml
```

## Clean Up

To destroy all resources when you're done:

```bash
terraform destroy
```

## Contributing

To add a new breaking scenario:
1. Create a new script named `breaking-scenario-X.sh`
2. Include clear comments explaining what breaks and why
3. Add verification commands within the script to demonstrate the issue
4. Document the solution

## Resources

- [GKE Documentation](https://cloud.google.com/kubernetes-engine/docs)
- [Kubernetes Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
- [Terraform GCP Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
