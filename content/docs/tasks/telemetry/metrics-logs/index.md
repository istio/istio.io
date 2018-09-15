---
title: Collecting Metrics and Logs
description: This task shows you how to configure Istio to collect metrics and logs.
weight: 20
keywords: [telemetry,metrics]
aliases:
    - /docs/tasks/metrics-logs.html
---

This task shows how to configure Istio to automatically gather telemetry for
services in a mesh. At the end of this task, a new metric and a new log stream
will be enabled for calls to services within your mesh.

The [Bookinfo](/docs/examples/bookinfo/) sample application is used
as the example application throughout this task.

## Before you begin

* [Install Istio](/docs/setup/) in your cluster and deploy an
  application. This task assumes that Mixer is setup in a default configuration
  (`--configDefaultNamespace=istio-system`). If you use a different
  value, update the configuration and commands in this task to match the value.

## Collecting new telemetry data

1.  Create a new YAML file to hold configuration for the new metric and log
    stream that Istio will generate and collect automatically.

    Save the following as `new_telemetry.yaml`:

    {{< text yaml >}}
    # Configuration for metric instances
    apiVersion: "config.istio.io/v1alpha2"
    kind: metric
    metadata:
      name: doublerequestcount
      namespace: istio-system
    spec:
      value: "2" # count each request twice
      dimensions:
        reporter: conditional((context.reporter.kind | "inbound") == "outbound", "client", "server")
        source: source.workload.name | "unknown"
        destination: destination.workload.name | "unknown"
        message: '"twice the fun!"'
      monitored_resource_type: '"UNSPECIFIED"'
    ---
    # Configuration for a Prometheus handler
    apiVersion: "config.istio.io/v1alpha2"
    kind: prometheus
    metadata:
      name: doublehandler
      namespace: istio-system
    spec:
      metrics:
      - name: double_request_count # Prometheus metric name
        instance_name: doublerequestcount.metric.istio-system # Mixer instance name (fully-qualified)
        kind: COUNTER
        label_names:
        - reporter
        - source
        - destination
        - message
    ---
    # Rule to send metric instances to a Prometheus handler
    apiVersion: "config.istio.io/v1alpha2"
    kind: rule
    metadata:
      name: doubleprom
      namespace: istio-system
    spec:
      actions:
      - handler: doublehandler.prometheus
        instances:
        - doublerequestcount.metric
    ---
    # Configuration for logentry instances
    apiVersion: "config.istio.io/v1alpha2"
    kind: logentry
    metadata:
      name: newlog
      namespace: istio-system
    spec:
      severity: '"warning"'
      timestamp: request.time
      variables:
        source: source.labels["app"] | source.workload.name | "unknown"
        user: source.user | "unknown"
        destination: destination.labels["app"] | destination.workload.name | "unknown"
        responseCode: response.code | 0
        responseSize: response.size | 0
        latency: response.duration | "0ms"
      monitored_resource_type: '"UNSPECIFIED"'
    ---
    # Configuration for a stdio handler
    apiVersion: "config.istio.io/v1alpha2"
    kind: stdio
    metadata:
      name: newhandler
      namespace: istio-system
    spec:
     severity_levels:
       warning: 1 # Params.Level.WARNING
     outputAsJson: true
    ---
    # Rule to send logentry instances to a stdio handler
    apiVersion: "config.istio.io/v1alpha2"
    kind: rule
    metadata:
      name: newlogstdio
      namespace: istio-system
    spec:
      match: "true" # match for all requests
      actions:
       - handler: newhandler.stdio
         instances:
         - newlog.logentry
    ---
    {{< /text >}}

1.  Push the new configuration.

    {{< text bash >}}
    $ kubectl apply -f new_telemetry.yaml
    Created configuration metric/istio-system/doublerequestcount at revision 1973035
    Created configuration prometheus/istio-system/doublehandler at revision 1973036
    Created configuration rule/istio-system/doubleprom at revision 1973037
    Created configuration logentry/istio-system/newlog at revision 1973038
    Created configuration stdio/istio-system/newhandler at revision 1973039
    Created configuration rule/istio-system/newlogstdio at revision 1973041
    {{< /text >}}

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

    View values for the new metric via the [Prometheus UI](http://localhost:9090/graph#%5B%7B%22range_input%22%3A%221h%22%2C%22expr%22%3A%22istio_double_request_count%22%2C%22tab%22%3A1%7D%5D).

    The provided link opens the Prometheus UI and executes a query for values of
    the `istio_double_request_count` metric. The table displayed in the
    **Console** tab includes entries similar to:

    {{< text plain >}}
    istio_double_request_count{destination="details-v1",instance="172.17.0.12:42422",job="istio-mesh",message="twice the fun!",reporter="client",source="productpage-v1"}   8
    istio_double_request_count{destination="details-v1",instance="172.17.0.12:42422",job="istio-mesh",message="twice the fun!",reporter="server",source="productpage-v1"}   8
    istio_double_request_count{destination="istio-policy",instance="172.17.0.12:42422",job="istio-mesh",message="twice the fun!",reporter="server",source="details-v1"}   4
    istio_double_request_count{destination="istio-policy",instance="172.17.0.12:42422",job="istio-mesh",message="twice the fun!",reporter="server",source="istio-ingressgateway"}   4
    {{< /text >}}

    For more on querying Prometheus for metric values, see the
    [Querying Istio Metrics](/docs/tasks/telemetry/querying-metrics/) task.

1.  Verify that the logs stream has been created and is being populated for
    requests.

    In a Kubernetes environment, search through the logs for the istio-telemetry pods as
    follows:

    {{< text bash json >}}
    $ kubectl logs -n istio-system -l istio-mixer-type=telemetry -c mixer | grep \"instance\":\"newlog.logentry.istio-system\" | grep -v '"destination":"telemetry"' | grep -v '"destination":"pilot"' | grep -v '"destination":"policy"' | grep -v '"destination":"unknown"'
    {"level":"warn","time":"2018-09-15T20:46:36.009801Z","instance":"newlog.logentry.istio-system","destination":"details","latency":"13.601485ms","responseCode":200,"responseSize":178,"source":"productpage","user":"unknown"}
    {"level":"warn","time":"2018-09-15T20:46:36.026993Z","instance":"newlog.logentry.istio-system","destination":"reviews","latency":"919.482857ms","responseCode":200,"responseSize":295,"source":"productpage","user":"unknown"}
    {"level":"warn","time":"2018-09-15T20:46:35.982761Z","instance":"newlog.logentry.istio-system","destination":"productpage","latency":"968.030256ms","responseCode":200,"responseSize":4415,"source":"istio-ingressgateway","user":"unknown"}
    {{< /text >}}

## Understanding the telemetry configuration

In this task, you added Istio configuration that instructed Mixer to
automatically generate and report a new metric and a new log stream for all
traffic within the mesh.

The added configuration controlled three pieces of Mixer functionality:

1. Generation of *instances* (in this example, metric values and log entries)
   from Istio attributes

1. Creation of *handlers* (configured Mixer adapters) capable of processing
   generated *instances*

1. Dispatch of *instances* to *handlers* according to a set of *rules*

### Understanding the metrics configuration

The metrics configuration directs Mixer to send metric values to Prometheus. It
uses three stanzas (or blocks) of configuration: *instance* configuration,
*handler* configuration, and *rule* configuration.

The `kind: metric` stanza of configuration defines a schema for generated metric values
(or *instances*) for a new metric named `doublerequestcount`. This instance
configuration tells Mixer _how_ to generate metric values for any given request,
based on the attributes reported by Envoy (and generated by Mixer itself).

For each instance of `doublerequestcount.metric`, the configuration directs Mixer to
supply a value of `2` for the instance. Because Istio generates an instance for
each request, this means that this metric records a value equal to twice the
total number of requests received.

A set of `dimensions` are specified for each `doublerequestcount.metric`
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

The `kind: prometheus` stanza of configuration defines a *handler* named
`doublehandler`. The handler `spec` configures how the Prometheus adapter code
translates received metric instances into Prometheus-formatted values that can
be processed by a Prometheus backend. This configuration specified a new
Prometheus metric named `double_request_count`. The Prometheus adapter prepends
the `istio_` namespace to all metric names, therefore this metric will show up
in Prometheus as `istio_double_request_count`. The metric has three labels
matching the dimensions configured for `doublerequestcount.metric` instances.

For `kind: prometheus` handlers, Mixer instances are matched to Prometheus
metrics via the `instance_name` parameter. The `instance_name` values must be
the fully-qualified name for Mixer instances (example:
`doublerequestcount.metric.istio-system`).

The `kind: rule` stanza of configuration defines a new *rule* named `doubleprom`. The
rule directs Mixer to send all `doublerequestcount.metric` instances to the
`doublehandler.prometheus` handler. Because there is no `match` clause in the
rule, and because the rule is in the configured default configuration namespace
(`istio-system`), the rule is executed for all requests in the mesh.

### Understanding the logs configuration

The logs configuration directs Mixer to send log entries to stdout. It uses
three stanzas (or blocks) of configuration: *instance* configuration, *handler*
configuration, and *rule* configuration.

The `kind: logentry` stanza of configuration defines a schema for generated log entries
(or *instances*) named `newlog`. This instance configuration tells Mixer _how_
to generate log entries for requests based on the attributes reported by Envoy.

The `severity` parameter is used to indicate the log level for any generated
`logentry`. In this example, a literal value of `"warning"` is used. This value will
be mapped to supported logging levels by a `logentry` *handler*.

The `timestamp` parameter provides time information for all log entries. In this
example, the time is provided by the attribute value of `request.time`, as
provided by Envoy.

The `variables` parameter allows operators to configure what values should be
included in each `logentry`. A set of expressions controls the mapping from Istio
attributes and literal values into the values that constitute a `logentry`.
In this example, each `logentry` instance has a field named `latency` populated
with the value from the attribute `response.duration`. If there is no known
value for `response.duration`, the `latency` field will be set to a duration of
`0ms`.

The `kind: stdio` stanza of configuration defines a *handler* named `newhandler`. The
handler `spec` configures how the `stdio` adapter code processes received
`logentry` instances. The `severity_levels` parameter controls how `logentry`
values for the `severity` field are mapped to supported logging levels. Here,
the value of `"warning"` is mapped to the `WARNING` log level. The
`outputAsJson` parameter directs the adapter to generate JSON-formatted log
lines.

The `kind: rule` stanza of configuration defines a new *rule* named `newlogstdio`. The
rule directs Mixer to send all `newlog.logentry` instances to the
`newhandler.stdio` handler. Because the `match` parameter is set to `true`, the
rule is executed for all requests in the mesh.

A `match: true` expression in the rule specification is not required to
configure a rule to be executed for all requests. Omitting the entire `match`
parameter from the `spec` is equivalent to setting `match: true`. It is included
here to illustrate how to use `match` expressions to control rule execution.

## Cleanup

*   Remove the new telemetry configuration:

    {{< text bash >}}
    $ kubectl delete -f new_telemetry.yaml
    {{< /text >}}

*   Remove any `kubectl port-forward` processes that may still be running:

    {{< text bash >}}
    $ killall kubectl
    {{< /text >}}

* If you are not planning to explore any follow-on tasks, refer to the
  [Bookinfo cleanup](/docs/examples/bookinfo/#cleanup) instructions
  to shutdown the application.
