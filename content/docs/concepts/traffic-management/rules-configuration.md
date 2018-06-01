---
title: Rules Configuration
description: Provides a high-level overview of the configuration model used by Istio to configure traffic management rules in the service mesh.
weight: 50
---

Istio provides a simple configuration model to
control how API calls and layer-4 traffic flow across various
services in an application deployment. The configuration model allows an operator to
configure service-level properties such as circuit breakers, timeouts,
retries, as well as set up common continuous deployment tasks such as
canary rollouts, A/B testing, staged rollouts with %-based traffic splits,
etc.

For example, a simple rule to send 100% of incoming traffic for a *reviews*
service to version "v1" can be described using a configuration as
follows:

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: reviews
spec:
  hosts:
  - reviews
  http:
  - route:
    - destination:
        host: reviews
        subset: v1
```

This configuration says that traffic sent to the *reviews* service
(specified in the `hosts` field) should be routed to the v1 subset
of the underlying *reviews* service instances.
The route `subset` specifies the name of a defined subset in
a corresponding destination rule configuration:

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: reviews
spec:
  host: reviews
  subsets:
  - name: v1
    labels:
      version: v1
  - name: v2
    labels:
      version: v2
```

A subset specifies one or more labels that identify version-specific instances.
For example, in a Kubernetes deployment of Istio, "version: v1" indicates that
only pods containing the label "version: v1" will receive traffic.

Rules can be configured using the
[istioctl CLI](/docs/reference/commands/istioctl/), or in a Kubernetes
deployment using the `kubectl` command instead, although only `istioctl` will
perform model validation and is recommended. See the
[configuring request routing task](/docs/tasks/traffic-management/request-routing/)
for examples.

There are four traffic management configuration resources in Istio:
**VirtualService**, **DestinationRule**, **ServiceEntry**, and **Gateway**.
A few important aspects of these resources are described below.
See [networking reference](/docs/reference/config/istio.networking.v1alpha3/)
for detailed information.

## Virtual Services

A [VirtualService](/docs/reference/config/istio.networking.v1alpha3/#VirtualService)
defines the rules that control how requests for a service are routed within an Istio service mesh.
For example, a virtual service could route requests to different versions of a service or, in fact,
to a completely different service than was requested.
Requests can be routed based on the request source and destination, HTTP paths and
header fields, and weights associated with individual service versions.

### Rule destinations

Routing rules correspond to one or more request destination hosts that are specified in
a `VirtualService` configuration. These hosts may or may not be the same as the actual
destination workload and may not even correspond to an actual routable service in the mesh.
For example, to define routing rules for requests to the *reviews* service using its internal
mesh name `reviews` or via host `bookinfo.com`, a `VirtualService` could have a `hosts` field
something like this:

```yaml
hosts:
  - reviews
  - bookinfo.com
```

The `hosts` field specifies, implicitly or explicitly, one or more fully qualified
domain names (FQDN). The short name `reviews`, above, would implicitly
expand to an implementation specific FQDN. For example, in a Kubernetes environment
the full name is derived from the cluster and namespace of the `VirtualSevice`
(e.g., `reviews.default.svc.cluster.local`).

### Qualify rules by source/headers

Rules can optionally be qualified to only apply to requests that match some
specific criteria such as the following:

_1. Restrict to a specific caller_.  For example, a rule
can indicate that it only applies to calls from workloads (pods) implementing
the *reviews* service.

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: ratings
spec:
  hosts:
  - ratings
  http:
  - match:
      sourceLabels:
        app: reviews
    ...
```

The value of `sourceLabels` depends on the implementation of the service.
In Kubernetes, for example, it would probably be the same labels that are used
in the pod selector of the corresponding Kubernetes service.

_2. Restrict to specific versions of the caller_. For example, the following
rule refines the previous example to only apply to calls from version "v2"
of the *reviews* service.

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: ratings
spec:
  hosts:
  - ratings
  http:
  - match:
    - sourceLabels:
        app: reviews
        version: v2
    ...
```

_3. Select rule based on HTTP headers_. For example, the following rule will
only apply to an incoming request if it includes a "cookie" header that
contains the substring "user=jason".

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: reviews
spec:
  hosts:
    - reviews
  http:
  - match:
    - headers:
        cookie:
          regex: "^(.*?;)?(user=jason)(;.*)?$"
    ...
```

If more than one header is provided, then all of the
corresponding headers must match for the rule to apply.

Multiple criteria can be set simultaneously. In such a case, AND or OR
semantics apply, depending on the nesting.
If multiple criteria are nested in a single match clause, then the conditions
are ANDed. For example, the following rule only applies if the source of the
request is "reviews:v2" AND the "cookie" header containing "user=jason" is
present.

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: ratings
spec:
  hosts:
  - ratings
  http:
  - match:
    - sourceLabels:
        app: reviews
        version: v2
      headers:
        cookie:
          regex: "^(.*?;)?(user=jason)(;.*)?$"
    ...
```

If instead, the criteria appear in separate match clauses, then only one
of the conditions must apply (OR semantics):

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: ratings
spec:
  hosts:
  - ratings
  http:
  - match:
    - sourceLabels:
        app: reviews
        version: v2
    - headers:
        cookie:
          regex: "^(.*?;)?(user=jason)(;.*)?$"
    ...
```

### Split traffic between service versions

Each route rule identifies one or more weighted backends to call when the rule is activated.
Each backend corresponds to a specific version of the destination service,
where versions can be expressed using _labels_.
If there are multiple registered instances with the specified label(s),
they will be routed to based on the load balancing policy configured for the service,
or round-robin by default.

For example, the following rule will route 25% of traffic for the *reviews* service to instances with
the "v2" label and the remaining traffic (i.e., 75%) to "v1".

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: reviews
spec:
  hosts:
    - reviews
  http:
  - route:
    - destination:
        host: reviews
        subset: v1
      weight: 75
    - destination:
        host: reviews
        subset: v2
      weight: 25
```

### Timeouts and retries

By default, the timeout for http requests is 15 seconds,
but this can be overridden in a route rule as follows:

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: ratings
spec:
  hosts:
    - ratings
  http:
  - route:
    - destination:
        host: ratings
        subset: v1
    timeout: 10s
```

The number of retries for a given http request can also be specified in a route rule.
The maximum number of attempts, or as many as possible within the default or overridden timeout period,
can be set as follows:

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: ratings
spec:
  hosts:
    - ratings
  http:
  - route:
    - destination:
        host: ratings
        subset: v1
    retries:
      attempts: 3
      perTryTimeout: 2s
```

Note that request timeouts and retries can also be
[overridden on a per-request basis](/docs/concepts/traffic-management/handling-failures#fine-tuning).

See the [request timeouts task](/docs/tasks/traffic-management/request-timeouts/) for a demonstration of timeout control.

### Injecting faults in the request path

A route rule can specify one or more faults to inject
while forwarding http requests to the rule's corresponding request destination.
The faults can be either delays or aborts.

The following example will introduce a 5 second delay in 10% of the requests to the "v1" version of the *ratings* microservice.

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: ratings
spec:
  hosts:
  - ratings
  http:
  - fault:
      delay:
        percent: 10
        fixedDelay: 5s
    route:
    - destination:
        host: ratings
        subset: v1
```

The other kind of fault, abort, can be used to prematurely terminate a request,
for example, to simulate a failure.

The following example will return an HTTP 400 error code for 10%
of the requests to the *ratings* service "v1".

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: ratings
spec:
  hosts:
  - ratings
  http:
  - fault:
      abort:
        percent: 10
        httpStatus: 400
    route:
    - destination:
        host: ratings
        subset: v1
```

Sometimes delays and abort faults are used together. For example, the following rule will delay
by 5 seconds all requests from the *reviews* service "v2" to the *ratings* service "v1" and
then abort 10 percent of them:

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: ratings
spec:
  hosts:
  - ratings
  http:
  - match:
    - sourceLabels:
        app: reviews
        version: v2
    fault:
      delay:
        fixedDelay: 5s
      abort:
        percent: 10
        httpStatus: 400
    route:
    - destination:
        host: ratings
        subset: v1
```

To see fault injection in action, see the [fault injection task](/docs/tasks/traffic-management/fault-injection/).

### HTTP route rules have precedence

When there are multiple rules for a given destination,
they are evaluated in the order they appear
in the `VirtualService`, i.e., the first rule
in the list has highest priority.

**Why is priority important?** Whenever the routing story for a particular
service is purely weight based, it can be specified in a single rule.
When, on the other hand, other criteria
(e.g., requests from a specific user) are being used to route traffic, more
than one rule will be needed to specify the routing.  This is where the
rule priority must be carefully considered to make sure that the rules are
evaluated in the right order.

A common pattern for generalized route specification is to provide one or
more higher priority rules that qualify rules by source/headers,
and then provide a single weight-based rule with no match
criteria last to provide the weighted distribution of
traffic for all other cases.

For example, the following `VirtualService` contains 2 rules that, together,
specify that all requests for the *reviews* service that includes a header
named "Foo" with the value "bar" will be sent to the "v2" instances.
All remaining requests will be sent to "v1".

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: reviews
spec:
  hosts:
  - reviews
  http:
  - match:
    - headers:
        Foo:
          exact: bar
    route:
    - destination:
        host: reviews
        subset: v2
  - route:
    - destination:
        host: reviews
        subset: v1
```

Notice that the header-based rule has the higher priority. If
it was lower, these rules wouldn't work as expected since the weight-based
rule, with no specific match criteria, would be evaluated first which would
then simply route all traffic to "v1", even requests that include the
matching "Foo" header. Once a rule is found that applies to the incoming
request, it will be executed and the rule-evaluation process will
terminate. That's why it's very important to carefully consider the
priorities of each rule when there is more than one.

## Destination Rules

A [DestinationRule](/docs/reference/config/istio.networking.v1alpha3/#DestinationRule)
configures the set of policies to be applied to a request after `VirtualService` routing has occurred. They are
intended to be authored by service owners, describing the circuit breakers, load balancer settings, TLS settings, etc..

A `DestinationRule` also defines addressable `subsets` (i.e., named versions) of the corresponding destination host.
These subsets are used in `VirtualService` route specifications when sending traffic to specific versions of the service.

The following `DestinationRule` configures policies and subsets for the reviews service:

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: reviews
spec:
  host: reviews
  trafficPolicy:
    loadBalancer:
      simple: RANDOM
  subsets:
  - name: v1
    labels:
      version: v1
  - name: v2
    labels:
      version: v2
    trafficPolicy:
      loadBalancer:
        simple: ROUND_ROBIN
  - name: v3
    labels:
      version: v3
```

Notice that multiple policies (e.g., default and v2-specific) can be
specified in a single `DestinationRule` configuration.

### Circuit breakers

A simple circuit breaker can be set based on a number of criteria such as connection and request limits.

For example, the following `DestinationRule`
sets a limit of 100 connections to *reviews* service version "v1" backends.

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: reviews
spec:
  host: reviews
  subsets:
  - name: v1
    labels:
      version: v1
    trafficPolicy:
      connectionPool:
        tcp:
          maxConnections: 100
```

See the [circuit-breaking task](/docs/tasks/traffic-management/circuit-breaking/) for a demonstration of circuit breaker control.

### DestinationRule evaluation

Similar to route rules, policies are associated with a
particular *host* however if they are subset specific,
activation depends on route rule evaluation results.

The first step in the rule evaluation process evaluates the route rules in
the `VirtualService` corresponding to the requested *host*, if there are any defined,
to determine the subset (i.e., specific
version) of the destination service that the current request will be routed
to. Next, the set of policies corresponding to the selected subset, if any,
are evaluated to determine if they apply.

**NOTE:** One subtlety of the algorithm to keep in mind is that policies
that are defined for specific subsets will only be applied if
the corresponding subset is explicitly routed to. For example,
consider the following configuration, as the one and only rule defined for the
*reviews* service (i.e., there are no route rules in a corresponding `VirtualService`.

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: reviews
spec:
  host: reviews
  subsets:
  - name: v1
    labels:
      version: v1
    trafficPolicy:
      connectionPool:
        tcp:
          maxConnections: 100
```

Since there is no specific route rule defined for the *reviews*
service, default round-robin routing behavior will apply, which will
presumably call "v1" instances on occasion, maybe even always if "v1" is
the only running version. Nevertheless, the above policy will never be
invoked since the default routing is done at a lower level. The rule
evaluation engine will be unaware of the final destination and therefore
unable to match the subset policy to the request.

You can fix the above example in one of two ways. You can either move the
traffic policy up a level to make it apply to any version:

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: reviews
spec:
  host: reviews
  trafficPolicy:
    connectionPool:
      tcp:
        maxConnections: 100
  subsets:
  - name: v1
    labels:
      version: v1
```

or, better yet, define proper route rules for the service.
For example, you can add a simple route rule for "reviews:v1".

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: reviews
spec:
  hosts:
  - reviews
  http:
  - route:
    - destination:
        host: reviews
        subset: v1
```

Although the default Istio behavior conveniently sends traffic from any
source to all versions of a destination service
without any rules being set, as soon as version discrimination is desired
rules are going to be needed.
Therefore, setting a default rule for every service, right from the
start, is generally considered a best practice in Istio.

## Service Entries

A [ServiceEntry](/docs/reference/config/istio.networking.v1alpha3/#ServiceEntry)
is used to add additional entries into the service registry that Istio maintains internally.
It is most commonly used to enable requests to services outside of an Istio service mesh.
For example, the following `ServiceEntry` can be used to allow external calls to services hosted
under the `*.foo.com` domain.

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: foo-ext-svc
spec:
  hosts:
  - *.foo.com
  ports:
  - number: 80
    name: http
    protocol: HTTP
  - number: 443
    name: https
    protocol: HTTPS
```

The destination of a `ServiceEntry` is specified using the `hosts` field, which
can be either a fully qualified or wildcard domain name.
It represents a white listed set of one or more services that services
in the mesh are allowed to access.

A `ServiceEntry` is not limited to external service configuration,
it can be of two types: mesh-internal or mesh-external.
Mesh-internal entries are like all other internal services but are used to explicitly add services
to the mesh. They can be used to add services as part of expanding the service mesh to include unmanaged infrastructure
(e.g., VMs added to a Kubernetes-based service mesh).
Mesh-external entries represent services external to the mesh.
For them, mTLS authentication is disabled and policy enforcement is performed on the client-side,
instead of on the usual server-side for internal service requests.

Service entries work well in conjunction with virtual services
and destination rules as long as they refer to the services using matching
`hosts`. For example, the following rule can be used in conjunction with
the above `ServiceEntry` rule to set a 10s timeout for calls to
the external service at `bar.foo.com`.

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: bar-foo-ext-svc
spec:
  hosts:
    - bar.foo.com
  http:
  - route:
    - destination:
        host: bar.foo.com
    timeout: 10s
```

Rules to redirect and forward traffic, to define retry,
timeout and fault injection policies are all supported for external destinations.
Weighted (version-based) routing is not possible, however, since there is no notion
of multiple versions of an external service.

See the [egress task](/docs/tasks/traffic-management/egress/) for a more
about accessing external services.

## Gateways

A [Gateway](/docs/reference/config/istio.networking.v1alpha3/#Gateway)
configure a load balancer for HTTP/TCP traffic, most commonly operating at the edge of the
mesh to enable ingress traffic for an application.

Unlike Kubernetes Ingress, Istio `Gateway` only configures the L4-L6 functions
(e.g., ports to  expose, TLS configuration). Users then can use standard Istio rules
to control HTTP requests as well as TCP traffic entering a `Gateway` by binding a
`VirtualService` to it.

For example, the following simple `Gateway` configures a load balancer
to allow external https traffic for host `bookinfo.com` into the mesh:

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: bookinfo-gateway
spec:
  servers:
  - port:
      number: 443
      name: https
      protocol: HTTPS
    hosts:
    - bookinfo.com
    tls:
      mode: SIMPLE
      serverCertificate: /tmp/tls.crt
      privateKey: /tmp/tls.key
```

To configure the corresponding routes, a `VirtualService`
must be defined for the same host and bound to the `Gateway` using
the `gateways` field in the configuration:

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: bookinfo
spec:
  hosts:
    - bookinfo.com
  gateways:
  - bookinfo-gateway # <---- bind to gateway
  http:
  - match:
    - uri:
        prefix: /reviews
    route:
    ...
```

See the [ingress task](/docs/tasks/traffic-management/ingress/) for a
complete ingress gateway example.

Although primarily used to manage ingress traffic, a `Gateway` can also be used to model
a purely internal or egress proxy. Irrespective of the location, all gateways
can be configured and controlled in the same way. Refer to the
[gateway reference](/docs/reference/config/istio.networking.v1alpha3/#Gateway)
for details.
