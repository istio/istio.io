---
title: Introducing the Istio v1alpha3 routing API
description: Introduction, motivation and design principles for the Istio v1alpha3 routing API.
publishdate: 2018-04-25
subtitle:
attribution: Frank Budinsky (IBM) and Shriram Rajagopalan (VMware)
keywords: [traffic-management]
target_release: 0.7
---

Up until now, Istio has provided a simple API for traffic management using four configuration resources:
`RouteRule`, `DestinationPolicy`, `EgressRule`, and (Kubernetes) `Ingress`.
With this API, users have been able to easily manage the flow of traffic in an Istio service mesh.
The API has allowed users to route requests to specific versions of services, inject delays and failures for resilience
testing, add timeouts and circuit breakers, and more, all without changing the application code itself.

While this functionality has proven to be a very compelling part of Istio, user feedback has also shown that this API does
have some shortcomings, specifically when using it to manage very large applications containing thousands of services, and
when working with protocols other than HTTP. Furthermore, the use of Kubernetes `Ingress` resources to configure external
traffic has proven to be woefully insufficient for our needs.

To address these, and other concerns, a new traffic management API, a.k.a. `v1alpha3`, is being introduced, which will
completely replace the previous API going forward. Although the `v1alpha3` model is fundamentally the same, it is not
backward compatible and will require manual conversion from the old API.

To justify this disruption, the `v1alpha3` API has gone through a long and painstaking community
review process that has hopefully resulted in a greatly improved API that will stand the test of time. In this article,
we will introduce the new configuration model and attempt to explain some of the motivation and design principles that
influenced it.

## Design principles

A few key design principles played a role in the routing model redesign:

* Explicitly model infrastructure as well as intent. For example, in addition to configuring an ingress gateway, the
  component (controller) implementing it can also be specified.
* The authoring model should be "producer oriented" and "host centric" as opposed to compositional. For example, all
  rules associated with a particular host are configured together, instead of individually.
* Clear separation of routing from post-routing behaviors.

## Configuration resources in v1alpha3

A typical mesh will have one or more load balancers (we call them gateways)
that terminate TLS from external networks and allow traffic into the mesh.
Traffic then flows through internal services via sidecar gateways.
It is also common for applications to consume external
services (e.g., Google Maps API). These may be called directly or, in certain deployments, all traffic
exiting the mesh may be forced through dedicated egress gateways. The following diagram depicts
this mental model.

{{< image width="80%"
    link="./gateways.svg"
    alt="Role of gateways in the mesh"
    caption="Gateways in an Istio service mesh"
    >}}

With the above setup in mind, `v1alpha3` introduces the following new
configuration resources to control traffic routing into, within, and out of the mesh.

1. `Gateway`
1. `VirtualService`
1. `DestinationRule`
1. `ServiceEntry`

`VirtualService`, `DestinationRule`, and `ServiceEntry` replace `RouteRule`,
`DestinationPolicy`, and `EgressRule` respectively. The `Gateway` is a
platform independent abstraction to model the traffic flowing into
dedicated middleboxes.

The figure below depicts the flow of control across configuration
resources.

{{< image width="80%"
    link="./virtualservices-destrules.svg"
    caption="Relationship between different v1alpha3 elements"
    >}}

### `Gateway`

A [`Gateway`](/pt-br/docs/reference/config/networking/gateway/)
configures a load balancer for HTTP/TCP traffic, regardless of
where it will be running.  Any number of gateways can exist within the mesh
and multiple different gateway implementations can co-exist. In fact, a
gateway configuration can be bound to a particular workload by specifying
the set of workload (pod) labels as part of the configuration, allowing
users to reuse off the shelf network appliances by writing a simple gateway
controller.

For ingress traffic management, you might ask: _Why not reuse Kubernetes Ingress APIs_?
The Ingress APIs proved to be incapable of expressing Istio's routing needs.
By trying to draw a common denominator across different HTTP proxies, the
Ingress is only able to support the most basic HTTP routing and ends up
pushing every other feature of modern proxies into non-portable
annotations.

Istio `Gateway` overcomes the `Ingress` shortcomings by separating the
L4-L6 spec from L7. It only configures the L4-L6 functions (e.g., ports to
expose, TLS configuration) that are uniformly implemented by all good L7
proxies. Users can then use standard Istio rules to control HTTP
requests as well as TCP traffic entering a `Gateway` by binding a
`VirtualService` to it.

For example, the following simple `Gateway` configures a load balancer
to allow external https traffic for host `bookinfo.com` into the mesh:

{{< text yaml >}}
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
{{< /text >}}

To configure the corresponding routes, a `VirtualService` (described in the [following section](#virtualservice))
must be defined for the same host and bound to the `Gateway` using
the `gateways` field in the configuration:

{{< text yaml >}}
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
{{< /text >}}

The `Gateway` can be used to model an edge-proxy or a purely internal proxy
as shown in the first figure. Irrespective of the location, all gateways
can be configured and controlled in the same way.

### `VirtualService`

Replacing route rules with something called "virtual services” might seem peculiar at first, but in reality it’s
fundamentally a much better name for what is being configured, especially after redesigning the API to address the
scalability issues with the previous model.

In effect, what has changed is that instead of configuring routing using a set of individual configuration resources
(rules) for a particular destination service, each containing a precedence field to control the order of evaluation, we
now configure the (virtual) destination itself, with all of its rules in an ordered list within a corresponding
[`VirtualService`](/pt-br/docs/reference/config/networking/virtual-service/) resource.
For example, where previously we had two `RouteRule` resources for the
[Bookinfo](/pt-br/docs/examples/bookinfo/) application’s `reviews` service, like this:

{{< text yaml >}}
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
{{< /text >}}

In `v1alpha3`, we provide the same configuration in a single `VirtualService` resource:

{{< text yaml >}}
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
        host: reviews
        subset: v2
  - route:
    - destination:
        host: reviews
        subset: v1
{{< /text >}}

As you can see, both of the rules for the `reviews` service are consolidated in one place, which at first may or may not
seem preferable. However, if you look closer at this new model, you’ll see there are fundamental differences that make
`v1alpha3` vastly more functional.

First of all, notice that the destination service for the `VirtualService` is specified using a `hosts` field (repeated field, in fact) and is then again specified in a `destination` field of each of the route specifications. This is a
very important difference from the previous model.

A `VirtualService` describes the mapping between one or more user-addressable destinations to the actual destination workloads inside the mesh. In our example, they are the same, however, the user-addressed hosts can be any DNS
names with optional wildcard prefix or CIDR prefix that will be used to address the service. This can be particularly
useful in facilitating turning monoliths into a composite service built out of distinct microservices without requiring the
consumers of the service to adapt to the transition.

For example, the following rule allows users to address both the `reviews` and `ratings` services of the Bookinfo application
as if they are parts of a bigger (virtual) service at `http://bookinfo.com/`:

{{< text yaml >}}
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
        host: reviews
  - match:
    - uri:
        prefix: /ratings
    route:
    - destination:
        host: ratings
  ...
{{< /text >}}

The hosts of a `VirtualService` do not actually have to be part of the service registry, they are simply virtual
destinations. This allows users to model traffic for virtual hosts that do not have routable entries inside the mesh.
These hosts can be exposed outside the mesh by binding the `VirtualService` to a `Gateway` configuration for the same host
(as described in the [previous section](#gateway)).

In addition to this fundamental restructuring, `VirtualService` includes several other important changes:

1. Multiple match conditions can be expressed inside the `VirtualService` configuration, reducing the need for redundant
   rules.

1. Each service version has a name (called a service subset). The set of pods/VMs belonging to a subset is defined in a
   `DestinationRule`, described in the following section.

1. `VirtualService` hosts can be specified using wildcard DNS prefixes to create a single rule for all matching services.
   For example, in Kubernetes, to apply the same rewrite rule for all services in the `foo` namespace, the `VirtualService`
   would use `*.foo.svc.cluster.local` as the host.

### `DestinationRule`

A [`DestinationRule`](/pt-br/docs/reference/config/networking/destination-rule/)
configures the set of policies to be applied while forwarding traffic to a service. They are
intended to be authored by service owners, describing the circuit breakers, load balancer settings, TLS settings, etc..
`DestinationRule` is more or less the same as its predecessor, `DestinationPolicy`, with the following exceptions:

1. The `host` of a `DestinationRule` can include wildcard prefixes, allowing a single rule to be specified for many actual
   services.
1. A `DestinationRule` defines addressable `subsets` (i.e., named versions) of the corresponding destination host. These
   subsets are used in `VirtualService` route specifications when sending traffic to specific versions of the service.
   Naming versions this way allows us to cleanly refer to them across different virtual services, simplify the stats that
   Istio proxies emit, and to encode subsets in SNI headers.

A `DestinationRule` that configures policies and subsets for the reviews service might look something like this:

{{< text yaml >}}
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
{{< /text >}}

Notice that, unlike `DestinationPolicy`, multiple policies (e.g., default and v2-specific) are specified in a single
`DestinationRule` configuration.

### `ServiceEntry`

[`ServiceEntry`](/pt-br/docs/reference/config/networking/service-entry/)
is used to add additional entries into the service registry that Istio maintains internally.
It is most commonly used to allow one to model traffic to external dependencies of the mesh
such as APIs consumed from the web or traffic to services in legacy infrastructure.

Everything you could previously configure using an `EgressRule` can just as easily be done with a `ServiceEntry`.
For example, access to a simple external service from inside the mesh can be enabled using a configuration
something like this:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: foo-ext
spec:
  hosts:
  - foo.com
  ports:
  - number: 80
    name: http
    protocol: HTTP
{{< /text >}}

That said, `ServiceEntry` has significantly more functionality than its predecessor.
First of all, a `ServiceEntry` is not limited to external service configuration,
it can be of two types: mesh-internal or mesh-external.
Mesh-internal entries are like all other internal services but are used to explicitly add services
to the mesh. They can be used to add services as part of expanding the service mesh to include unmanaged infrastructure
(e.g., VMs added to a Kubernetes-based service mesh).
Mesh-external entries represent services external to the mesh.
For them, mutual TLS authentication is disabled and policy enforcement is performed on the client-side,
instead of on the usual server-side for internal service requests.

Because a `ServiceEntry` configuration simply adds a destination to the internal service registry, it can be
used in conjunction with a `VirtualService` and/or `DestinationRule`, just like any other service in the registry.
The following `DestinationRule`, for example, can be used to initiate mutual TLS connections for an external service:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: foo-ext
spec:
  host: foo.com
  trafficPolicy:
    tls:
      mode: MUTUAL
      clientCertificate: /etc/certs/myclientcert.pem
      privateKey: /etc/certs/client_private_key.pem
      caCertificates: /etc/certs/rootcacerts.pem
{{< /text >}}

In addition to its expanded generality, `ServiceEntry` provides several other improvements over `EgressRule`
including the following:

1. A single `ServiceEntry` can configure multiple service endpoints, which previously would have required multiple
   `EgressRules`.
1. The resolution mode for the endpoints is now configurable (`NONE`, `STATIC`, or `DNS`).
1. Additionally, we are working on addressing another pain point: the need to access secure external services over plain
   text ports (e.g., `http://google.com:443`). This should be fixed in the coming weeks, allowing you to directly access
   `https://google.com` from your application. Stay tuned for an Istio patch release (0.8.x) that addresses this limitation.

## Creating and deleting v1alpha3 route rules

Because all route rules for a given destination are now stored together as an ordered
list in a single `VirtualService` resource, adding a second and subsequent rules for a particular destination
is no longer done by creating a new (`RouteRule`) resource, but instead by updating the one-and-only `VirtualService`
resource for the destination.

old routing rules:

{{< text bash >}}
$ kubectl apply -f my-second-rule-for-destination-abc.yaml
{{< /text >}}

`v1alpha3` routing rules:

{{< text bash >}}
$ kubectl apply -f my-updated-rules-for-destination-abc.yaml
{{< /text >}}

Deleting route rules other than the last one for a particular destination is also done by updating
the existing resource using `kubectl apply`.

When adding or removing routes that refer to service versions, the `subsets` will need to be updated in
the service's corresponding `DestinationRule`.
As you might have guessed, this is also done using `kubectl apply`.

## Summary

The Istio `v1alpha3` routing API has significantly more functionality than
its predecessor, but unfortunately is not backwards compatible, requiring a
one time manual conversion.  The previous configuration resources,
`RouteRule`, `DesintationPolicy`, and `EgressRule`, will not be supported
from Istio 0.9 onwards. Kubernetes users can continue to use `Ingress` to
configure their edge load balancers for basic routing. However, advanced
routing features (e.g., traffic split across two versions) will require use
of `Gateway`, a significantly more functional and highly
recommended `Ingress` replacement.

## Acknowledgments

Credit for the routing model redesign and implementation work goes to the
following people (in alphabetical order):

* Frank Budinsky (IBM)
* Zack Butcher (Google)
* Greg Hanson (IBM)
* Costin Manolache (Google)
* Martin Ostrowski (Google)
* Shriram Rajagopalan (VMware)
* Louis Ryan (Google)
* Isaiah Snell-Feikema (IBM)
* Kuat Yessenov (Google)
