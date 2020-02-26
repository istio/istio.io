---
title: Querying Metrics from Prometheus
description: This task shows you how to query for Istio Metrics using Prometheus.
weight: 30
keywords: [telemetry,metrics]
aliases:
    - /docs/tasks/telemetry/querying-metrics/
    - /docs/tasks/telemetry/metrics/querying-metrics/
---

This task shows you how to query for Istio Metrics using Prometheus. As part of
this task, you will use the web-based interface for querying metric values.

The [Bookinfo](/docs/examples/bookinfo/) sample application is used as
the example application throughout this task.

## Before you begin

[Install Istio](/docs/setup/) in your cluster and deploy an
application.

## Querying Istio metrics

1.  Verify that the `prometheus` service is running in your cluster.

    In Kubernetes environments, execute the following command:

    {{< text bash >}}
    $ kubectl -n istio-system get svc prometheus
    NAME         CLUSTER-IP     EXTERNAL-IP   PORT(S)    AGE
    prometheus   10.59.241.54   <none>        9090/TCP   2m
    {{< /text >}}

1.  Send traffic to the mesh.

    For the Bookinfo sample, visit `http://$GATEWAY_URL/productpage` in your web
    browser or issue the following command:

    {{< text bash >}}
    $ curl http://$GATEWAY_URL/productpage
    {{< /text >}}

    {{< tip >}}
    `$GATEWAY_URL` is the value set in the [Bookinfo](/docs/examples/bookinfo/) example.
    {{< /tip >}}

1.  Open the Prometheus UI.

    In Kubernetes environments, execute the following command:

    {{< text bash >}}
    $ istioctl dashboard prometheus
    {{< /text >}}

    Click **Graph** in Prometheus.

1.  Execute a Prometheus query.

    In the "Expression" input box at the top of the web page, enter the text:
    `istio_requests_total`. Then, click the **Execute** button.

The results will be similar to:

{{< image link="./prometheus_query_result.png" caption="Prometheus Query Result" >}}

Other queries to try:

-   Total count of all requests to the `productpage` service:

    {{< text plain >}}
    istio_requests_total{destination_service="productpage.default.svc.cluster.local"}
    {{< /text >}}

- Total count of all requests to `v3` of the `reviews` service:

    {{< text plain >}}
    istio_requests_total{destination_service="reviews.default.svc.cluster.local", destination_version="v3"}
    {{< /text >}}

    This query returns the current total count of all requests to the v3 of the `reviews` service.

-   Rate of requests over the past 5 minutes to all instances of the `productpage` service:

    {{< text plain >}}
    rate(istio_requests_total{destination_service=~"productpage.*", response_code="200"}[5m])
    {{< /text >}}

### About the Prometheus add-on

The Prometheus add-on is a Prometheus server that comes preconfigured to scrape
Istio endpoints to collect metrics. It provides a mechanism for persistent storage and querying
of Istio metrics.

For more on querying Prometheus, please read their [querying
docs](https://prometheus.io/docs/querying/basics/).

## Cleanup

-   Remove any `istioctl` processes that may still be running using control-C or:

    {{< text bash >}}
    $ killall istioctl
    {{< /text >}}

-   If you are not planning to explore any follow-on tasks, refer to the
    [Bookinfo cleanup](/docs/examples/bookinfo/#cleanup) instructions
    to shutdown the application.
