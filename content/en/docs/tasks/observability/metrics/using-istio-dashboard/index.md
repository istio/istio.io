---
title: Visualizing Metrics with Grafana
description: This task shows you how to setup and use the Istio Dashboard to monitor mesh traffic.
weight: 40
keywords: [telemetry,visualization]
aliases:
    - /docs/tasks/telemetry/using-istio-dashboard/
    - /docs/tasks/telemetry/metrics/using-istio-dashboard/
owner: istio/wg-policies-and-telemetry-maintainers
test: no
---

This task shows you how to setup and use the Istio Dashboard to monitor mesh
traffic. As part of this task, you will use the Grafana Istio addon and
the web-based interface for viewing service mesh traffic data.

The [Bookinfo](/docs/examples/bookinfo/) sample application is used as
the example application throughout this task.

## Before you begin

* [Install Istio](/docs/setup) in your cluster.
* Install the [Grafana Addon](/docs/ops/integrations/grafana/#option-1-quick-start).
* Install the [Prometheus Addon](/docs/ops/integrations/prometheus/#option-1-quick-start).
* Deploy the [Bookinfo](/docs/examples/bookinfo/) application.

## Viewing the Istio dashboard

1.  Verify that the `prometheus` service is running in your cluster.

    In Kubernetes environments, execute the following command:

    {{< text bash >}}
    $ kubectl -n istio-system get svc prometheus
    NAME         TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
    prometheus   ClusterIP   10.100.250.202   <none>        9090/TCP   103s
    {{< /text >}}

1.  Verify that the Grafana service is running in your cluster.

    In Kubernetes environments, execute the following command:

    {{< text bash >}}
    $ kubectl -n istio-system get svc grafana
    NAME      TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
    grafana   ClusterIP   10.103.244.103   <none>        3000/TCP   2m25s
    {{< /text >}}

1.  Open the Istio Dashboard via the Grafana UI.

    In Kubernetes environments, execute the following command:

    {{< text bash >}}
    $ istioctl dashboard grafana
    {{< /text >}}

    Visit [http://localhost:3000/dashboard/db/istio-mesh-dashboard](http://localhost:3000/dashboard/db/istio-mesh-dashboard) in your web browser.

    The Istio Dashboard will look similar to:

    {{< image link="./grafana-istio-dashboard.png" caption="Istio Dashboard" >}}

1.  Send traffic to the mesh.

    For the Bookinfo sample, visit `http://$GATEWAY_URL/productpage` in your web
    browser or issue the following command:

    {{< text bash >}}
    $ curl http://$GATEWAY_URL/productpage
    {{< /text >}}

    {{< tip >}}
    `$GATEWAY_URL` is the value set in the [Bookinfo](/docs/examples/bookinfo/) example.
    {{< /tip >}}

    Refresh the page a few times (or send the command a few times) to generate a
    small amount of traffic.

    Look at the Istio Dashboard again. It should reflect the traffic that was
    generated. It will look similar to:

    {{< image link="./dashboard-with-traffic.png" caption="Istio Dashboard With Traffic" >}}

    This gives the global view of the Mesh along with services and workloads in the mesh.
    You can get more details about services and workloads by navigating to their specific dashboards as explained below.

1.  Visualize Service Dashboards.

    From the Grafana dashboard's left hand corner navigation menu, you can navigate to Istio Service Dashboard or visit
    [http://localhost:3000/dashboard/db/istio-service-dashboard](http://localhost:3000/dashboard/db/istio-service-dashboard) in your web browser.

    {{< tip >}}
    You may need to select a service in the Service dropdown.
    {{< /tip >}}

    The Istio Service Dashboard will look similar to:

    {{< image link="./istio-service-dashboard.png" caption="Istio Service Dashboard" >}}

    This gives details about metrics for the service and then client workloads (workloads that are calling this service)
    and service workloads (workloads that are providing this service) for that service.

1.  Visualize Workload Dashboards.

    From the Grafana dashboard's left hand corner navigation menu, you can navigate to Istio Workload Dashboard or visit
    [http://localhost:3000/dashboard/db/istio-workload-dashboard](http://localhost:3000/dashboard/db/istio-workload-dashboard) in your web browser.

    The Istio Workload Dashboard will look similar to:

    {{< image link="./istio-workload-dashboard.png" caption="Istio Workload Dashboard" >}}

    This gives details about metrics for each workload and then inbound workloads (workloads that are sending request to
    this workload) and outbound services (services to which this workload send requests) for that workload.

### About the Grafana dashboards

The Istio Dashboard consists of three main sections:

1. A Mesh Summary View. This section provides Global Summary view of the Mesh and shows HTTP/gRPC and TCP
   workloads in the Mesh.

1. Individual Services View. This section provides metrics about requests and
   responses for each individual service within the mesh (HTTP/gRPC and TCP).
   This also provides metrics about client and service workloads for this service.

1. Individual Workloads View: This section provides metrics about requests and
   responses for each individual workload within the mesh (HTTP/gRPC and TCP).
   This also provides metrics about inbound workloads and outbound services for this workload.

For more on how to create, configure, and edit dashboards, please see the
[Grafana documentation](https://docs.grafana.org/).

## Cleanup

*   Remove any `kubectl port-forward` processes that may be running:

    {{< text bash >}}
    $ killall kubectl
    {{< /text >}}

* If you are not planning to explore any follow-on tasks, refer to the
[Bookinfo cleanup](/docs/examples/bookinfo/#cleanup) instructions
to shutdown the application.
