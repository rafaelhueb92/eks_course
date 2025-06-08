####### HPA 
# Everything is based on this documentation: 
# https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale-walkthrough/

# Install Metrics Server 
# Doc.:
# https://github.com/kubernetes-sigs/metrics-server#deployment
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/high-availability-1.21+.yaml
##########################################################