#!/bin/bash
# Scenario 4: Break Node-to-Pod Communication with Firewall Rules
# This script will create a restrictive firewall rule blocking node-to-pod traffic

# First, get the cluster network name
CLUSTER_NAME="catawiki-demo"
NETWORK_NAME=$(gcloud container clusters describe $CLUSTER_NAME --format="value(network)" --zone=$(gcloud container clusters list --format="value(zone)" --limit=1))
PROJECT_ID="catawiki-452406"

echo "Cluster name: $CLUSTER_NAME"
echo "Network name: $NETWORK_NAME"
echo "Project ID: $PROJECT_ID"

# Get the pod CIDR range
POD_CIDR=$(gcloud container clusters describe $CLUSTER_NAME --format="value(clusterIpv4Cidr)" --zone=$(gcloud container clusters list --format="value(zone)" --limit=1))
echo "Pod CIDR: $POD_CIDR"

# Create a firewall rule to block traffic to pod CIDR
echo "Creating firewall rule to block node-to-pod traffic..."
gcloud compute firewall-rules create block-pod-traffic \
  --network $NETWORK_NAME \
  --action deny \
  --direction ingress \
  --rules tcp,udp,icmp \
  --source-ranges "0.0.0.0/0" \
  --destination-ranges $POD_CIDR \
  --priority 900

# Deploy a test application
kubectl create deployment nginx --image=nginx --replicas=3

# Wait for deployment to be ready
echo "Waiting for nginx deployment to be ready..."
kubectl wait --for=condition=available deployment/nginx --timeout=60s

# Create a service to expose the deployment
kubectl expose deployment nginx --port=80 --type=ClusterIP

# --- Verification commands ---
echo ""
echo "To verify the node-to-pod communication is broken, run:"
echo "kubectl exec -it \$(kubectl get pods -l app=nginx -o jsonpath='{.items[0].metadata.name}') -- curl nginx.default.svc.cluster.local"
echo ""
echo "Expected result: The connection will time out or fail because node-to-pod traffic is blocked by the firewall rule"
echo ""
echo "To fix: Delete the restrictive firewall rule:"
echo ""
echo "gcloud compute firewall-rules delete block-pod-traffic"