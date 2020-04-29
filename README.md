# Criação do Cluster AWS EKS (Kubernetes 1.15)
eksctl create cluster

# Deploy do Microserviço que pode aplicar Delays
kubectl apply -f delay-microservice/delay-k8s-dep.yaml

# Deploy do Microgateway para o Microserviço de Delays
kubectl apply -f delay-api-k8s-dep.yaml

# Autoscale para os PODs do Microgateway 
kubectl autoscale deployment.v1.apps/delay-api-deployment --min=1 --max=4 --cpu-percent=80

# Autoscale para os PODs do Microservice
kubectl autoscale deployment.v1.apps/delay-deployment --min=1 --max=4 --cpu-percent=80