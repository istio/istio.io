---
title: Jaeger
description: How to configure the proxies to send tracing requests to Jaeger.
weight: 10
keywords: [telemetry,tracing,jaeger]
---

## Before you begin

*   Setup Istio by following the instructions in the [Installation guide](/docs/setup/).

    Either use the `istio-demo.yaml` or `istio-demo-auth.yaml` template, which includes tracing support, or
    use the Helm chart with tracing enabled by setting the `--set tracing.enabled=true` option.

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

From the left-hand pane of the dashboard, select `productpage` from the Service drop-down list and click
Find Traces. You should see something similar to the following:

{{< image width="100%" ratio="52.68%"
    link="./istio-tracing-list.png"
    caption="Tracing Dashboard"
    >}}

If you click on the top (most recent) trace, you should see the details corresponding to your
latest refresh of the `/productpage`.
The page should look something like this:

{{< image width="100%" ratio="36.32%"
    link="./istio-tracing-details.png"
    caption="Detailed Trace View"
    >}}

As you can see, the trace is comprised of a set of spans,
where each span corresponds to a Bookinfo service invoked during the execution of a `/productpage` request.

Every RPC is represented by two spans in the trace. For example, the call from `productpage` to `reviews` starts
with the span labeled `productpage reviews.default.svc.cluster.local:9080/`, which represents the client-side
span for the call. It took 24.13ms . The second span (labeled `reviews reviews.default.svc.cluster.local:9080/`)
is a child of the first span and represents the server-side span for the call. It took 22.99ms .

The trace for the call to the `reviews` services reveals two subsequent RPC's in the trace. The first is to the `istio-policy`
service, reflecting the server-side Check call made for the service to authorize access. The second is the call out to
the `ratings` service.

## Cleanup

*   Remove any `kubectl port-forward` processes that may still be running:

    {{< text bash >}}
    $ killall kubectl
    {{< /text >}}

*   If you are not planning to explore any follow-on tasks, refer to the
    [Bookinfo cleanup](/docs/examples/bookinfo/#cleanup) instructions
    to shutdown the application.

