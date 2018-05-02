---
title: Mixer Configuration
description: An overview of the key concepts used to configure Mixer.

weight: 30

---
{% include home.html %}

This page describes Mixer's configuration model.

## Background

Istio is a sophisticated system with hundreds of independent features. An Istio deployment can be a sprawling
affair potentially involving dozens of services, with a swarm of Envoy proxies and Mixer instances to
support them. In large deployments, many different operators, each with different scopes and areas of responsibility,
may be involved in managing the overall deployment.

Mixer's configuration model makes it possible to exploit all of its capabilities and flexibility, while
remaining relatively simple to use. The model's scoping features enable large
support organizations to collectively manage complex deployments with ease. Some of the model's key
features include:

- **Designed for Operators**. Service operators control all operational and policy
aspects of a Mixer deployment by manipulating configuration resources.

- **Flexible**. The configuration model is built around Istio's [attributes](./attributes.html),
enabling operators unprecedented control over the policies used and telemetry produced within a deployment.

- **Robust**. The configuration model is designed to provide maximum static correctness guarantees to help reduce
the potential for bad configuration changes leading to service outages.

- **Extensible**. The model is designed to support Istio's overall extensibility story. New or custom
[adapters](./mixer.html#adapters)
can be added to Istio and be fully manipulated using the same general mechanisms as existing adapters.

## Concepts

Mixer is an attribute processing machine. Requests arrive at Mixer with a set of [*attributes*](./attributes.html),
and based on these attributes, Mixer generates calls to a variety of infrastructure backends.
A rate limit system, an ACL provider, and a policy enforcer are examples of infrastructure backends.
The set of attributes determines which backend Mixer calls for a given request and what parameters
each is given. In order to hide the details of individual backends, Mixer uses modules
known as [*adapters*](./mixer.html#adapters).

{% include figure.html width='60%' ratio='42.60%'
    img='./img/mixer-config/machine.svg'
    alt='Attribute Machine'
    title='Attribute Machine'
    caption='Attribute Machine'
    %}

Mixer's configuration has the following central responsibilities:

- Describe which adapters are being used and how they operate.
- Describe how to map request attributes into adapter inputs.
- Describe when a particular adapter is called with specific inputs.

Configuration is based on  *adapters* and *templates*.

- **Adapters** encapsulate the logic necessary to interface Mixer with a specific infrastructure backend.
- **Templates** define the schema for specifying request mapping from attributes to adapter inputs.
A given adapter may support any number of templates.

Configuration is expressed using a YAML format built around the following abstractions:

|Concept                     |Description
|----------------------------|-----------
|[Handlers](#handlers)       | A handler is a configured instance of an adapter. The adapter constructor parameters are specified as handler configuration.
|[Instances](#instances)     | A (request) instance is the result of applying request attributes to the template mapping. The mapping is specified as an instance configuration.
|[Rules](#rules)             | A rule defines when a particular handler is invoked using a specific template configuration.

Configuration resources are expressed in Kubernetes resource syntax:
```yaml
apiVersion: config.istio.io/v1alpha2
kind: rule, adapter kind, or template kind
metadata:
  name: shortname
  namespace: istio-system
spec:
  # kind specific configuration.
```
- **apiVersion** - A constant for an Istio release.
- **kind** - A Mixer assigned unique "kind" for every adapter and template.
- **name** - The configuration resource name.
- **namespace** - The namespace in which the configuration resource is applicable.
- **spec** - The `kind`-specific configuration.

### Handlers

[Adapters](./mixer.html#adapters) encapsulate the logic necessary to interface Mixer with specific external infrastructure
backends such as [Prometheus](https://prometheus.io), [New Relic](https://newrelic.com), or [Stackdriver](https://cloud.google.com/logging).
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
adapters and their specific configuration formats can be found [here]({{home}}/docs/reference/config/adapters/).

### Instances

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

Each template defines its own particular format of configuration data. The exhaustive set of
templates and their specific configuration formats can be found [here]({{home}}/docs/reference/config/template/).

### Rules

Rules specify when a particular handler is invoked with a specific instance configuration.
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

The match predicate is an attribute expression, which are explained below.

### Attribute expressions

Mixer features a number of independent [request processing phases](./mixer.html#request-phases).
The *Attribute Processing* phase is responsible for ingesting a set of attributes and producing template instances
necessary to invoke individual adapters. The phase operates by evaluating a series of *attribute expressions*.

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

The attributes that can be used in attribute expressions must be defined in an
[*attribute manifest*](#manifests) for the deployment. Within the manifest, each attribute has
a type which represents the kind of data that the attribute carries. In the
same way, attribute expressions are also typed, and their type is derived from
the attributes in the expression and the operators applied to these attributes.

Refer to the [attribute expression reference]({{home}}/docs/reference/config/mixer/expression-language.html) for details.

### Resolution

When a request arrives, Mixer goes through a number of [request processing phases](./mixer.html#request-phases).
The Resolution phase is concerned with identifying the configuration resources to use in order to
process the incoming request. For example, a request arriving at Mixer for service A likely has some configuration differences
with requests arriving for service B. Resolution is about deciding which config resources to use for a request.

Resolution depends on a well-known attribute to guide its choice, called the *identity attribute*.
The default identity attribute is `destination.service`.
The mesh-wide configuration is stored in the `configDefaultNamespace` whose default value is `istio-system`.

Mixer goes through the following steps to arrive at the set of `actions`.

1. Extract the value of the identity attribute from the request.

1. Extract the service namespace from the identity attribute.

1. Evaluate the `match` predicate for all rules in the `configDefaultNamespace` and the service namespace.

The actions resulting from these steps are performed by Mixer.

### Manifests

Manifests capture invariants about the components involved in a particular Istio deployment. The only
kind of manifest supported at the moment are *attribute manifests* which are used to define the exact
set of attributes produced by individual components. Manifests are supplied by component producers
and inserted into a deployment's configuration.

Here's part of the manifest for the Istio proxy:

```yaml
manifests:
  - name: istio-proxy
    revision: "1"
    attributes:
      source.name:
        valueType: STRING
        description: The name of the source.
      destination.name:
        valueType: STRING
        description: The name of the destination
      source.ip:
        valueType: IP_ADDRESS
        description: Did you know that descriptions are optional?
      origin.user:
        valueType: STRING
      request.time:
        valueType: TIMESTAMP
      request.method:
        valueType: STRING
      response.code:
        valueType: INT64
```

## Examples

You can find fully-formed examples of Mixer configuration by visiting the
[Guides]({{home}}/docs/guides). Here is some [example
configuration](https://github.com/istio/istio/blob/master/mixer/testdata/config).

## What's next

-Read the [blog post]({{home}}/blog/mixer-adapter-model.html) describing Mixer's adapter model.
