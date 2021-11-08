#!/bin/bash

# Create cluster
eksctl create cluster -f cluster-config/prometheus-load-test-1.yaml

# Install metrics-server for CPU, memory metrics (useful with k9s)
kubectl create ns metrics-server
helm install -n metrics-server metrics-server metrics-server/metrics-server

# Run receiver-mock
kubectl apply -f https://raw.githubusercontent.com/SumoLogic/sumologic-kubernetes-collection/v2.1.6/vagrant/k8s/receiver-mock.yaml

kubectl logs -n receiver-mock receiver-mock

# Run collection
kubectl create ns sumo
helm install -n sumo collection sumologic/sumologic --version 2.1.6 --values values.yaml

# Run many pods
kubectl apply -f Deployment96.yaml

# Delete pods periodically
while true; do sleep 60; date; kubectl delete pods --selector=app=deployment1; done

# Observe Prometheus memory usage
kubectl port-forward -n sumo prometheus-col-kube-prometheus-stack-prometheus-0 9090 9090
# container_memory_working_set_bytes{pod="prometheus-collection-kube-prometheus-prometheus-0",container="prometheus"}
