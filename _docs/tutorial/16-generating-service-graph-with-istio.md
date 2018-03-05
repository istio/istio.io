---
title: A service graph with Istio
overview: Enable service graph generation

order: 16

layout: docs
type: markdown
---
{% include home.html %}
In this step, we will add service graph generation on top of Prometheus.

1. Deploy a service graph generation instance:
  ```bash
  kubectl apply -f install/kubernetes/addons/servicegraph.yaml
  ```
2. Check the pods at istio-system namespaces and wait for the pod of Zipkin to start running:
  ```bash
  kubectl get pods -n istio-system
  ```
2. Perform port forwarding from the service graph generation instance to the local machine:
  ```bash
  kubectl -n istio-system port-forward $(kubectl -n istio-system get pod -l app=servicegraph -o jsonpath='{.items[0].metadata.name}') 8088:8088 &   

  ```

3. Access the generated service graph on the local machine:  http://localhost:8088/dotviz

{% include what-is-next-footer.md %}
