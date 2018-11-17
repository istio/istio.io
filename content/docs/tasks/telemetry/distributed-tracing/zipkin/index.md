---
title: Zipkin
description: How to configure the proxies to send tracing requests to Zipkin.
weight: 10
keywords: [telemetry,tracing,zipkin]
aliases:
    - /docs/tasks/zipkin-tracing.html
---

## Before you begin

*   Setup Istio by following the instructions in the [Installation guide](/docs/setup/).

    Use the Helm chart with tracing enabled by setting the `--set tracing.enabled=true` option and
    selecting the zipkin tracing provider using `--set tracing.provider=zipkin`.

* Deploy the [Bookinfo](/docs/examples/bookinfo/) sample application.

## Accessing the dashboard

Setup access to the tracing dashboard by using port-forwarding:

{{< text bash >}}
$ kubectl -n istio-system port-forward $(kubectl -n istio-system get pod -l app=istio-ingressgateway -o jsonpath='{.items[0].metadata.name}') 15032:15032 &
{{< /text >}}

Access the dashboard by opening your browser to [http://localhost:15032](http://localhost:15032).

It is also possible to use a Kubernetes ingress by specifying the Helm chart option `--set tracing.ingress.enabled=true`.

## Generating traces using the Bookinfo sample

With the Bookinfo application up and running, generate trace information by accessing
`http://$GATEWAY_URL/productpage` one or more times.

From the top panel, select a service of interest (or 'all') from the Service Name drop-down list and click
Find Traces. You should see something similar to the following:

{{< image width="100%" ratio="52.68%"
    link="./istio-tracing-list-zipkin.png"
    caption="Tracing Dashboard"
    >}}

If you click on the top (most recent) trace, you should see the details corresponding to your
latest request of the `/productpage` endpoint.
The page should look something like this:

{{< image width="100%" ratio="36.32%"
    link="./istio-tracing-details-zipkin.png"
    caption="Detailed Trace View"
    >}}

As you can see, the trace is comprised of a set of spans,
where each span corresponds to a Bookinfo service invoked during the execution of a `/productpage` request or
internal Istio components (e.g. `istio-ingressgateway`, `istio-mixer`, `istio-policy`).

## Cleanup

*   Remove any `kubectl port-forward` processes that may still be running:

    {{< text bash >}}
    $ killall kubectl
    {{< /text >}}

*   If you are not planning to explore any follow-on tasks, refer to the
    [Bookinfo cleanup](/docs/examples/bookinfo/#cleanup) instructions
    to shutdown the application.

