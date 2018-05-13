---
title: Visualizing Metrics with Grafana

description: This task shows you how to setup and use the Istio Dashboard to monitor mesh traffic.

weight: 40

---
{% include home.html %}

This task shows you how to setup and use the Istio Dashboard to monitor mesh
traffic. As part of this task, you will install the Grafana Istio addon and use
the web-based interface for viewing service mesh traffic data.

The [Bookinfo]({{home}}/docs/guides/bookinfo.html) sample application is used as
the example application throughout this task.

## Before you begin

* [Install Istio]({{home}}/docs/setup/) in your cluster and deploy an
  application.

## Viewing the Istio Dashboard

1. To view Istio metrics in a graphical dashboard install the Grafana add-on.

   In Kubernetes environments, execute the following command:

   ```command
   $ kubectl apply -f install/kubernetes/addons/grafana.yaml
   ```

1. Verify that the service is running in your cluster.

   In Kubernetes environments, execute the following command:

   ```command
   $ kubectl -n istio-system get svc grafana
   NAME      CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
   grafana   10.59.247.103   <none>        3000/TCP   2m
   ```

1. Open the Istio Dashboard via the Grafana UI.

   In Kubernetes environments, execute the following command:

   ```command
   $ kubectl -n istio-system port-forward $(kubectl -n istio-system get pod -l app=grafana -o jsonpath='{.items[0].metadata.name}') 3000:3000 &
   ```

   Visit [http://localhost:3000/dashboard/db/istio-dashboard](http://localhost:3000/dashboard/db/istio-dashboard) in your web browser.

   The Istio Dashboard will look similar to:

   {% include image.html width="100%" ratio="56.57%"
        link="./img/grafana-istio-dashboard.png"
        caption="Istio Dashboard"
        %}

1. Send traffic to the mesh.

   For the Bookinfo sample, visit `http://$GATEWAY_URL/productpage` in your web
   browser or issue the following command:

   ```command
   $ curl http://$GATEWAY_URL/productpage
   ```

   Refresh the page a few times (or send the command a few times) to generate a
   small amount of traffic.

   Look at the Istio Dashboard again. It should reflect the traffic that was
   generated. It will look similar to:

   {% include image.html width="100%" ratio="56.57%"
    link="./img/dashboard-with-traffic.png"
    caption="Istio Dashboard With Traffic"
    %}

   > `$GATEWAY_URL` is the value set in the [Bookinfo]({{home}}/docs/guides/bookinfo.html) guide.

### About the Grafana add-on

The Grafana add-on is a preconfigured instance of Grafana. The base image
([`grafana/grafana:4.1.2`](https://hub.docker.com/r/grafana/grafana/)) has been
modified to start with both a Prometheus data source and the Istio Dashboard
installed. The base install files for Istio, and Mixer in particular, ship with
a default configuration of global (used for every service) metrics. The Istio
Dashboard is built to be used in conjunction with the default Istio metrics
configuration and a Prometheus backend.

The Istio Dashboard consists of three main sections:
1. A Global Summary View. This section provides high-level summary of HTTP
   requests flowing through the service mesh.
1. A Mesh Summary View. This section provides slightly more detail than the
   Global Summary View, allowing per-service filtering and selection.
1. Individual Services View. This section provides metrics about requests and
   responses for each individual service within the mesh (HTTP and TCP).

For more on how to create, configure, and edit dashboards, please see the
[Grafana documentation](https://docs.grafana.org/).

## Cleanup

* In Kubernetes environments, execute the following command to remove the Grafana
add-on:

   ```command
   $ kubectl delete -f install/kubernetes/addons/grafana.yaml
   ```

* Remove any `kubectl port-forward` processes that may be running:

   ```command
   $ killall kubectl
   ```

* If you are not planning to explore any follow-on tasks, refer to the
[Bookinfo cleanup]({{home}}/docs/guides/bookinfo.html#cleanup) instructions
to shutdown the application.
