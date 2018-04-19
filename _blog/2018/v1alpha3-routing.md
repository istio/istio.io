---
title: "Introducing the Istio v1alpha3 routing API"
overview: Introduction, motivation and design principles for the Istio v1alpha3 routing API. 
publish_date: April 19, 2018
subtitle:
attribution: Frank Budinsky and Shriram Rajagopalan

order: 90

layout: blog
type: markdown
redirect_from: "/blog/v1alpha3-routing.html"
---

{% include home.html %}

Up until now, Istio has provided a simple API for traffic management using four configuration resources:
`RouteRule`, `DestinationPolicy`, `EgressRule`, and (Kubernetes) `Ingress`.
With this API, users have been able to easily manage the flow of traffic in an Istio service mesh.
The API has allowed users to route requests to specific versions of services, inject delays and failures for resilience
testing, add timeouts and circuit breakers, and more, all without changing the application code itself.

While this functionality has proven to be a very compelling part of Istio, user feedback has also shown that this API does
have some shortcoming, specifically when using it manage very large applications containing thousands of services, and
when working with protocols other than HTTP. Furthermore, the use of Kubernetes `Ingress` resources to configure external
traffic has proven to be woefully insufficient for our needs.

To address these, and other concerns, a new traffic management API, a.k.a. `v1alpha3`, is being introduced, which will
completely replace the previous API going forward. Although the `v1alpha3` model is fundamentally the same, it is not
backward compatible and will require manual conversion from the old API. A
[conversion tool]({{home}}/docs/reference/commands/istioctl.html#istioctl%20experimental%20convert-networking-config)
is included in the the next few releases of Istio to help with the transition.

To justify this disruption, the `v1alpha3` API has gone through a long and painstaking community
review process that has hopefully resulted in a greatly improved API that will stand the test of time. In this article,
we will introduce the new configuration model and attempt to explain some of the motivation and design principles that
influenced it.

## Design Principles

A few key design principles played a role in the routing model redesign:

* Explicitly model infrastructure as well as intent. For example, in addition to configuring an ingress gateway, the
  component (controller) implementing it can also be specified.
* The authoring model should be "producer oriented" and "host-centric" as opposed to compositional. For example, all
  rules associated with a particular host are configured together, instead of individually.
* Clear separation of routing from post-routing behaviors.

## Configuration Resources in v1alpha3

The routing configuration resources in v1alpha3 have changed as follows:

1. [VirtualService]({{home}}/docs/reference/config/istio.networking.v1alpha3.html#VirtualService) replaces `RouteRule`
2. [DestinationRule]({{home}}/docs/reference/config/istio.networking.v1alpha3.html#DestinationRule) replaces
   `DestinationPolicy`
3. [ExternalService]({{home}}/docs/reference/config/istio.networking.v1alpha3.html#ExternalService) replaces `EgressRule`
4. [Gateway]({{home}}/docs/reference/config/istio.networking.v1alpha3.html#Gateway) is the recommended replacement
   for (Kubernetes) `Ingress`

The old `RouteRule`, `DestinationPolicy`, and `EgressRule` configuration resources will be completely removed and no longer
available in future releases of Istio. Istio `Ingress`, however, will continue to be available but using a `Gateway` provides
significantly more functionality and is the recommended API for configuring external traffic going forward.

### VirtualService

Replacing route rules with something called “virtual services” might seem peculiar at first, but in reality it’s
fundamentally a much better name for what is being configured, especially after redesigning the API to address the
scalability issues with the previous model.

In effect, what has changed is that instead of configuring routing using a set of individual configuration resources
(rules) for a particular destination service, each containing a precedence field to control the order of evaluation, we
now configure the (virtual) destination itself, with all of its rules in an ordered list within a corresponding
`VirtualService` resource. For example, where previously we had two `RouteRule` resources for the
[Bookinfo]({{home}}/docs/guides/bookinfo.html) application’s `reviews` service, like this:

```yaml
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
---
apiVersion: config.istio.io/v1alpha2
kind: RouteRule
metadata:
  name: reviews-test-v2
spec:
  destination:
    name: reviews
  precedence: 2
  match:
    request:
      headers:
        cookie:
          regex: "^(.*?;)?(user=jason)(;.*)?$"
  route:
  - labels:
      version: v2
```

In `v1alph3`, we provide the same configuration in a single `VirtualService` resource:

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
    route:
    - destination:
        name: reviews
        subset: v2
  - route:
    - destination:
        name: reviews
        subset: v1
```

As you can see, both of the rules for the `reviews` service are consolidated in one place, which at first may or may not
seem preferable. However, if you look closer at this new model, you’ll see there are fundamental differences that make
`v1alpha3` vastly more functional.

First of all, notice that the destination service for the `VirtualService` is specified using a `hosts` field (repeated field,
in fact) and is then again specified in a `destination` field of each of the route specifications. This is a very important
difference from the previous model.

A `VirtualService` describes the mapping between one, or more, user-addressable destinations to the actual destination services (workloads) inside the mesh. In our example, they are the same, however, the user-addressed hosts can be any DNS
names with optional wildcard prefix or CIDR prefix that will be used to address the service. This can be particularly
useful in facilitating turning monoliths into a composite service built out of distinct microservices without requiring the
consumers of the service to adapt to the transition.

For example, the following rule allows users to address both the reviews and ratings services of the Bookinfo application
as if they are parts of a bigger (virtual) service at http://bookinfo.com/:

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: bookinfo
spec:
  hosts:
    - bookinfo.com
  http:
  - match:
    - uri:
        prefix: /reviews
    route:
    - destination:
        name: reviews
  - match:
    - uri:
        prefix: /ratings
    route:
    - destination:
        name: ratings
  ...
```

The hosts of a `VirtualService` do not actually have to be part of the service registry, they are simply virtual
destinations. This allows users to model traffic for virtual hosts that do not have routable entries inside the mesh.
These hosts can be exposed outside the mesh by binding the `VirtualService` to a `Gateway` configuration for the same host
(see [Gateway](#gateway), below).

In addition to this fundamental restructuring, `VirtualService` includes several other important changes:

1. Multiple match conditions can be expressed inside the `VirtualService` configuration, reducing the need for redundant
   rules. 
2. Each service version has a name (called a service subset). The set of pods/VMs belonging to a subset is defined in a
   `DestinationRule`, described in the following section.
3. `VirtualService` hosts can be specified using wildcard DNS prefixes to create a single rule for all matching services.
   For example, in Kubernetes, to apply the same rewrite rule for all services in the `foo` namespace, the `VirtualService`
   would use `*.foo.svc.cluster.local` as the host.

### DestinationRule

A `DestinationRule` configures the set of policies to be applied at a destination after routing has occurred. They are
intended to be authored by service owners, describing the circuit breakers, load balancer settings, TLS settings, etc.. 
`DestinationRule` is more or less the same as its predecessor, `DestinationPolicy`, with the following exceptions:

1. The `host` of a `DestinationRule` can include wildcard prefixes, allowing a single rule to be specified for many actual
   services.
2. A `DestinationRule` defines addressable `subsets` (i.e., named versions) of the corresponding destination host. These
   subsets are used in `VirtualService` route specifications when sending traffic to specific versions of the service.
   Naming versions this way allows us to cleanly refer to them across different virtual services, simplify the stats that
   Istio proxies emit, and to encode subsets in SNI headers.

A `DestinationRule` that configures policies and subsets for the reviews service might look something like this:

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

Notice that, unlike `DestinationPolicy`, multiple policies (e.g., default and v2-specific) are specified in a single
`DestinationRule` configuration.

### ExternalService

`ExternalService` is used to add additional entries into the service registry that Istio maintains internally. This allows
one to model traffic to external dependencies of the mesh such as APIs consumed from the web or traffic to services in
legacy infrastructure.

Replacing `EgressRule` from the previous API, `ExternalService` provides several significant improvements, such as:

1. Individual service ports and service discovery mode are now configurable.
2. One or more (different) external endpoints can be configured to implement a “virtual” external service.
3. Secure HTTP services (automatic TLS upgrade) can now be accessed using standard https (e.g., https://secureservice.com/
   instead of http://secureservice.com:443/.
4. Multiple CIDR subsets can now be included in a single `ExternalService` configuration.

Because an `ExternalService` configuration simply adds an external destination to the internal service registry, it can be
used in conjunction with a `VirtualService` and/or `DestinationRule`, just like any other service in the registry.

### Gateway

It all started with ingress. The Istio ingress feature inherited the Kubernetes `Ingress` resource model for expediency, but
unfortunately it is not able to express all of the routing capabilities of Istio. The `Ingress` APIs are inadequate to model
ingress traffic for several key Istio use-cases such as:

* Split traffic across different versions of a service based on labelling
* Route traffic based on complex matching criteria on headers and other properties of the call.
* Apply transformations such as rewrites, header mutations, etc.
* Define resilience features such as retry & circuit breaking behavior
* Load balance TCP traffic

Another problem with the `Ingress` specification is that it tries to draw a common denominator across different L7 proxies.
This results in a least common denominator that uses the most basic HTTP routing and discards every other feature of the
proxy, which end up in annotations that are not portable.

So the `Gateway` effort started. Istio `Gateway` overcomes the `Ingress` shortcomings by separating the L4-L6 spec from L7.
It only configures the L4-L6 functions (e.g., ports to expose, TLS configuration) that are uniformly implemented by all good
L7 proxies. Users can then use standard Istio route rules to control HTTP requests & TCP traffic entering a `Gateway` by
binding a `VirtualService` to it. The route rules will be applied at the gateway if and only if one of the `VirtualService's`
hosts corresponds to one of the hosts configured in the `Gateway`.

For example, the following simple `Gateway` could be used to allow external https traffic to the bookinfo.com
`VirtualService`, described earlier:

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

In this example, the `hosts` field specifies bookinfo.com concretely, but in general the binding can be much more flexible.
A single `Gateway` can bind to multiple `VirtualServices` or a single `VirtualService` can be exposed on more than one
`Gateway`.

To configure the corresponding routes, the bookinfo `VirtualService` needs to be bound to the `Gateway` by adding an
additional `gateways` field to the configuration:

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

Although primarily used as an ingress allowing external traffic into the mesh, a `Gateway` can also act as an egress to
allow traffic in the mesh to exit. A `Gateway` can also model a proxy that is entirely internal to the mesh and implemented
either by sidecars or by a middle proxy.  Ingress and egress gateways can also expose non HTTP services with the same
ease.

A `Gateway` simply configures a loadbalancer, regardless of where it will be running. Any number of gateways can exist
within the mesh and multiple different gateway implementations can co-exist. In fact, a gateway configuration can be bound
to a particular workload by specifying the set of workload (pod) labels as part of the configuration, allowing users to
reuse off the shelf network appliances by writing a simple gateway controller. `Gateway` is much more general purpose than
simply an ingress replacement.

## Summary

The Istio `v1alpha3` routing API is significantly more functional than its predecessor, but unfortunately not backwards
compatible, requiring a one time manual conversion. The previous configuration resources, `RouteRule`, `DesintationPolicy`,
and `EgressRule`, will no longer be available or supported. For external traffic control, however, the previous `Ingress`
configuration will still be supported (in the Kubernetes environment), but with limited functionality. The new Istio
`Gateway` API is significantly more functional and a highly recommended `Ingress` replacement.

