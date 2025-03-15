#!/bin/bash
# Scenario 1: Network Policy Breakage
# This script will deploy two services and a restrictive network policy
# that blocks communication between them

# Create namespaces
kubectl create namespace frontend
kubectl create namespace backend

# Deploy frontend app
cat <<EOF | kubectl apply -f - -n frontend
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
      - name: frontend
        image: nginx:latest
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: frontend
spec:
  selector:
    app: frontend
  ports:
  - port: 80
    targetPort: 80
EOF

# Deploy backend app
cat <<EOF | kubectl apply -f - -n backend
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
      - name: backend
        image: nginx:latest
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: backend
spec:
  selector:
    app: backend
  ports:
  - port: 80
    targetPort: 80
EOF

# Create a default deny-all network policy in the backend namespace
cat <<EOF | kubectl apply -f - -n backend
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
EOF

# --- Verification commands ---
echo "To verify connectivity is broken, run:"
echo "kubectl exec -it -n frontend \$(kubectl get pods -n frontend -l app=frontend -o jsonpath='{.items[0].metadata.name}') -- curl backend.backend.svc.cluster.local"
echo ""
echo "Expected result: curl will hang or timeout because the network policy blocks all ingress traffic to backend namespace"
echo ""
echo "To fix: Create a network policy that allows traffic from frontend namespace:"
echo ""
echo "kubectl apply -f - -n backend <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-from-frontend
spec:
  podSelector:
    matchLabels:
      app: backend
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: frontend
    ports:
    - protocol: TCP
      port: 80
EOF"