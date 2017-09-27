---
title: Rules Configuration
overview: Provides a high-level overview of the domain-specific language used by Istio to configure traffic management rules in the service mesh.

order: 50

layout: docs
type: markdown
---
{% include home.html %}

Istio provides a simple Domain-specific language (DSL) to
control how API calls and layer-4 traffic flow across various
services in the application deployment. The DSL allows the operator to
configure service-level properties such as circuit breakers, timeouts,
retries, as well as set up common continuous deployment tasks such as
canary rollouts, A/B testing, staged rollouts with %-based traffic splits,
etc. See [routing rules reference]({{home}}/docs/reference/config/traffic-rules/) for detailed information.

For example, a simple rule to send 100% of incoming traffic for a "reviews"
service to version "v1" can be described using the Rules DSL as
follows:

```yaml
apiVersion: config.istio.io/v1alpha2
kind: RouteRule
metadata:
  name: reviews-default
spec:
  destination:
    name: reviews
  route:
  - labels:
      version: v1
    weight: 100
```

The destination is the name of the service to which the traffic is being
routed. The route *labels* identify the specific service instances that will
recieve traffic. For example, in a Kubernetes deployment of Istio, the route
*label* "version: v1" indicates that only pods containing the label "version: v1"
will receive traffic.

Rules can be configured using the
[istioctl CLI]({{home}}/docs/reference/commands/istioctl.html), or in a Kubernetes
deployment using the `kubectl` command instead. See the
[configuring request routing task]({{home}}/docs/tasks/request-routing.html) for
examples.

There are three kinds of traffic management rules in Istio: **Route Rules**, **Destination
Policies** (these are not the same as Mixer policies), and **Egress Rules**. All three
kinds of rules control how requests are routed to a destination service.

## Route Rules

Route rules control how requests are routed within an Istio service mesh.
For example, a route rule could route requests to different versions of a service.
Requests can be routed based on the source and destination, HTTP
header fields, and weights associated with individual service versions. The
following important aspects must be kept in mind while writing route rules:

### Qualify rules by destination

Every rule corresponds to some destination service identified by a
*destination* field in the rule. For example, rules that apply to calls
to the "reviews" service will typically include at least the following.

```yaml
destination:
  name: reviews
```

The *destination* value specifies, implicitly or explicitly, a fully qualified
domain name (FQDN). It is used by Istio Pilot for matching rules to services.

Normally, the FQDN of the service is composed from three components: *name*,
*namespace*, and *domain*:

```
FQDN = name + "." + namespace + "." + domain
```

These fields can be explicitly specified as follows.

```yaml
destination:
  name: reviews
  namespace: default
  domain: svc.cluster.local
```

More commonly, to simplify and maximize reuse of the rule (for example, to use
the same rule in more than one namespace or domain), the rule destination
specifies only the *name* field, relying on defaults for the other
two.

The default value for the *namespace* is the namespace of the rule
itself, which can be specified in the *metadata* field of the rule,
or during rule install using the `istioctl -n <namespace> create`
or `kubectl -n <namesapce> create` command.  The default value of
the *domain* field is implementation specific. In Kubernates, for example,
the default value is `svc.cluster.local`.

In some cases, such as when referring to external services in egress rules or
on platforms where *namespace* and *domain* are not meaningful, an alternative
*service* field can be used to explicitly specify the destination:

```yaml
destination:
  service: my-service.com
```

When the *service* field is specified, all other implicit or explicit values of the
other fields are ignored.

### Qualify rules by source/headers

Rules can optionally be qualified to only apply to requests that match some
specific criteria such as the following:

_1. Restrict to a specific caller_.  For example, the following rule only
applies to calls from the "reviews" service.

```yaml
apiVersion: config.istio.io/v1alpha2
kind: RouteRule
metadata:
  name: reviews-to-ratings
spec:
  destination:
    name: ratings
  match:
    source:
      name: reviews
  ...
```

The *source* value, just like *destination*, specifies a FQDN of a service,
either implicitly or explicitly.

_2. Restrict to specific versions of the caller_. For example, the following
rule refines the previous example to only apply to calls from version "v2"
of the "reviews" service.

```yaml
apiVersion: config.istio.io/v1alpha2
kind: RouteRule
metadata:
  name: reviews-v2-to-ratings
spec:
  destination:
    name: ratings
  match:
    source:
      name: reviews
      labels:
        version: v2
  ...
```

_3. Select rule based on HTTP headers_. For example, the following rule will
only apply to an incoming request if it includes a "cookie" header that
contains the substring "user=jason".

```yaml
apiVersion: config.istio.io/v1alpha2
kind: RouteRule
metadata:
  name: ratings-jason
spec:
  destination:
    name: reviews
  match:
    request:
      headers:
        cookie:
          regex: "^(.*?;)?(user=jason)(;.*)?$"
  ...
```

If more than one header is provided, then all of the
corresponding headers must match for the rule to apply.

Multiple criteria can be set simultaneously. In such a case, AND semantics
apply. For example, the following rule only applies if the source of the
request is "reviews:v2" AND the "cookie" header containing "user=jason" is
present.

```yaml
apiVersion: config.istio.io/v1alpha2
kind: RouteRule
metadata:
  name: ratings-reviews-jason
spec:
  destination:
    name: ratings
  match:
    source:
      name: reviews
      labels:
        version: v2
    request:
      headers:
        cookie:
          regex: "^(.*?;)?(user=jason)(;.*)?$"
  ...
```

### Split traffic between service versions

Each route rule identifies one or more weighted backends to call when the rule is activated.
Each backend corresponds to a specific version of the destination service,
where versions can be expressed using _labels_.

If there are multiple registered instances with the specified tag(s),
they will be routed to based on the load balancing policy configured for the service,
or round-robin by default.

For example, the following rule will route 25% of traffic for the "reviews" service to instances with
the "v2" tag and the remaining traffic (i.e., 75%) to "v1".

```yaml
apiVersion: config.istio.io/v1alpha2
kind: RouteRule
metadata:
  name: reviews-v2-rollout
spec:
  destination:
    name: reviews
  route:
  - labels:
      version: v2
    weight: 25
  - labels:
      version: v1
    weight: 75
```

### Timeouts and retries

By default, the timeout for http requests is 15 seconds,
but this can be overridden in a route rule as follows:

```yaml
apiVersion: config.istio.io/v1alpha2
kind: RouteRule
metadata:
  name: ratings-timeout
spec:
  destination:
    name: ratings
  route:
  - labels:
      version: v1
  httpReqTimeout:
    simpleTimeout:
      timeout: 10s
```

The number of retries for a given http request can also be specified in a route rule.
The maximum number of attempts, or as many as possible within the default or overridden timeout period,
can be set as follows:

```yaml
apiVersion: config.istio.io/v1alpha2
kind: RouteRule
metadata:
  name: ratings-retry
spec:
  destination:
    name: ratings
  route:
  - labels:
      version: v1
  httpReqRetries:
    simpleRetry:
      attempts: 3
```

Note that request timeouts and retries can also be
[overridden on a per-request basis](./handling-failures.html#fine-tuning).

See the [request timeouts task]({{home}}/docs/tasks/request-timeouts.html) for a demonstration of timeout control.

### Injecting faults in the request path

A route rule can specify one or more faults to inject
while forwarding http requests to the rule's corresponding request destination.
The faults can be either delays or aborts.

The following example will introduce a 5 second delay in 10% of the requests to the "v1" version of the "reviews" microservice.

```yaml
apiVersion: config.istio.io/v1alpha2
kind: RouteRule
metadata:
  name: ratings-delay
spec:
  destination:
    name: reviews
  route:
  - labels:
      version: v1
  httpFault:
    delay:
      percent: 10
      fixedDelay: 5s
```

The other kind of fault, abort, can be used to prematurely terminate a request,
for example, to simulate a failure.

The following example will return an HTTP 400 error code for 10%
of the requests to the "ratings" service "v1".

```yaml
apiVersion: config.istio.io/v1alpha2
kind: RouteRule
metadata:
  name: ratings-abort
spec:
   destination:
     name: ratings
   route:
   - labels:
       version: v1
   httpFault:
     abort:
       percent: 10
       httpStatus: 400
```

Sometimes delays and abort faults are used together. For example, the following rule will delay
by 5 seconds all requests from the "reviews" service "v2" to the "ratings" service "v1" and
then abort 10 percent of them:

```yaml
apiVersion: config.istio.io/v1alpha2
kind: RouteRule
metadata:
  name: ratings-delay-abort
spec:
  destination:
    name: ratings
  match:
    source:
      name: reviews
      labels:
        version: v2
  route:
  - labels:
      version: v1
  httpFault:
    delay:
      fixedDelay: 5s
    abort:
      percent: 10
      httpStatus: 400
```

To see fault injection in action, see the [fault injection task]({{home}}/docs/tasks/fault-injection.html).

### Rules have precedence

Multiple route rules could be applied to the same destination. The order of
evaluation of rules corresponding to a given destination, when there is
more than one, can be specified by setting the *precedence* field of the
rule.

```yaml
destination:
  name: reviews
precedence: 1
```

The precedence field is an optional integer value, 0 by default.  Rules
with higher precedence values are evaluated first. _If there is more than
one rule with the same precedence value the order of evaluation is
undefined._

**When is precedence useful?** Whenever the routing story for a particular
service is purely weight based, it can be specified in a single rule,
as shown in the earlier example.  When, on the other hand, other criteria
(e.g., requests from a specific user) are being used to route traffic, more
than one rule will be needed to specify the routing.  This is where the
rule *precedence* field must be set to make sure that the rules are
evaluated in the right order.

A common pattern for generalized route specification is to provide one or
more higher priority rules that qualify rules by source/headers to specific
destinations, and then provide a single weight-based rule with no match
criteria at the lowest priority to provide the weighted distribution of
traffic for all other cases.

For example, the following 2 rules, together, specify that all requests for
the "reviews" service that includes a header named "Foo" with the value
"bar" will be sent to the "v2" instances.  All remaining requests will be
sent to "v1".

```yaml
apiVersion: config.istio.io/v1alpha2
kind: RouteRule
metadata:
  name: reviews-foo-bar
spec:
  destination:
    name: reviews
  precedence: 2
  match:
    request:
      headers:
        Foo: bar
  route:
  - labels:
      version: v2
---
apiVersion: config.istio.io/v1alpha2
kind: RouteRule
metadata:
  name: reviews-default
spec:
  destination:
    name: reviews
  precedence: 1
  route:
  - labels:
      version: v1
    weight: 100
```

Notice that the header-based rule has the higher precedence (2 vs. 1). If
it was lower, these rules wouldn't work as expected since the weight-based
rule, with no specific match criteria, would be evaluated first which would
then simply route all traffic to "v1", even requests that include the
matching "Foo" header. Once a rule is found that applies to the incoming
request, it will be executed and the rule-evaluation process will
terminate. That's why it's very important to carefully consider the
priorities of each rule when there is more than one.

## Destination policies

Destination policies describe various routing related policies associated
with a particular service or version, such as the load balancing algorithm,
the configuration of circuit breakers, health checks, etc.

Unlike route rules, destination policies cannot be qualified based on attributes
of a request other than the calling service, but they can be restricted to
apply to requests that are routed to destination backends with specific labels.
For example, the following load balancing policy will only apply to requests
targeting the "v1" version of the "ratings" microservice that are called
from version "v2" of the "reviews" service.

```yaml
apiVersion: config.istio.io/v1alpha2
metadata:
  name: ratings-lb-policy
spec:
  source:
    name: reviews
    labels:
      version: v2
  destination:
    name: ratings
    labels:
      version: v1
  loadBalancing:
    name: ROUND_ROBIN
```

### Circuit breakers

A simple circuit breaker can be set based on a number of criteria such as connection and request limits.

For example, the following destination policy
sets a limit of 100 connections to "reviews" service version "v1" backends.

```yaml
apiVersion: config.istio.io/v1alpha2
metadata:
  name: reviews-v1-cb
spec:
  destination:
    name: reviews
    labels:
      version: v1
  circuitBreaker:
    simpleCb:
       maxConnections: 100
```

The complete set of simple circuit breaker fields can be found
[here]({{home}}/docs/reference/config/traffic-rules/destination-policies.html#istio.proxy.v1.config.CircuitBreaker).

### Destination policy evaluation

Similar to route rules, destination policies are associated with a
particular *destination* however if they also include *labels* their
activation depends on route rule evaluation results.

The first step in the rule evaluation process evaluates the route rules for
a *destination*, if any are defined, to determine the labels (i.e., specific
version) of the destination service that the current request will be routed
to. Next, the set of destination policies, if any, are evaluated to
determine if they apply.

**NOTE:** One subtlety of the algorithm to keep in mind is that policies
that are defined for specific tagged destinations will only be applied if
the corresponding tagged instances are explicitly routed to. For example,
consider the following rule, as the one and only rule defined for the
"reviews" service.

```yaml
apiVersion: config.istio.io/v1alpha2
metadata:
  name: reviews-v1-cb
spec:
  destination:
    name: reviews
    labels:
      version: v1
  circuitBreaker:
    simpleCb:
      maxConnections: 100
```

Since there is no specific route rule defined for the "reviews"
service, default round-robin routing behavior will apply, which will
presumably call "v1" instances on occasion, maybe even always if "v1" is
the only running version. Nevertheless, the above policy will never be
invoked since the default routing is done at a lower level. The rule
evaluation engine will be unaware of the final destination and therefore
unable to match the destination policy to the request.

You can fix the above example in one of two ways. You can either remove the
`labels:` from the rule, if "v1" is the only instance anyway, or, better yet,
define proper route rules for the service. For example, you can add a
simple route rule for "reviews:v1".

```yaml
apiVersion: config.istio.io/v1alpha2
kind: RouteRule
metadata:
  name: reviews-default
spec:
  destination:
    name: reviews
  route:
  - labels:
      version: v1
```

Although the default Istio behavior conveniently sends traffic from all
versions of a source service to all versions of a destination service
without any rules being set, as soon as version discrimination is desired
rules are going to be needed.
Therefore, setting a default rule for every service, right from the
start, is generally considered a best practice in Istio.

## Egress Rules

Egress rules are used to enable requests to services outside of an Istio service mesh.
For example, the following rule can be used to allow external calls to services hosted
under the `*.foo.com` domain.

```yaml
apiVersion: config.istio.io/v1alpha2
kind: EgressRule
metadata:
  name: foo-egress-rule
spec:
  destination:
    service: *.foo.com
  ports:
    - port: 80
      protocol: http
    - port: 443
      protocol: https
```

The destination of an egress rule is specified using the *service* field, which
can be either a fully qualified or wildcard domain name.
It represents a white listed set of one or more external services that services
in the mesh are allowed to access. The supported wildcard syntax can be found
[here]({{home}}/docs/reference/config/traffic-rules/egress-rules.html).

Currently, only HTTP-based services can be expressed using an egress rule, however,
TLS origination from the sidecar can be achieved by setting the protocol of
the associated service port to "https", as shown in the above example.
The service must be accessed over HTTP
(e.g., `http://secure-service.foo.com:443`, instead of `https://secure-service.foo.com`),
however, the sidecar will upgrade the connection to TLS in this case.

Egress rules work well in conjunction with route rules and destination
policies as long as they refer to the external services using the exact same
specification for the destination service as the corresponding egress rule.
For example, the following rule can be used in conjunction with the above egress
rule to set a 10s timeout for calls to the external services.

```yaml
apiVersion: config.istio.io/v1alpha2
kind: RouteRule
metadata:
  name: foo-timeout-rule
spec:
  destination:
    service: *.foo.com
  httpReqTimeout:
    simpleTimeout:
      timeout: 10s
```

Destination policies and route rules to redirect and forward traffic, to define retry,
timeout and fault injection policies are all supported for external destinations.
Weighted (version-based) routing is not possible, however, since there is no notion
of multiple versions of an external service.
