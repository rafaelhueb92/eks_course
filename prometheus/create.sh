#!/bin/bash

# Configuration variables
CLUSTER_NAME="prometheus-cluster"
REGION="us-east-1"
NODE_GROUP_NAME="prometheus-nodes"
INSTANCE_TYPE="t3.medium"
MIN_NODES=2
MAX_NODES=4
DESIRED_NODES=2

echo "🚀 Starting EKS cluster creation and Prometheus deployment..."

# 1. Create EKS cluster
echo "📦 Creating EKS cluster: $CLUSTER_NAME"
eksctl create cluster \
  --name $CLUSTER_NAME \
  --region $REGION \
  --nodegroup-name $NODE_GROUP_NAME \
  --node-type $INSTANCE_TYPE \
  --nodes $DESIRED_NODES \
  --nodes-min $MIN_NODES \
  --nodes-max $MAX_NODES \
  --managed \
  --with-oidc # Eneable OPEN ID

if [ $? -ne 0 ]; then
  echo "❌ Failed to create EKS cluster"
  exit 1
fi

echo "✅ EKS cluster created successfully"

# 2. Update kubeconfig
echo "🔧 Updating kubeconfig..."
aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME

bash create-addon-ebs.sh $CLUSTER_NAME $REGION

# Wait for EBS CSI driver to be ready
echo "⏳ Waiting for EBS CSI driver to be ready..."
kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=aws-ebs-csi-driver -n kube-system --timeout=600s

# 5. Create StorageClass for EBS
echo "📁 Creating StorageClass..."
cat <<EOF | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: gp3-ebs
provisioner: ebs.csi.aws.com
parameters:
  type: gp3
  fsType: ext4
volumeBindingMode: WaitForFirstConsumer
reclaimPolicy: Delete
EOF

# 6. Create namespace for Prometheus
echo "📂 Creating prometheus namespace..."
kubectl create namespace prometheus

# 7. Add Helm repositories
echo "📚 Adding Helm repositories..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# 8. Deploy Prometheus with Helm
echo "🔍 Deploying Prometheus with Helm..."
helm upgrade --install prometheus prometheus-community/prometheus \
  --namespace prometheus \
  --set alertmanager.persistence.storageClass="gp3-ebs" \
  --set alertmanager.persistence.size="5Gi" \
  --set server.persistentVolume.storageClass="gp3-ebs" \
  --set server.persistentVolume.size="20Gi" \
  --set server.service.type="LoadBalancer" \
  --set alertmanager.service.type="LoadBalancer" \
  --timeout=10m

# 9. Wait for Prometheus to be ready
echo "⏳ Waiting for Prometheus to be ready..."
kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=prometheus -n prometheus --timeout=600s

# 10. Get service information
echo "🌐 Getting service information..."
echo ""
echo "📊 Prometheus Server:"
kubectl get svc -n prometheus prometheus-server -o wide

echo ""
echo "🚨 Alertmanager:"
kubectl get svc -n prometheus prometheus-alertmanager -o wide

echo ""
echo "📋 All pods in prometheus namespace:"
kubectl get pods -n prometheus

echo ""
echo "💾 PVCs status:"
kubectl get pvc -n prometheus

echo ""
echo "🎉 Deployment completed successfully!"
echo ""
echo "📝 To access Prometheus:"
echo "   - Get the LoadBalancer URL for prometheus-server service"
echo "   - Or use port-forward: kubectl port-forward -n prometheus svc/prometheus-server 9090:80"
echo ""
echo "🧹 To clean up everything:"
echo "   eksctl delete cluster --name $CLUSTER_NAME --region $REGION"