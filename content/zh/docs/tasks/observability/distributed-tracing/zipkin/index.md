---
title: Zipkin
description: Learn how to configure the proxies to send tracing requests to Zipkin.
weight: 10
keywords: [telemetry,tracing,zipkin,span,port-forwarding]
aliases:
    - /docs/tasks/zipkin-tracing.html
---

After completing this task, you understand how to have your application participate in tracing with [Zipkin](https://zipkin.apache.org/),
regardless of the language, framework, or platform you use to build your application.

This task uses the [Bookinfo](/docs/examples/bookinfo/) sample as the example application.

To learn how Istio handles tracing, visit this task's [overview](../overview/).

## Before you begin

1.  To set up Istio, follow the instructions in the [Installation guide](/docs/setup/install/istioctl)
    and then configure:

    a) a demo/test environment by setting the `--set values.tracing.enabled=true` and `--set values.tracing.provider=zipkin` install options to enable tracing "out of the box"

    b) a production environment by referencing an existing Zipkin instance and then setting the `--set values.global.tracer.zipkin.address=<zipkin-collector-service>.<zipkin-collector-namespace>:9411` install option.

    {{< warning >}}
    When you enable tracing, you can set the sampling rate that Istio uses for tracing.
    Use the `pilot.traceSampling` option to set the sampling rate. The default sampling rate is 1%.
    {{< /warning >}}

1.  Deploy the [Bookinfo](/docs/examples/bookinfo/#deploying-the-application) sample application.

## Accessing the dashboard

[Remotely Accessing Telemetry Addons](/docs/tasks/observability/gateways) details how to configure access to the Istio addons through a gateway. Alternatively, to use a Kubernetes ingress, specify the option `--set values.tracing.ingress.enabled=true` during install.

For testing (and temporary access), you may also use port-forwarding. Use the following, assuming you've deployed Zipkin to the `istio-system` namespace:

{{< text bash >}}
$ kubectl -n istio-system port-forward $(kubectl -n istio-system get pod -l app=zipkin -o jsonpath='{.items[0].metadata.name}') 15032:9411
{{< /text >}}

Open your browser to [http://localhost:15032](http://localhost:15032).

## Generating traces using the Bookinfo sample

1.  When the Bookinfo application is up and running, access `http://$GATEWAY_URL/productpage` one or more times
    to generate trace information.

    {{< boilerplate trace-generation >}}

1.  From the top panel, select a service of interest (or 'all') from the **Service Name** drop-down list and click
    **Find Traces**:

    {{< image link="./istio-tracing-list-zipkin.png" caption="Tracing Dashboard" >}}

1.  Click on the most recent trace at the top to see the details corresponding to the
    latest request to the `/productpage`:

    {{< image link="./istio-tracing-details-zipkin.png" caption="Detailed Trace View" >}}

1.  The trace is comprised of a set of spans,
    where each span corresponds to a Bookinfo service, invoked during the execution of a `/productpage` request, or
    internal Istio component, for example: `istio-ingressgateway`.

## Cleanup

1.  Remove any `kubectl port-forward` processes that may still be running:

    {{< text bash >}}
    $ killall kubectl
    {{< /text >}}

1.  If you are not planning to explore any follow-on tasks, refer to the
    [Bookinfo cleanup](/docs/examples/bookinfo/#cleanup) instructions
    to shutdown the application.

