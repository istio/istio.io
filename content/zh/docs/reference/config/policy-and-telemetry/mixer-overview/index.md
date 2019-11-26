---
title: Mixer Configuration Model 
description: Describes the configuration model for Istio's policy enforcement and telemetry mechanisms.
weight: 5
keywords: [policies,telemetry,control,config]
aliases:
    - /zh/docs/concepts/policy-and-control/mixer.html
    - /zh/docs/concepts/policy-and-control/mixer-config.html
    - /zh/docs/concepts/policy-and-control/attributes.html
    - /zh/docs/concepts/policies-and-telemetry/overview/
    - /zh/docs/concepts/policies-and-telemetry/config/
---

Istio provides a flexible model to enforce authorization policies and collect telemetry for the
services in a mesh.

Infrastructure backends are designed to provide support functionality
used to build services. They include such things as access control systems,
telemetry capturing systems, quota enforcement systems, billing systems, and so
forth. Services traditionally directly integrate with these backend systems,
creating a hard coupling and baking-in specific semantics and usage options.

Istio provides a uniform abstraction that makes it possible for Istio to interface with
an open-ended set of infrastructure backends. This is done in such a way to provide rich
and deep controls to the operator, while imposing no burden on service developers.
Istio is designed to change the boundaries between layers in order to reduce
systemic complexity, eliminate policy logic from service code and give
control to operators.

Mixer is the Istio component responsible for providing policy controls and telemetry collection:

{{< image width="55%" link="./topology-without-cache.svg" caption="Mixer Topology" >}}

The Envoy sidecar logically calls Mixer before each request to perform precondition checks, and after each request to report telemetry.
The sidecar has local caching such that a large percentage of precondition checks can be performed from cache. Additionally, the
sidecar buffers outgoing telemetry such that it only calls Mixer infrequently.

At a high level, Mixer provides:

* **Backend Abstraction**. Mixer insulates the rest of Istio from the implementation details of individual infrastructure backends.

* **Intermediation**. Mixer allows operators to have fine-grained control over all interactions between the mesh and infrastructure backends.

Policy enforcement and telemetry collection are entirely driven from configuration.
Policy check is disabled by default, avoiding the need to go through the Mixer policy component.
Refer to [Installation Options](/zh/docs/reference/config/installation-options/) for more information.

## Adapters

Mixer is a highly modular and extensible component. One of its key functions is
to abstract away the details of different policy and telemetry backend systems,
allowing the rest of Istio to be agnostic of those backends.

Mixer's flexibility in dealing with different infrastructure backends comes
from its general-purpose plug-in model. Individual plug-ins are
known as *adapters* and they allow Mixer to interface to different
infrastructure backends that deliver core functionality, such as logging,
monitoring, quotas, ACL checking, and more. The exact set of
adapters used at runtime is determined through configuration and can easily be
extended to target new or custom infrastructure backends.

{{< image width="80%" link="./adapters.svg"
    alt="Showing Mixer with adapters."
    caption="Mixer and its Adapters"
    >}}

Learn more about the [set of supported adapters](/zh/docs/reference/config/policy-and-telemetry/adapters/).

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

{{< text plain >}}
request.path: xyz/abc
request.size: 234
request.time: 12:34:56.789 04/17/2017
source.ip: [192 168 0 1]
destination.service.name: example
{{< /text >}}

Mixer is in essence an attribute processing machine. The Envoy sidecar invokes Mixer for
every request, giving Mixer a set of attributes that describe the request and the environment
around the request. Based on its configuration and the specific set of attributes it was
given, Mixer generates calls to a variety of infrastructure backends.

{{< image width="60%" link="./machine.svg" caption="Attribute Machine" >}}

### Attribute vocabulary

A given Istio deployment has a fixed vocabulary of attributes that it understands.
The specific vocabulary is determined by the set of attribute producers being used
in the deployment. The primary attribute producer in Istio is Envoy, although
specialized Mixer adapters can also generate attributes.

Learn more about the [common baseline set of attributes available in most Istio deployments](/zh/docs/reference/config/policy-and-telemetry/attribute-vocabulary/).

### Attribute expressions

Attribute expressions are used when configuring [instances](#instances).
Here's an example use of expressions:

{{< text yaml >}}
destination_service: destination.service.host
response_code: response.code
destination_version: destination.labels["version"] | "unknown"
{{< /text >}}

The sequences on the right-hand side of the colons are the simplest forms of attribute expressions.
The first two only consist of attribute names. The `response_code` label is assigned the value from the `response.code` attribute.

Here's an example of a conditional expression:

{{< text yaml >}}
destination_version: destination.labels["version"] | "unknown"
{{< /text >}}

With the above, the `destination_version` label is assigned the value of `destination.labels["version"]`. However if that attribute
is not present, the literal `"unknown"` is used.

Refer to the [attribute expression](/zh/docs/reference/config/policy-and-telemetry/expression-language/) page for details.

## Configuration model

Istio's policy and telemetry features are configured through a common model designed to
put operators in control of every aspect of authorization policy and telemetry collection.
Specific focus was given to keeping the model simple, while being powerful
enough to control Istio's many features at scale.

Controlling the policy and telemetry features involves configuring three types of resources:

* Configuring a set of *handlers*, which determine the set of adapters that
are being used and how they operate. Providing a `statsd` adapter with the IP
address for a Statsd backend is an example of handler configuration.

* Configuring a set of *instances*, which describe how to map request attributes into adapter inputs.
Instances represent a chunk of data that one or more adapters will operate
on. For example, an operator may decide to generate `requestcount`
metric instances from attributes such as `destination.service.host` and
`response.code`.

* Configuring a set of *rules*, which describe when a particular adapter is called and which instances
it is given. Rules consist of a *match* expression and *actions*. The match expression controls
when to invoke an adapter, while the actions determine the set of instances to give the adapter.
For example, a rule might send generated `requestcount` metric instances to a `statsd` adapter.

Configuration is based on *adapters* and *templates*:

* **Adapters** encapsulate the logic necessary to interface Mixer with a specific infrastructure backend.

* **Templates** define the schema for specifying request mapping from attributes to adapter inputs.
A given adapter may support any number of templates.

### Handlers

Adapters encapsulate the logic necessary to interface Mixer with specific external infrastructure
backends such as [Prometheus](https://prometheus.io) or [Stackdriver](https://cloud.google.com/logging).
A _handler_ is a resource responsible for holding the configuration state needed by an adapter. For example, a
logging adapter may require the IP address and port of the log collection backend.

Here is an example showing how to create a handler for an adapter. The `listchecker` adapter checks an input value against a list.
If the adapter is configured for a whitelist, it returns success if the input value is found in the list.

{{< text yaml >}}
apiVersion: config.istio.io/v1alpha2
kind: handler
metadata:
  name: staticversion
  namespace: istio-system
spec:
  compiledAdapter: listchecker
  params:
    providerUrl: http://white_list_registry/
    blacklist: false
{{< /text >}}

The schema of the data in the `params` stanza depends on the specific adapter being configured.

Some adapters implement functionality that goes beyond connecting Mixer to a backend.
For example, the `prometheus` adapter consumes metrics and aggregates them as distributions or counters in a configurable way.

{{< text yaml >}}
apiVersion: config.istio.io/v1alpha2
kind: handler
metadata:
  name: promhandler
  namespace: istio-system
spec:
  compiledAdapter: prometheus
  params:
    metrics:
    - name: request_count
      instance_name: requestcount.instance.istio-system
      kind: COUNTER
      label_names:
      - destination_service
      - destination_version
      - response_code
    - name: request_duration
      instance_name: requestduration.instance.istio-system
      kind: DISTRIBUTION
      label_names:
      - destination_service
      - destination_version
      - response_code
      buckets:
        explicit_buckets:
          bounds: [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10]
{{< /text >}}

Each adapter defines its own particular format of configuration data. Learn more about [the full set of
adapters and their specific configuration formats](/zh/docs/reference/config/policy-and-telemetry/adapters/).

### Instances

Instance configuration specifies the request mapping from attributes to adapter inputs.
The following is an example of a metric instance configuration that produces the `requestduration` metric.

{{< text yaml >}}
apiVersion: config.istio.io/v1alpha2
kind: instance
metadata:
  name: requestduration
  namespace: istio-system
spec:
  compiledTemplate: metric
  params:
    value: response.duration | "0ms"
    dimensions:
      destination_service: destination.service.host | "unknown"
      destination_version: destination.labels["version"] | "unknown"
      response_code: response.code | 200
    monitored_resource_type: '"UNSPECIFIED"'
{{< /text >}}

Note that all the dimensions expected in the handler configuration are specified in the mapping.
Templates define the specific required content of individual instances. Learn more about the [set of
templates and their specific configuration formats](/zh/docs/reference/config/policy-and-telemetry/templates/).

### Rules

Rules specify when a particular handler is invoked with a specific instance.
Consider an example where you want to deliver the `requestduration` metric to the `prometheus` handler if
the destination service is `service1` and the `x-user` request header has a specific value.

{{< text yaml >}}
apiVersion: config.istio.io/v1alpha2
kind: rule
metadata:
  name: promhttp
  namespace: istio-system
spec:
  match: destination.service.host == "service1.ns.svc.cluster.local" && request.headers["x-user"] == "user1"
  actions:
  - handler: promhandler
    instances: [ requestduration ]
{{< /text >}}

A rule contains a `match` predicate expression and a list of actions to perform if the predicate is true.
An action specifies the list of instances to be delivered to a handler.
A rule must use the fully qualified names of handlers and instances.
If the rule, handlers, and instances are all in the same namespace, the namespace suffix can be elided from
the fully qualified name as seen in `promhandler`.
