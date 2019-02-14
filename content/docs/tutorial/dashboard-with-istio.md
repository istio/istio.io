---
title: Dashboard with Istio
overview: Adding a Grafana dashboard for Istio.

weight: 140

---
In this module, we will add a [Grafana](https://grafana.com) dashboard on top of our Prometheus instance.

1. Deploy a Grafana instance:
  {{< text bash >}}
  kubectl apply -f install/kubernetes/addons/grafana.yaml
  {{< /text >}}
2. Check the pods at `istio-system` namespace and wait for the Grafana's pod to start running:
  {{< text bash >}}
  kubectl get pods -n istio-system
  {{< /text >}}
2. Perform port forwarding from the Grafana instance to the local machine:
  {{< text bash >}}
  kubectl -n istio-system port-forward $(kubectl -n istio-system get pod -l app=grafana -o jsonpath='{.items[0].metadata.name}') 3000:3000 &
  {{< /text >}}

3. Access the dashboard on local machine:  [http://localhost:3000/dashboard/db/istio-dashboard](http://localhost:3000/dashboard/db/istio-dashboard)
