echo "Creating default EKS Cluster"

# Creating by manifest
eksctl create cluster --config-file=../manifests/eksctl-create-cluster.yaml

# You can create via CLI
# eksctl create cluster --name eksctl-test --nodegroup-name ng-default --node-type t3.micro --nodes 2
