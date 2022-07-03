#!/usr/bin/env bash
set -e

echo "🚀 Starting E2E test infrastructure!"

echo "➡️ Ensuring minikube, helm and kubectl binaries are installed..."
brew install minikube helm kubectl

echo "➡️ Setting up & starting minikube..."
minikube start --kubernetes-version=v1.22.2

echo "Ensuring kubectl is correct"
minikube kubectl -- get pods -A

echo "Ensuring we're in the right place..."
cd "$(dirname "$0")"

echo "Deleting e2e repo if it exists"
#rm -rf e2e-tests

echo "🧲 Pulling in e2e test repo... if the below command fails you're required to run ps2alerts-init as per the setup instructions."
#git clone git@github.com:ps2alerts/e2e-tests.git e2e-tests

echo "Ensuring helm repos are added"
helm repo add bitnami https://charts.bitnami.com/bitnami

echo "Deleting the testing namespace if it exists... (grab a snickers if this isn't a fresh start of the tests)"
kubectl delete namespace/ps2alerts-tests --ignore-not-found=true

echo "⎈ Deploying infra manifests..."
kubectl apply -f provisioning/namespace-k8s.yaml
kubectl apply -f provisioning/mongo-k8s.yaml
kubectl apply -f provisioning/rabbit-k8s.yaml
kubectl apply -f provisioning/redis-k8s.yaml

set +e
echo "Waiting until all infrastructure pods are ready..."
READY=0
while [[ $READY == 0 ]]
do
  RESULT=$(kubectl get pods -n ps2alerts-tests -o custom-columns="NAMESPACE:metadata.namespace,POD:metadata.name,PodIP:status.podIP,READY:status.containerStatuses[*].ready" | grep true -c)

  if [ "$RESULT" == "3" ]; then
    echo "✅ All infrastructure pods are ready!"
    READY=1
  else
    echo "⌛️ Pods not yet ready ($RESULT/3)... waiting"
    sleep 5
  fi
done

set -e
