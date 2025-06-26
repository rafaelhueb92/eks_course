#!/bin/bash

set -euo pipefail
CLUSTER_NAME=$1
REGION=$2
POLICY_NAME="$CLUSTER_NAME-policy"

echo "Creating IAM Policy for EBS CSI Driver..."

# Create policy JSON
cat > /tmp/ebs-csi-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateVolume",
        "ec2:DeleteVolume",
        "ec2:AttachVolume",
        "ec2:DetachVolume",
        "ec2:ModifyVolume",
        "ec2:DescribeAvailabilityZones",
        "ec2:DescribeInstances",
        "ec2:DescribeSnapshots",
        "ec2:DescribeVolumes",
        "ec2:DescribeVolumeAttribute",
        "ec2:DescribeVolumeStatus",
        "ec2:CreateTags"
      ],
      "Resource": "*"
    }
  ]
}
EOF

cat /tmp/ebs-csi-policy.json

# Creatting policy
POLICY_ARN=$(aws iam create-policy \
    --policy-name "${POLICY_NAME}" \
    --policy-document file:///tmp/ebs-csi-policy.json \
    --description "Policy for EBS CSI Driver" \
    --query 'Policy.Arn' --output text 2>/dev/null || true)

echo "Creating IRSA for EBS CSI Driver..."
echo "Policy arn $POLICY_ARN"

# Creatting IRSA
eksctl create iamserviceaccount \
    --cluster="${CLUSTER_NAME}" \
    --region="${REGION}" \
    --name="ebs-csi-controller-sa" \
    --namespace="kube-system" \
    --attach-policy-arn=$POLICY_ARN \
    --override-existing-serviceaccounts \
    --approve

echo "Installing EBS CSI Driver add-on..."

# Get Role ARN
ROLE_ARN=$(eksctl get iamserviceaccount --cluster="${CLUSTER_NAME}" --region="${REGION}" --name="ebs-csi-controller-sa" --namespace="kube-system" -o json | jq -r '.[0].status.roleARN')

# Install add-on
aws eks create-addon \
    --cluster-name="${CLUSTER_NAME}" \
    --addon-name="aws-ebs-csi-driver" \
    --service-account-role-arn="${ROLE_ARN}" \
    --region="${REGION}" \
    --resolve-conflicts="OVERWRITE" || echo "Add-on já existe"

# Cleanup
rm -f /tmp/ebs-csi-policy.json

echo "Successful! Wait some minutes and try create the PVCs again."