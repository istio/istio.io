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
etc. See [routing rules reference]({{home}}/docs/reference/api/traffic-rules/index.html) for detailed information.

For example, a simple rule to send 100% of incoming traffic for a "reviews"
service to version "v1" can be described using the Rules DSL as
follows:

```yaml
destination: reviews.default.svc.cluster.local
route:
- tags:
    version: v1
  weight: 100
```

The destination is the name of the service to which the traffic is being
routed. In a Kubernetes deployment of Istio, the route *tag* "version: v1"
corresponds to a Kubernetes *label* "version: v1".  The rule ensures that
only Kubernetes pods containing the label "version: v1" will receive
traffic. Rules can be configured using the
[istioctl CLI]({{home}}/docs/reference/commands/istioctl.html). See the
[configuring request routing task]({{home}}/docs/tasks/request-routing.html) for
examples.

There are two types of rules in Istio, **Routes** and **Destination
Policies** (these are not the same as Mixer policies). Both types of rules
control how requests are routed to a destination service.

## Routes

Routes control how requests are routed to different versions of a
service. Requests can be routed based on the source and destination, HTTP
header fields, and weights associated with individal service versions. The
following important aspects must be keep in mind while writing route rules:

### Qualify rules by destination

Every rule corresponds to some destination service identified by a
*destination* field in the rule. For example, all rules that apply to calls
to the "reviews" service will include the following field.

```yaml
destination: reviews.default.svc.cluster.local
```

The *destination* value SHOULD be a fully qualified domain name (FQDN). It
is used by Istio-Manager for matching rules to services. For example,
in Kubernetes, a fully qualified domain name for a service can be
constructed using the following format: *serviceName.namespace.dnsSuffix*.

### Qualify rules by source/headers

Rules can optionally be qualified to only apply to requests that match some
specific criteria such as the following:

_1. Restrict to a specific caller_.  For example, the following rule only
apply to calls from the "reviews" service.

```yaml
destination: ratings.default.svc.cluster.local
match:
  source: reviews.default.svc.cluster.local
```

The *source* value, just like *destination*, MUST be a FQDN of a service.

_2. Restrict to specific versions of the caller_. For example, the following
rule refines the previous example to only apply to calls from version "v2"
of the "reviews" service.

```yaml
destination: ratings.default.svc.cluster.local
match:
  source: reviews.default.svc.cluster.local
  sourceTags:
    version: v2
```

_3. Select rule based on HTTP headers_. For example, the following rule will
only apply to an incoming request if it includes a "cookie" header that
contains the substring "user=jason".

```yaml
destination: reviews.default.svc.cluster.local
match:
  httpHeaders:
    cookie:
      regex: "^(.*?;)?(user=jason)(;.*)?$"
```

If more than one property-value pair is provided, then all of the
corresponding headers must match for the rule to apply.

Multiple criteria can be set simultaneously. In such a case, AND semantics
apply. For example, the following rule only applies if the source of the
request is "reviews:v2" AND the "cookie" header containing "user=jason" is
present.

```yaml
destination: ratings.default.svc.cluster.local
match:
  source: reviews.default.svc.cluster.local
  sourceTags:
    version: v2
  httpHeaders:
    cookie:
      regex: "^(.*?;)?(user=jason)(;.*)?$"
```

### Split traffic between service versions

Each *route rule* identifies one or more weighted backends to call when the rule is activated.
Each backend corresponds to a specific version of the destination service,
where versions can be expressed using _tags_.

If there are multiple registered instances with the specified tag(s),
they will be routed to based on the load balancing policy configured for the service,
or round-robin by default.

For example, the following rule will route 25% of traffic for the "reviews" service to instances with
the "v2" tag and the remaining traffic (i.e., 75%) to "v1".

```yaml
destination: reviews.default.svc.cluster.local
route:
- tags:
    version: v2
  weight: 25
- tags:
    version: v1
  weight: 75
```

### Timeouts and Retries

By default, the timeout for http requests is 15 seconds,
but this can be overridden in a route rule as follows:

```yaml
destination: "ratings.default.svc.cluster.local"
route:
- tags:
    version: v1
httpReqTimeout:
  simpleTimeout:
    timeout: 10s
```

The number of retries for a given http request can also be specified in a route rule.
The maximum number of attempts, or as many as possible within the default or overriden timeout period,
can be set as follows:

```yaml
destination: "ratings.default.svc.cluster.local"
route:
- tags:
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
destination: reviews.default.svc.cluster.local
route:
- tags:
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
destination: "ratings.default.svc.cluster.local"
route:
- tags:
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
destination: ratings.default.svc.cluster.local
match:
  source: reviews.default.svc.cluster.local
  sourceTags:
    version: v2
route:
- tags:
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
destination: reviews.default.svc.cluster.local
precedence: 1
```

The precedence field is an optional integer value, 0 by default.  Rules
with higher precedence values are evaluated first. _If there is more than
one rule with the same precedence value the order of evaluation is
undefined._

**When is precedence useful?** Whenever the routing story for a particular
service is purely weight based, it can be specified in a single rule,
as shown in the earlier example.  When, on the other hand, other crieria
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
destination: reviews.default.svc.cluster.local
precedence: 2
match:
  httpHeaders:
    Foo:
      exact: bar
route:
- tags:
    version: v2
---
destination: reviews.default.svc.cluster.local
precedence: 1
route:
- tags:
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

## Destination Policies

Destination policies describe various routing related policies associated
with a particular service version, such as the load balancing algorithm,
the configuration of circuit breakers, health checks, etc. Unlike route
rules, destination policies cannot be qualified based on attributes of a
request such as the calling service or HTTP request headers.

However, the policies can be restricted to apply to requests that are
routed to backends with specific tags. For example, the following load
balancing policy will only apply to requests targetting the "v1" version of
the "reviews" microserivice.

```yaml
destination: reviews.default.svc.cluster.local
tags:
  version: v1
loadBalancing: RANDOM
```

### Circuit Breakers

A simple circuit breaker can be set based on a number of criteria such as connection and request limits.

For example, the following destination policy
sets a limit of 100 connections to "reviews" service version "v1" backends.

```yaml
destination: reviews.default.svc.cluster.local
tags:
  version: v1
circuitBreaker:
  simpleCb:
    maxConnections: 100
```

The complete set of simple circuit breaker fields can be found
[here]({{home}}/docs/reference/api/traffic-rules/destination-policies.html#istio.proxy.v1.config.CircuitBreaker).

### Destination Policy evaluation

Similar to route rules, destination policies are associated with a
particular *destination* however if they also include *tags* their
activation depends on route rule evaluation results.

The first step in the rule evaluation process evaluates the route rules for
a *destination*, if any are defined, to determine the tags (i.e., specific
version) of the destination service that the current request will be routed
to. Next, the set of destination policies, if any, are evaluated to
determine if they apply.

**NOTE:** One subtlety of the algorithm to keep in mind is that policies
that are defined for specific tagged destinations will only be applied if
the corresponding tagged instances are explicity routed to. For example,
consider the following rule, as the one and only rule defined for the
"reviews" service.

```yaml
destination: reviews.default.svc.cluster.local
tags:
  version: v1
circuitBreaker:
  simpleCb:
    maxConnections: 100
```

Since there is no specific route rule defined for the "reviews"
service, default round-robin routing behavior will apply, which will
persumably call "v1" instances on occasion, maybe even always if "v1" is
the only running version. Nevertheless, the above policy will never be
invoked since the default routing is done at a lower level. The rule
evaluation engine will be unaware of the final destination and therefore
unable to match the destination policy to the request.

You can fix the above example in one of two ways. You can either remove the
`tags:` from the rule, if "v1" is the only instance anyway, or, better yet,
define proper route rules for the service. For example, you can add a
simple route rule for "reviews:v1".

```yaml
destination: reviews.default.svc.cluster.local
route:
- tags:
    version: v1
```

Although the default Istio behavior conveniently sends traffic from all
versions of a source service to all versions of a destination service
without any rules being set, as soon as version discrimination is desired
rules are going to be needed.

Therefore, setting a default rule for every service, right from the
start, is generally considered a best practice in Istio.
