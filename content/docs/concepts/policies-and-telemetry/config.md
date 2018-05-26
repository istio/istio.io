---
title: Configuration
description: An overview of the key concepts used to configure Istio's policy enforcement and telemetry collection features.
weight: 30
aliases:
    - /docs/concepts/policy-and-control/mixer-config.html
    - /docs/concepts/policy-and-control/attributes.html
---

Istio's policy and telemetry features are configured through a common model designed to
put operators in control of every aspect of authorization policy and telemetry collection.
Specific focus was given to keeping the model as simple and possible, while being powerful
enough to control Istio's many features at scale.

## Attributes

Attributes are an essential concept to Istio's policy and telemetry functionality.
An attribute is a small bit of data that describes a single property of a specific
service request or the environment for the request. For example, an attribute can
specify the size of a specific request, the response code for an operation, the IP
address where a request came from, etc.

Each attribute has a name and a type. The type defines the kind of data that the attribute holds. For
example, an attribute can have a `STRING` type which means it has a textual value, or it can have an `INT64`
type indicating it has a 64 bit integer value.

Here are some example attributes with their associated values:

```plain
request.path: xyz/abc
request.size: 234
request.time: 12:34:56.789 04/17/2017
source.ip: 192.168.0.1
destination.service: example
```

Mixer is the Istio component that implements policy and telemetry functionality.
Mixer is in essence an attribute processing machine. The Envoy sidecar invokes Mixer for
every request, giving Mixer a set of attributes that describe the request and the environment
around the request. Based on its configuration and the specific set of attributes it was
given, Mixer generates calls to a variety of infrastructure backends.

{{< image width="60%" ratio="42.60%"
    link="../img/machine.svg"
    caption="Attribute Machine"
    >}}

### Attribute vocabulary

A given Istio deployment has a fixed vocabulary of attributes that it understands.
The specific vocabulary is determined by the set of attribute producers being used
in the deployment. The primary attribute producer in Istio is Envoy, although
specialized Mixer adapters can also generate attributes.

The common baseline set of attributes available in most Istio deployments is defined
[here](/docs/reference/config/policy-and-telemetry/attribute-vocabulary/).

## Configuration model

Controlling the policy and telemetry features involves configuring three types of resources:

- Configuring a set of *handlers*, which determine the set of adapters that
are being used and how they operate. Providing a `statsd` adapter with the IP
address for a statsd backend is an example of handler configuration.

- Configuring a set of *instances*, which describe how to map request attributes into adapter inputs.
Instances represent a chunk of data that one or more adapters will operate
on. For example, an operator may decide to generate `requestcount`
metric instances from attributes such as `destination.service` and
`response.code`.

- Configuring a set of *rules*, which describe when a particular adapter is called and which instances
it is given. Rules consist of a *match* expression and *actions*. The match expression controls
when to invoke an adapter, while the actions determine the set of instances to give to the adapter.
For example, a rule might send generated `requestcount` metric instances to a `statsd` adapter.

Configuration is based on *adapters* and *templates*:

- **Adapters** encapsulate the logic necessary to interface Mixer with a specific infrastructure backend.
- **Templates** define the schema for specifying request mapping from attributes to adapter inputs.
A given adapter may support any number of templates.

## Handlers

Adapters encapsulate the logic necessary to interface Mixer with specific external infrastructure
backends such as [Prometheus](https://prometheus.io) or [Stackdriver](https://cloud.google.com/logging).
Individual adapters generally need operational parameters in order to do their work. For example, a logging adapter may require
the IP address and port of the log sink.

Here is an example showing how to configure an adapter of kind = `listchecker`. The listchecker adapter checks an input value against a list.
If the adapter is configured for a whitelist, it returns success if the input value is found in the list.

```yaml
apiVersion: config.istio.io/v1alpha2
kind: listchecker
metadata:
  name: staticversion
  namespace: istio-system
spec:
  providerUrl: http://white_list_registry/
  blacklist: false
```

`{metadata.name}.{kind}.{metadata.namespace}` is the fully qualified name of a handler. The fully qualified name of the above handler is
`staticversion.listchecker.istio-system` and it must be unique.
The schema of the data in the `spec` stanza depends on the specific adapter being configured.

Some adapters implement functionality that goes beyond connecting Mixer to a backend.
For example, the `prometheus` adapter consumes metrics and aggregates them as distributions or counters in a configurable way.

```yaml
apiVersion: config.istio.io/v1alpha2
kind: prometheus
metadata:
  name: handler
  namespace: istio-system
spec:
  metrics:
  - name: request_count
    instance_name: requestcount.metric.istio-system
    kind: COUNTER
    label_names:
    - destination_service
    - destination_version
    - response_code
  - name: request_duration
    instance_name: requestduration.metric.istio-system
    kind: DISTRIBUTION
    label_names:
    - destination_service
    - destination_version
    - response_code
    buckets:
      explicit_buckets:
        bounds: [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10]
```

Each adapter defines its own particular format of configuration data. The exhaustive set of
adapters and their specific configuration formats can be found [here](/docs/reference/config/policy-and-telemetry/adapters/).

## Instances

Instance configuration specifies the request mapping from attributes to adapter inputs.
The following is an example of a metric instance configuration that produces the `requestduration` metric.

```yaml
apiVersion: config.istio.io/v1alpha2
kind: metric
metadata:
  name: requestduration
  namespace: istio-system
spec:
  value: response.duration | "0ms"
  dimensions:
    destination_service: destination.service | "unknown"
    destination_version: destination.labels["version"] | "unknown"
    response_code: response.code | 200
  monitored_resource_type: '"UNSPECIFIED"'
```
Note that all the dimensions expected in the handler configuration are specified in the mapping.
Templates define the specific required content of individual instances. The exhaustive set of
templates and their specific configuration formats can be found [here](/docs/reference/config/policy-and-telemetry/templates/).

## Rules

Rules specify when a particular handler is invoked with a specific instance.
Consider an example where you want to deliver the `requestduration` metric to the prometheus handler if
the destination service is `service1` and the `x-user` request header has a specific value.

```yaml
apiVersion: config.istio.io/v1alpha2
kind: rule
metadata:
  name: promhttp
  namespace: istio-system
spec:
  match: destination.service == "service1.ns.svc.cluster.local" && request.headers["x-user"] == "user1"
  actions:
  - handler: handler.prometheus
    instances:
    - requestduration.metric.istio-system
```
A rule contains a `match` predicate expression and a list of actions to perform if the predicate is true.
An action specifies the list of instances to be delivered to a handler.
A rule must use the fully qualified names of handlers and instances.
If the rule, handlers, and instances are all in the same namespace, the namespace suffix can be elided from the fully qualified name as seen in `handler.prometheus`.

## Attribute expressions

Attribute expressions are used when configuring instances.
You have already seen a few simple attribute expressions in the previous examples:

```yaml
destination_service: destination.service
response_code: response.code
destination_version: destination.labels["version"] | "unknown"
```
The sequences on the right-hand side of the colons are the simplest forms of attribute expressions.
The first two only consist of attribute names. The `response_code` label is assigned the value from the `request.code` attribute.

Here's an example of a conditional expression:

```yaml
destination_version: destination.labels["version"] | "unknown"
```

With the above, the `destination_version` label is assigned the value of `destination.labels["version"]`. However if that attribute
is not present, the literal `"unknown"` is used.

Refer to the [attribute expression reference](/docs/reference/config/policy-and-telemetry/expression-language/) for details.

## What's next

- Learn how to [configure telemetry collection](/docs/tasks/telemetry/).

- Learn how to [configure policy enforcement](/docs/tasks/policy-enforcement/).

- Learn about the set of [supported adapters](/docs/reference/config/policy-and-telemetry/adapters/).

- See the blog post describing [Mixer's adapter model](/blog/2017/adapter-model/).
