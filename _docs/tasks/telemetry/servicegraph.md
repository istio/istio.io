---
title: Generating a Service Graph

description: This task shows you how to generate a graph of services within an Istio mesh.

weight: 50

---
{% include home.html %}

This task shows you how to generate a graph of services within an Istio mesh.
As part of this task, you will install the Servicegraph addon and use
the web-based interface for viewing service graph of the service mesh.

The [Bookinfo]({{home}}/docs/guides/bookinfo.html) sample application is used as
the example application throughout this task.

## Before you begin

* [Install Istio]({{home}}/docs/setup/) in your cluster and deploy an
  application.

## Generating a Service Graph

1. To view a graphical representation of your service mesh, install the
   Servicegraph add-on.

   In Kubernetes environments, execute the following command:

   ```bash
   kubectl apply -f install/kubernetes/addons/servicegraph.yaml
   ```

1. Verify that the service is running in your cluster.

   In Kubernetes environments, execute the following command:

   ```bash
   kubectl -n istio-system get svc servicegraph
   ```

   The output will be similar to:

   ```xxx
   NAME           CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
   servicegraph   10.59.253.165   <none>        8088/TCP   30s
   ```

1. Send traffic to the mesh.

   For the Bookinfo sample, visit `http://$GATEWAY_URL/productpage` in your web
   browser or issue the following command:

   ```bash
   curl http://$GATEWAY_URL/productpage
   ```

   Refresh the page a few times (or send the command a few times) to generate a
   small amount of traffic.

   > `$GATEWAY_URL` is the value set in the [Bookinfo]({{home}}/docs/guides/bookinfo.html) guide.

1. Open the Servicegraph UI.

   In Kubernetes environments, execute the following command:

   ```bash
   kubectl -n istio-system port-forward $(kubectl -n istio-system get pod -l app=servicegraph -o jsonpath='{.items[0].metadata.name}') 8088:8088 &
   ```

   Visit [http://localhost:8088/force/forcegraph.html](http://localhost:8088/force/forcegraph.html)
   in your web browser. Try clicking on a service to see details on
   the service. Real time traffic data is shown in a panel below.

   The results will look similar to:

   {% include figure.html width='75%' ratio='107.7%'
    img='./img/servicegraph-example.png'
    alt='Example Servicegraph'
    title='Example Servicegraph'
    caption='Example Servicegraph'
    %}

1. Experiment with Query Parameters

   Visit
   [http://localhost:8088/force/forcegraph.html?time_horizon=15s&filter_empty=true](http://localhost:8088/force/forcegraph.html?time_horizon=15s&filter_empty=true)
   in your web browser. Note the query parameters provided.

   `filter_empty=true` will only show services that are currently receiving traffic within the time horizon.

   `time_horizon=15s` affects the filter above, and also affects the
   reported traffic information when clicking on a service. The
   traffic information will be aggregated over the specified time
   horizon.

   The default behavior is to not filter empty services, and use a
   time horizon of 5 minutes.

### About the Servicegraph Add-on

The [Servicegraph](https://github.com/istio/istio/tree/master/addons/servicegraph)
service provides endpoints for generating and visualizing a graph of
services within a mesh. It exposes the following endpoints:

* `/force/forcegraph.html` As explored above, this is an interactive
  [D3.js](https://d3js.org/) visualization.

* `/dotviz` is a static [Graphviz](https://www.graphviz.org/)
  visualization.

* `/dotgraph` provides a
  [DOT](https://en.wikipedia.org/wiki/DOT_(graph_description_language))
  serialization.

* `/d3graph` provides a JSON serialization for D3 visualization.

* `/graph` provides a generic JSON serialization.

All endpoints take the query parameters explored above.

The Servicegraph example is built on top of Prometheus queries and
depends on the standard Istio metric configuration.

## Cleanup

* In Kubernetes environments, execute the following command to remove the
Servicegraph add-on:

   ```bash
   kubectl delete -f install/kubernetes/addons/servicegraph.yaml
   ```

* If you are not planning to explore any follow-on tasks, refer to the
[Bookinfo cleanup]({{home}}/docs/guides/bookinfo.html#cleanup) instructions
to shutdown the application.
