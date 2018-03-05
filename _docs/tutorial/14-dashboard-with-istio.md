---
title: Dashboard with Istio
overview: Adding a Grafana dashboard for Istio

order: 14

layout: docs
type: markdown
---
{% include home.html %}
In this step, we will add a [Grafana](https://grafana.com) dashboard on top of our Prometheus instance.

1. Deploy a Graphana instance:
  ```bash
  kubectl apply -f ../../istio-*/install/kubernetes/addons/grafana.yaml
  ```
2. Check the pods at istio-system namespaces and wait for the pod of Graphana to start running:
  ```bash
  kubectl get pods -n istio-system
  ```
2. Perform port forwarding from the Graphana instance to the local machine:
  ```bash
  kubectl -n istio-system port-forward $(kubectl -n istio-system get pod -l app=grafana -o jsonpath='{.items[0].metadata.name}') 3000:3000 &
  ```

3. Access the dashboard on local machine:  http://localhost:3000/dashboard/db/istio-dashboard

{% include what-is-next-footer.md %}
