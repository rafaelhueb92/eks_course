echo "creating node group with config file manifest"

eksctl create nodegroup --config-file=../manifests/eksctl-create-ng.yaml
