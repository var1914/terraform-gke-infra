#!/bin/bash
# Scenario 3: Break External Service Access
# This script will deploy a service but corrupt its external access

# Deploy the sample application
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
  namespace: default
spec:
  replicas: 2
  selector:
    matchLabels:
      app: web-app
  template:
    metadata:
      labels:
        app: web-app
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: web-app
  namespace: default
spec:
  selector:
    app: web-app
  ports:
  - port: 80
    targetPort: 80
  type: LoadBalancer
EOF

# Wait for service to get external IP
echo "Waiting for LoadBalancer to get an external IP..."
while [[ $(kubectl get svc web-app -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null) == "" ]]; do
  echo -n "."
  sleep 5
done
echo ""

EXTERNAL_IP=$(kubectl get svc web-app -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Service external IP: $EXTERNAL_IP"

# Break the service by changing the selector to a non-existent label
echo "Breaking the service by changing the selector..."
kubectl patch svc web-app -p '{"spec":{"selector":{"app":"non-existent"}}}'

# --- Verification commands ---
echo ""
echo "To verify the service is broken, run:"
echo "curl $EXTERNAL_IP"
echo ""
echo "Expected result: The connection will time out or reset because no pods match the service selector"
echo ""
echo "To fix: Update the service selector to match the deployment labels:"
echo ""
echo "kubectl patch svc web-app -p '{\"spec\":{\"selector\":{\"app\":\"web-app\"}}}'"