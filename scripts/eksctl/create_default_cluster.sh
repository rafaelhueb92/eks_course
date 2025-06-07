echo "Creating default EKS Cluster"

eksctl create cluster --name eksctl-test --nodegroup-name ng-default --node-type t3.micro --nodes 2
