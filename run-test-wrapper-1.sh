#!/bin/bash

# Create cluster
eksctl create cluster -f cluster-config/prometheus-load-test-3.yaml

# Install metrics-server for CPU, memory metrics (useful with k9s)
kubectl create ns metrics-server
helm install -n metrics-server metrics-server metrics-server/metrics-server

# Run receiver-mock
kubectl apply -f https://raw.githubusercontent.com/SumoLogic/sumologic-kubernetes-collection/v2.1.6/vagrant/k8s/receiver-mock.yaml

# Install kube-prometheus-stack v16
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm create ns kps
helm install -n kps prometheus-community/kube-prometheus-stack --version 16.15.0

# Run collection - wrapper chart
git clone git@github.com:SumoLogic-Incubator/k8s-helm-chart-wrapper.git
kubectl create ns sumo
(cd k8s-helm-chart-wrapper/ && helm dependency update)
helm install -n sumo collection k8s-helm-chart-wrapper --values values-wrapper.yaml

# Run many pods (or use Frank's script for cronjobs)
kubectl apply -f Deployment10000.yaml

# Delete pods periodically
while true; do sleep 60; date; kubectl delete pods --selector=app=deployment1; done

# Observe Prometheus
kubectl port-forward -n sumo prometheus-col-kube-prometheus-stack-prometheus-0 9090 9090
# container_memory_working_set_bytes{pod="prometheus-collection-kube-prometheus-prometheus-0",container="prometheus"}
