---
title: Collecting Logs
description: This task shows you how to configure Istio to collect and customize logs.
weight: 10
keywords: [telemetry,logs]
aliases:
 - /docs/tasks/telemetry/logs/collecting-logs/
---

This task shows how to configure Istio to automatically gather telemetry for
services in a mesh. At the end of this task, a new log stream will be enabled
for calls to services within your mesh.

The [Bookinfo](/docs/examples/bookinfo/) sample application is used
as the example application throughout this task.

## Before you begin

* [Install Istio](/docs/setup) in your cluster and deploy an
  application. This task assumes that Mixer is setup in a default configuration
  (`--configDefaultNamespace=istio-system`). If you use a different
  value, update the configuration and commands in this task to match the value.

## Collecting new logs data

1.  Apply a YAML file with configuration for the new log
    stream that Istio will generate and collect automatically.

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/telemetry/log-entry.yaml@
    {{< /text >}}

    {{< warning >}}
    If you use Istio 1.1.2 or prior, please use the following configuration instead:

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/telemetry/log-entry-crd.yaml@
    {{< /text >}}

    {{< /warning >}}

1.  Send traffic to the sample application.

    For the Bookinfo sample, visit `http://$GATEWAY_URL/productpage` in your web
    browser or issue the following command:

    {{< text bash >}}
    $ curl http://$GATEWAY_URL/productpage
    {{< /text >}}

1.  Verify that the log stream has been created and is being populated for
    requests.

    In a Kubernetes environment, search through the logs for the `istio-telemetry` pods as
    follows:

    {{< text bash json >}}
    $ kubectl logs -n istio-system -l istio-mixer-type=telemetry -c mixer | grep "newlog" | grep -v '"destination":"telemetry"' | grep -v '"destination":"pilot"' | grep -v '"destination":"policy"' | grep -v '"destination":"unknown"'
    {"level":"warn","time":"2018-09-15T20:46:36.009801Z","instance":"newlog.xxxxx.istio-system","destination":"details","latency":"13.601485ms","responseCode":200,"responseSize":178,"source":"productpage","user":"unknown"}
    {"level":"warn","time":"2018-09-15T20:46:36.026993Z","instance":"newlog.xxxxx.istio-system","destination":"reviews","latency":"919.482857ms","responseCode":200,"responseSize":295,"source":"productpage","user":"unknown"}
    {"level":"warn","time":"2018-09-15T20:46:35.982761Z","instance":"newlog.xxxxx.istio-system","destination":"productpage","latency":"968.030256ms","responseCode":200,"responseSize":4415,"source":"istio-ingressgateway","user":"unknown"}
    {{< /text >}}

## Understanding the logs configuration

In this task, you added Istio configuration that instructed Mixer to
automatically generate and report a new log stream for all
traffic within the mesh.

The added configuration controlled three pieces of Mixer functionality:

1. Generation of *instances* (in this example, log entries)
   from Istio attributes

1. Creation of *handlers* (configured Mixer adapters) capable of processing
   generated *instances*

1. Dispatch of *instances* to *handlers* according to a set of *rules*

The logs configuration directs Mixer to send log entries to stdout. It uses
three stanzas (or blocks) of configuration: *instance* configuration, *handler*
configuration, and *rule* configuration.

The `kind: instance` stanza of configuration defines a schema for generated log entries
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

The `kind: handler` stanza of configuration defines a *handler* named `newloghandler`. The
handler `spec` configures how the `stdio` compiled adapter code processes received
`logentry` instances. The `severity_levels` parameter controls how `logentry`
values for the `severity` field are mapped to supported logging levels. Here,
the value of `"warning"` is mapped to the `WARNING` log level. The
`outputAsJson` parameter directs the adapter to generate JSON-formatted log
lines.

The `kind: rule` stanza of configuration defines a new *rule* named `newlogstdio`. The
rule directs Mixer to send all `newlog` instances to the
`newloghandler` handler. Because the `match` parameter is set to `true`, the
rule is executed for all requests in the mesh.

A `match: true` expression in the rule specification is not required to
configure a rule to be executed for all requests. Omitting the entire `match`
parameter from the `spec` is equivalent to setting `match: true`. It is included
here to illustrate how to use `match` expressions to control rule execution.

## Cleanup

*   Remove the new logs configuration:

    {{< text bash >}}
    $ kubectl delete -f @samples/bookinfo/telemetry/log-entry.yaml@
    {{< /text >}}

    If you are using Istio 1.1.2 or prior:

    {{< text bash >}}
    $ kubectl delete -f @samples/bookinfo/telemetry/log-entry-crd.yaml@
    {{< /text >}}

*   If you are not planning to explore any follow-on tasks, refer to the
    [Bookinfo cleanup](/docs/examples/bookinfo/#cleanup) instructions
    to shutdown the application.
