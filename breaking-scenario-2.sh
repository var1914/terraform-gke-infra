#!/bin/bash
# Scenario 2: DNS Resolution Breakage
# This script will corrupt the CoreDNS ConfigMap causing DNS resolution issues

# First, create a test deployment to verify DNS issues
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: dns-test
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: dns-test
  template:
    metadata:
      labels:
        app: dns-test
    spec:
      containers:
      - name: dns-test
        image: busybox:1.28
        command:
          - sleep
          - "3600"
EOF

# Wait for deployment to be ready
echo "Waiting for dns-test deployment to be ready..."
kubectl wait --for=condition=available deployment/dns-test --timeout=60s

# Backup the original CoreDNS ConfigMap
echo "Backing up the original CoreDNS ConfigMap..."
kubectl get configmap -n kube-system coredns -o yaml > coredns-configmap-backup.yaml

# Corrupt the CoreDNS ConfigMap
echo "Corrupting the CoreDNS ConfigMap..."
kubectl get configmap -n kube-system coredns -o json | \
  jq '.data.Corefile = ".:53 {\n  errors\n  health\n  kubernetes nonexistentdomain.local in-addr.arpa ip6.arpa {\n    pods insecure\n    fallthrough in-addr.arpa ip6.arpa\n  }\n  prometheus :9153\n  forward . /etc/resolv.conf\n  cache 30\n  loop\n  reload\n  loadbalance\n}\n"' | \
  kubectl apply -f -

# Restart CoreDNS pods to apply the changes
echo "Restarting CoreDNS pods..."
kubectl delete pods -n kube-system -l k8s-app=kube-dns

# --- Verification commands ---
echo ""
echo "To verify DNS is broken, run:"
echo "kubectl exec -it \$(kubectl get pods -l app=dns-test -o jsonpath='{.items[0].metadata.name}') -- nslookup kubernetes.default"
echo ""
echo "Expected result: 'nslookup' will fail with timeout or 'Server failure' errors"
echo ""
echo "To fix: Restore the original CoreDNS ConfigMap and restart CoreDNS pods:"
echo ""
echo "kubectl apply -f coredns-configmap-backup.yaml"
echo "kubectl delete pods -n kube-system -l k8s-app=kube-dns"