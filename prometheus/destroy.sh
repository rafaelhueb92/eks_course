CLUSTER_NAME="prometheus-cluster"
POLICY_NAME="$CLUSTER_NAME-policy"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

eksctl delete cluster --name $CLUSTER_NAME
aws iam delete-policy --policy-arn arn:aws:iam::$ACCOUNT_ID:policy/$POLICY_NAME
