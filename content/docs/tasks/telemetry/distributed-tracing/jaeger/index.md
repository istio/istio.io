---
title: Jaeger
description: Learn how to configure the proxies to send tracing requests to Jaeger.
weight: 10
keywords: [telemetry,tracing,jaeger,span,port-forwarding]
---

To learn how Istio handles tracing, visit this task's [overview](../overview/).

## Before you begin

1.  To set up Istio, follow the instructions in the [Installation guide](/docs/setup/kubernetes/install/helm)
    and then configure:

    a) a demo/test environment by setting the `--set tracing.enabled=true`  Helm install option to enable tracing "out of the box"

    b) a production environment by referencing an existing Jaeger instance, e.g. created with the [operator](https://github.com/jaegertracing/jaeger-operator), and then setting the `--set global.tracer.zipkin.address=<jaeger-collector-service>.<jaeger-collector-namespace>:9411` Helm install option.

    {{< warning >}}
    When you enable tracing, you can set the sampling rate that Istio uses for tracing.
    Use the `pilot.traceSampling` option to set the sampling rate. The default sampling rate is 1%.
    {{< /warning >}}

1.  Deploy the [Bookinfo](/docs/examples/bookinfo/#deploying-the-application) sample application.

## Accessing the dashboard

[Remotely Accessing Telemetry Addons](/docs/tasks/telemetry/gateways) details how to configure access to the Istio       addons through a gateway. Alternatively, to use a Kubernetes ingress, specify the Helm chart option `--set tracing.ingress.enabled=true` during install.

For testing (and temporary access), you may also use port-forwarding. Use the following, assuming you've deployed Jaeger to the `istio-control` namespace:

{{< text bash >}}
$ kubectl -n istio-control port-forward $(kubectl -n istio-control get pod -l app=jaeger -o jsonpath='{.items[0].metadata.name}') 15032:16686
{{< /text >}}

Open your browser to [http://localhost:15032](http://localhost:15032).

## Generating traces using the Bookinfo sample

1.  When the Bookinfo application is up and running, access `http://$GATEWAY_URL/productpage` one or more times
    to generate trace information.

    {{< boilerplate trace-generation >}}

1.  From the left-hand pane of the dashboard, select `productpage` from the **Service** drop-down list and click
    **Find Traces**:

    {{< image link="./istio-tracing-list.png" caption="Tracing Dashboard" >}}

1.  Click on the most recent trace at the top to see the details corresponding to the
    latest request to the `/productpage`:

    {{< image link="./istio-tracing-details.png" caption="Detailed Trace View" >}}

1.  The trace is comprised of a set of spans,
    where each span corresponds to a Bookinfo service, invoked during the execution of a `/productpage` request, or
    internal Istio component, for example: `istio-ingressgateway`, `istio-mixer`, `istio-policy`.

## Cleanup

1.  Remove any `kubectl port-forward` processes that may still be running:

    {{< text bash >}}
    $ killall kubectl
    {{< /text >}}

1.  If you are not planning to explore any follow-on tasks, refer to the
    [Bookinfo cleanup](/docs/examples/bookinfo/#cleanup) instructions
    to shutdown the application.

