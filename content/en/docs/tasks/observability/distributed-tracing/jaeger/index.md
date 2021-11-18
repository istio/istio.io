---
title: Jaeger
description: Learn how to configure the proxies to send tracing requests to Jaeger.
weight: 10
keywords: [telemetry,tracing,jaeger,span,port-forwarding]
aliases:
 - /docs/tasks/telemetry/distributed-tracing/jaeger/
owner: istio/wg-policies-and-telemetry-maintainers
test: yes
---

After completing this task, you understand how to have your application participate in tracing with [Jaeger](https://www.jaegertracing.io/),
regardless of the language, framework, or platform you use to build your application.

This task uses the [Bookinfo](/docs/examples/bookinfo/) sample as the example application.

To learn how Istio handles tracing, visit this task's [overview](../overview/).

## Before you begin

1.  Follow the [Jaeger installation](/docs/ops/integrations/jaeger/#installation) documentation to deploy Jaeger into your cluster.

1.  When you enable tracing, you can set the sampling rate that Istio uses for tracing.
    Use the `meshConfig.defaultConfig.tracing.sampling` option during installation to
    [set the sampling rate](/docs/tasks/observability/distributed-tracing/mesh-and-proxy-config/#customizing-trace-sampling).
    The default sampling rate is 1%.

1.  Deploy the [Bookinfo](/docs/examples/bookinfo/#deploying-the-application) sample application.

## Accessing the dashboard

[Remotely Accessing Telemetry Addons](/docs/tasks/observability/gateways) details how to configure access to the Istio addons through a gateway.

For testing (and temporary access), you may also use port-forwarding. Use the following, assuming you've deployed Jaeger to the `istio-system` namespace:

{{< text bash >}}
$ istioctl dashboard jaeger
{{< /text >}}

## Generating traces using the Bookinfo sample

1.  When the Bookinfo application is up and running, access `http://$GATEWAY_URL/productpage` one or more times
    to generate trace information.

    {{< boilerplate trace-generation >}}

1.  From the left-hand pane of the dashboard, select `productpage.default` from the **Service** drop-down list and click
    **Find Traces**:

    {{< image link="./istio-tracing-list.png" caption="Tracing Dashboard" >}}

1.  Click on the most recent trace at the top to see the details corresponding to the
    latest request to the `/productpage`:

    {{< image link="./istio-tracing-details.png" caption="Detailed Trace View" >}}

1.  The trace is comprised of a set of spans,
    where each span corresponds to a Bookinfo service, invoked during the execution of a `/productpage` request, or
    internal Istio component, for example: `istio-ingressgateway`.

## Cleanup

1.  Remove any `istioctl` processes that may still be running using control-C or:

    {{< text bash >}}
    $ killall istioctl
    {{< /text >}}

1.  If you are not planning to explore any follow-on tasks, refer to the
    [Bookinfo cleanup](/docs/examples/bookinfo/#cleanup) instructions
    to shutdown the application.
