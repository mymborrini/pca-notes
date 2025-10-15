# Prometheus and k8s

I'm going to use minikube as a k8s server

## Helm Installation

The prometheus community helm repo is going to contain all of the prometheus related helm charts which one of them we're going to
use to set up the kube. The chart that we are going to use is the `kube-prometheus-stack`

    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo update
    helm install prometheus prometheus-community/kube-prometheus-stack --version 45.7.1 --namespace monitoring --create-namespace

By doing so we are installing 4 components:
- Prometheus Operator
- Node Exporter
- Kube State Metrics
- Grafana

The prometheus operator is crucial because allows us to create 
- Prometheus Instance
- AlertManager

Node Exporter and Kube State metrics work together to extract infrastructure related metrics from the k8s platform itself and automatically
set up to persist all of that data into Prometheus so right there we get infrastructure monitoring out of the box. We also get grafana 
for free.

Now we have to customize of course our release especially Grafana. Since we install operators we can easy define grafana datasource and dashboards
like shown in `./local-environment/minikube/promethues-stack`

First we download the prometheus stack values

     helm show values prometheus-community/kube-prometheus-stack > prometheus-values.yaml


## Infrastructure Monitoring

Prometheus relies on exporters to extract metrics from particular targets. 
- The Node exporter is designed to scrape metrics system level from k8s nodes like CPU, memory usage, disk utilization 
- We have Kube State Metrics which returns the health availability of all our kubernetes object

Since we have installed all through a prometheus-stack the prometheus instance already know how to fetch the data from this exporter.
First let's expose our prometheus ui

    kubectl port-forward -n monitoring svc/prometheus-operated 10000:9090
    kubectl port-forward -n monitoring svc/prometheus-grafana 10001:80

And from the browser 

    http://localhost:10000
    http://localhost:10001

For example, we can check the prometheus ui and the grafana ui. We can check the grafana ui password from the helm `prometheus-values.yaml` we downloaded
before. In our case the password is `prom-operator`. In the dashboard folder we can see how grafana already preconfigured a lot of dashboard where we can check all the information we 
need


## Application Monitoring

