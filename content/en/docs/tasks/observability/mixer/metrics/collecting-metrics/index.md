---
title: Collecting Metrics With Mixer
description: This task shows you how to configure Istio's Mixer to collect and customize metrics.
weight: 10
keywords: [telemetry,metrics]
aliases:
    - /docs/tasks/metrics-logs.html
    - /docs/tasks/telemetry/metrics-logs/
    - /docs/tasks/telemetry/metrics/collecting-metrics/
    - /docs/tasks/observability/metrics/collecting-metrics/
---

{{< warning >}}
Mixer is deprecated. The functionality provided by Mixer is being moved into the Envoy proxies.
Use of Mixer with Istio will only be supported through the 1.7 release of Istio.
{{< /warning>}}

This task shows how to configure Istio to automatically gather telemetry for
services in a mesh. At the end of this task, a new metric will be enabled for
calls to services within your mesh.

The [Bookinfo](/docs/examples/bookinfo/) sample application is used
as the example application throughout this task.

## Before you begin

* [Install Istio](/docs/setup) with Mixer enabled in your cluster and deploy an
  application.

    The *custom* configuration needed to use Mixer for telemetry is:

    {{< text yaml >}}
    values:
      prometheus:
        enabled: true
      telemetry:
        v1:
          enabled: true
        v2:
          enabled: false
    components:
      citadel:
        enabled: true
      telemetry:
        enabled: true
    {{< /text >}}

    Please see the guide on [Customizing the configuration](/docs/setup/install/istioctl/#customizing-the-configuration)
    for information on how to apply these settings.

    Once the configuration has been applied, confirm a telemetry-focused instance of Mixer is running:

    {{< text bash >}}
    $ kubectl -n istio-system get service istio-telemetry
    NAME              TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)                                  AGE
    istio-telemetry   ClusterIP   10.4.31.226   <none>        9091/TCP,15004/TCP,15014/TCP,42422/TCP   80s
    {{< /text >}}

## Collecting new metrics

1.  Apply a YAML file with configuration for the new metric
    that Istio will generate and collect automatically.

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/telemetry/metrics.yaml@
    {{< /text >}}

    {{< warning >}}
    If you use Istio 1.1.2 or prior, please use the following configuration instead:

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/telemetry/metrics-crd.yaml@
    {{< /text >}}

    {{< /warning >}}

1.  Send traffic to the sample application.

    For the Bookinfo sample, visit `http://$GATEWAY_URL/productpage` in your web
    browser or issue the following command:

    {{< text bash >}}
    $ curl http://$GATEWAY_URL/productpage
    {{< /text >}}

1.  Verify that the new metric values are being generated and collected.

    In a Kubernetes environment, setup port-forwarding for Prometheus by
    executing the following command:

    {{< text bash >}}
    $ kubectl -n istio-system port-forward $(kubectl -n istio-system get pod -l app=prometheus -o jsonpath='{.items[0].metadata.name}') 9090:9090 &
    {{< /text >}}

    View values for the new metric in the Prometheus browser window.  Select **Graph**.
    Enter the `istio_double_request_count` metric and select **Execute**.
    The table displayed in the
    **Console** tab includes entries similar to:

    {{< text plain >}}
    istio_double_request_count{destination="details-v1",instance="172.17.0.12:42422",job="istio-mesh",message="twice the fun!",reporter="client",source="productpage-v1"}   8
    istio_double_request_count{destination="details-v1",instance="172.17.0.12:42422",job="istio-mesh",message="twice the fun!",reporter="server",source="productpage-v1"}   8
    istio_double_request_count{destination="istio-policy",instance="172.17.0.12:42422",job="istio-mesh",message="twice the fun!",reporter="server",source="details-v1"}   4
    istio_double_request_count{destination="istio-policy",instance="172.17.0.12:42422",job="istio-mesh",message="twice the fun!",reporter="server",source="istio-ingressgateway"}   4
    {{< /text >}}

    For more on querying Prometheus for metric values, see the
    [Querying Istio Metrics](/docs/tasks/observability/metrics/querying-metrics/) task.

## Understanding the metrics configuration

In this task, you added Istio configuration that instructed Mixer to
automatically generate and report a new metric for all
traffic within the mesh.

The added configuration controlled three pieces of Mixer functionality:

1. Generation of *instances* (in this example, metric values)
   from Istio attributes

1. Creation of *handlers* (configured Mixer adapters) capable of processing
   generated *instances*

1. Dispatch of *instances* to *handlers* according to a set of *rules*

The metrics configuration directs Mixer to send metric values to Prometheus. It
uses three stanzas (or blocks) of configuration: *instance* configuration,
*handler* configuration, and *rule* configuration.

The `kind: instance` stanza of configuration defines a schema for generated metric values
(or *instances*) for a new metric named `doublerequestcount`. This instance
configuration tells Mixer _how_ to generate metric values for any given request,
based on the attributes reported by Envoy (and generated by Mixer itself).

For each instance of `doublerequestcount`, the configuration directs Mixer to
supply a value of `2` for the instance. Because Istio generates an instance for
each request, this means that this metric records a value equal to twice the
total number of requests received.

A set of `dimensions` are specified for each `doublerequestcount`
instance. Dimensions provide a way to slice, aggregate, and analyze metric data
according to different needs and directions of inquiry. For instance, it may be
desirable to only consider requests for a certain destination service when
troubleshooting application behavior.

The configuration instructs Mixer to populate values for these dimensions based
on attribute values and literal values. For instance, for the `source`
dimension, the new configuration requests that the value be taken from the
`source.workload.name` attribute. If that attribute value is not populated, the rule
instructs Mixer to use a default value of `"unknown"`. For the `message`
dimension, a literal value of `"twice the fun!"` will be used for all instances.

The `kind: handler` stanza of configuration defines a *handler* named
`doublehandler`. The handler `spec` configures how the Prometheus adapter code
translates received metric instances into Prometheus-formatted values that can
be processed by a Prometheus backend. This configuration specified a new
Prometheus metric named `double_request_count`. The Prometheus adapter prepends
the `istio_` namespace to all metric names, therefore this metric will show up
in Prometheus as `istio_double_request_count`. The metric has three labels
matching the dimensions configured for `doublerequestcount` instances.

Mixer instances are matched to Prometheus metrics via the `instance_name` parameter.
The `instance_name` values must be the fully-qualified name for Mixer instances (example:
`doublerequestcount.instance.istio-system`).

The `kind: rule` stanza of configuration defines a new *rule* named `doubleprom`. The
rule directs Mixer to send all `doublerequestcount` instances to the
`doublehandler` handler. Because there is no `match` clause in the
rule, and because the rule is in the configured default configuration namespace
(`istio-system`), the rule is executed for all requests in the mesh.

## Cleanup

*   Remove the new metrics configuration:

    {{< text bash >}}
    $ kubectl delete -f @samples/bookinfo/telemetry/metrics.yaml@
    {{< /text >}}

    If you are using Istio 1.1.2 or prior:

    {{< text bash >}}
    $ kubectl delete -f @samples/bookinfo/telemetry/metrics-crd.yaml@
    {{< /text >}}

*   Remove any `kubectl port-forward` processes that may still be running:

    {{< text bash >}}
    $ killall kubectl
    {{< /text >}}

*   If you are not planning to explore any follow-on tasks, refer to the
    [Bookinfo cleanup](/docs/examples/bookinfo/#cleanup) instructions
    to shutdown the application.