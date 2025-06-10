####### HPA 
# Everything is based on this documentation: 
# https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale-walkthrough/

# Install Metrics Server 
# Doc.:
# https://github.com/kubernetes-sigs/metrics-server#deployment
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/high-availability-1.21+.yaml
##########################################################

######## Cluster AutoScaler

eksctl create cluster --name my-cluster --version 1.33 --managed --asg-access

kubectl apply -f https://raw.githubusercontent.com/kubernetes/autoscaler/refs/heads/master/cluster-autoscaler/cloudprovider/aws/examples/cluster-autoscaler-autodiscover.yaml

kubectl -n kube-system annotate deployment.apps/cluster-autoscaler cluster-autoscaler.kubernetes.io/safe-to-evict="false"

kubectl -n kube-system edit deployment.apps/cluster-autoscaler

kubectl -n kube-system set image deployment.apps/cluster-autoscaler cluster-autoscaler=k8s.gcr.io/cluster-autoscaler:v1.15.6

kubectl -n kube-system logs -f deployment.apps/cluster-autoscaler

###########################