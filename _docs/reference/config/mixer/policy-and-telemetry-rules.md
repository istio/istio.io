---
title: Policy and Telemetry Rules
overview: Describes the rules used to configure Mixer policy and telemetry.

order: 40

layout: docs
type: markdown
---
{% include home.html %}


<a name="rpcIstio.mixer.v1.configIndex"></a>
### Index

* [Rule](#istio.mixer.v1.config.Rule)
(message)
* [Action](#istio.mixer.v1.config.Action)
(message)
* [Handler](#istio.mixer.v1.config.Handler)
(message)
* [Instance](#istio.mixer.v1.config.Instance)
(message)

<a name="istio.mixer.v1.config.Rule"></a>
### Rule
A Rule is a selector and a set of intentions to be executed when the
selector evaluates to `true`.

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="istio.mixer.v1.config.Rule.match"></a>
 <tr>
  <td><code>match</code></td>
  <td>string</td>
  <td><p>Required. Match is an attribute based predicate. When Mixer receives a request it evaluates the match expression and executes all the associated <code>actions</code> if the match evaluates to true.</p><p>A few example match:</p>
<ul>
  <li>an empty match evaluates to <code>true</code></li>
  <li><code>true</code>, a boolean literal; a rule with this match will always be executed</li>
  <li><code>destination.service == ratings*</code> selects any request targeting a service whose name starts with "ratings"</li>
  <li><code>attr1 == &quot;20&quot; &amp;&amp; attr2 == &quot;30&quot;</code> logical AND, OR, and NOT are also available</li>
</ul></td>
 </tr>
<a name="istio.mixer.v1.config.Rule.actions"></a>
 <tr>
  <td><code>actions[]</code></td>
  <td>repeated <a href="#istio.mixer.v1.config.Action">Action</a></td>
  <td>Optional. The actions that will be executed when match evaluates to <code>true</code>.</td>
 </tr>
</table>

The following example instructs Mixer to invoke 'handler.prometheus' handler for
all services and pass it the instance constructed using the
`RequestCount` metric instance.


```yaml
apiVersion: "config.istio.io/v1alpha2"
kind: rule
metadata:
  name: promcount
  namespace: istio-system
spec:
- match: destination.service == "*"
  actions:
  - handler: handler.prometheus
    instances:
    - RequestCount.metric
```

#### Custom Resource Definition

```yaml
kind: CustomResourceDefinition
apiVersion: apiextensions.k8s.io/v1beta1
metadata:
  name: rules.config.istio.io
  labels:
    package: istio.io.mixer
    istio: core
spec:
  group: config.istio.io
  names:
    kind: rule
    plural: rules
    singular: rule
  scope: Namespaced
  version: v1alpha2
```

<a name="istio.mixer.v1.config.Action"></a>
### Action
Action describes which [Handler](#istio.mixer.v1.config.Handler) to invoke and
what data to pass to it for processing.

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="istio.mixer.v1.config.Action.handler"></a>
 <tr>
  <td><code>handler</code></td>
  <td>string</td>
  <td>Required. Fully qualified name of the handler to invoke. Must match the <code>name</code> of a <a href="#istio.mixer.v1.config.Handler">Handler</a>.</td>
 </tr>
<a name="istio.mixer.v1.config.Action.instances"></a>
 <tr>
  <td><code>instances[]</code></td>
  <td>repeated string</td>
  <td>Required. Each value must match the fully qualified name of the <a href="#istio.mixer.v1.config.Instance">Instance</a>s. Referenced instances are evaluated by resolving the attributes/literals for all the fields. The constructed objects are then passed to the <code>handler</code> referenced within this action.</td>
 </tr>
</table>

The following example instructs Mixer to invoke the `handler.prometheus` handler
and pass it the instance constructed using the `RequestCount` metric instance.


```yaml
  handler: handler.prometheus
  instances:
  - RequestCount.metric
```

<a name="istio.mixer.v1.config.Handler"></a>
### Handler
Handler allows the operator to configure a specific adapter implementation.

In the following example we define a `prometheus` handler using the Mixer's
prepackaged [prometheus
adapter]({{home}}/docs/reference/config/mixer/adapters/prometheus.html). Here,
we define how the handler should generate prometheus metrics from the metric
instances provided by Mixer.


```yaml
apiVersion: "config.istio.io/v1alpha2"
kind: prometheus
metadata:
  name: handler
  namespace: istio-system
spec:
  metrics:
  - name: request_count
    instance_name: RequestCount.metric.istio-system
    kind: COUNTER
    label_names:
    - source_service
    - source_version
    - destination_service
    - destination_version
    - response_code
```

<a name="istio.mixer.v1.config.Instance"></a>
### Instance
A Instance tells Mixer how to create values for particular template.

Instance is defined by the operator. Instance is defined relative to a known
template. Their purpose is to tell Mixer how to use attributes or literals to
produce values for the specified template at runtime.

The following example instructs Mixer to construct an instance associated with
[metric template]({{home}}/docs/reference/config/mixer/template/metric.html). It
provides a mapping from the template's fields to expressions. Instances produced
with this instance configuration can be referenced by
[Actions](#istio.mixer.v1.config.Action) using name `RequestCount`.


```yaml
apiVersion: "config.istio.io/v1alpha2"
kind: metric
metadata:
  name: RequestCount
  namespace: istio-system
spec:
  value: "1"
  dimensions:
    source_service: source.service | "unknown"
    source_version: source.labels["version"] | "unknown"
    destination_service: destination.service | "unknown"
    destination_version: destination.labels["version"] | "unknown"
    response_code: response.code | 200
  monitored_resource_type: '"UNSPECIFIED"'
```