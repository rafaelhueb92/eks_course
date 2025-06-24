# Install EBS-CSI-DRIVER

# aws eks describe-addon-versions --addon-name aws-ebs-csi-driver

# observability-cluster

eksctl create iamserviceaccount \
  --name ebs-csi-controller-sa \
  --namespace kube-system \
  --cluster observability-cluster \
  --attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
  --approve \
  --region us-east-1

# no IAM OIDC provider associated with cluster, try 
eksctl utils associate-iam-oidc-provider --region=us-east-1 --cluster=observability-cluster --approve

eksctl create addon \
  --name aws-ebs-csi-driver \
  --cluster observability-cluster \
  --region us-east-1 \
  --service-account-role-arn $(eksctl get iamserviceaccount -c observability-cluster -o json | jq -r '.[].status.roleARN')

eksctl utils migrate-to-pod-identity --cluster observability-cluster --approve