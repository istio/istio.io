---
title: The Istio network configuration objects and your application
description: Describes Istio's network configuration objects and their functionality.
weight: 30
keywords: [network, virtual service, gateway, ingress, egress, service entry]
aliases:
---

Cloud applications, unlike monolithic applications, are comprised of a
collection of connected services. Throughout this document a service should be
understood as an addressable destination workload inside the mesh. These
services can connect to other services or to external resources. The Istio
configuration objects allow you to configure traffic routes to and from
services to secure the traffic between them. Other configuration objects
provide telemetry and monitoring configuration options but this document
focuses on the Istio's network configuration objects.

The Istio network API defines four configuration objects: gateways, virtual
services, destination rules, and service entries.
The diagrams on this page don't show data plane traffic. Unless otherwise
indicated, the arrows in the diagrams portray the traffic routes that the
network configuration objects configured using destination rules. The diagrams
show the possible control plane connections between the Envoy proxies of the
network configuration objects.

The following diagram shows the **configurable traffic routes** that the
network configuration objects allow for a basic mesh with two different
versions of a service:

{{< image width="80%"
    link="./net-config-1.svg"
    caption="Istio network configuration objects overview"
    >}}

This document describes the key configurations each configuration object
enables. Additionally, this document provides high-level examples of how the
Istio network API can help you handle internal, incoming, and outgoing traffic.
Lastly, the document discusses the benefits of using the Istio network API for
your cloud applications.

# The Istio network configuration objects

The Istio network configuration objects provide you with four objects to
configure the traffic routes between your services and your external resources:
virtual services, destination rules, service entries, and gateways. You can add
and configure these objects in a variety of ways to suit your needs. Each
configuration object serves a specific purpose and provides specific
configurations for your Istio service mesh. To create a solution for your
specific mesh, you can combine the configuration objects in a way that best
fulfills your needs.

You can define the Istio network configuration objects as Kubernetes Custom
Resource Definition [(CRD)](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/)
objects and store their configuration in YAML files. The following sections
describe the purposes and specific configurations of each configuration object
and provide examples.

## Virtual Services

You can use virtual services for fine-grained traffic control. Istio can use
virtual services to configure  ingress, canary, traffic rewrite, or traffic
policing. A virtual service is not required for simple connectivity. A service
can map one or more user-addressable destinations to the actual destination
workloads inside the mesh without a virtual service. The Istio virtual services
can configure traffic routes to:

-  Other virtual services in the mesh.
-  Specific services or services' subsets in the mesh.
-  Other network configuration objects in the mesh.

{{< image width="80%"
    link="./net-config-2.svg"
    caption="Possible configurations between virtual services and workloads"
    >}}

As you can see, virtual services are very flexible and can accommodate a wide
variety of topologies. With destination rules, virtual services configure the
traffic routes to your application services. The Istio virtual services can use
any DNS names with optional wildcard prefixes or CIDR prefixes to create a
single rule for all matching services. You can address one or more application
services through a single Istio virtual service. To eliminate redundant rules,
you can add multiple match conditions to a virtual service configuration. If
your mesh uses Kubernetes, for example, you can configure a virtual service to
handle all services in a specific namespace. With the Istio virtual services,
you can configure routes for the canary and A/B testing for your application's
services. You can configure each application service version as a virtual
service subset. You can also configure the corresponding Istio destination rule
to determine the set of pods or VMs belonging to these subsets.

You can use the Istio virtual services in a variety of ways: to route traffic
following the rules to provide load balancing to the ingress and egress traffic
of your mesh with Istio gateways, and to address multiple application services
through a single Istio virtual service.

The following example shows an Istio virtual service configuration file with
descriptive value entries. You can use this example as a basis and modify it to
fit your needs:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: my-vtl-svc
spec:
  hosts:
    - *.my-co.org
      route:
      - destination:
        host: service
        subset: v1
{{< /text >}}

Virtual services can specify the destination's DNS host name using the `hosts:`
field under `spec:`. As you can see in the `my-vtl-svc` example, you can use a
wildcard for the virtual service configurations to apply to multiple hosts. In
the `destination:` field of each route, you specify the service and subset that
the configuration targets. The example configures a route for traffic to reach
the `v1` subset of the `my-svc` service from the `my-vtl-svc` virtual service.
The following diagram shows the configured rule:

{{< image width="50%"
    link="./net-config-3.svg"
    caption="A virtual service configurable traffic to a specific subset"
    >}}

Istio does not need virtual services to connect to services. More commonly, you
use virtual services to finely configure traffic. For example, to direct HTTP
traffic to use a different version of the service for a specific user. To
specify the user, the following example uses a regular expression to match the
user from the cookie and shows you how to add the condition for the protocol in
the `http:` field and a new `route:` and `destination:` configuration for the
traffic matching the condition. In short, the example configures the HTTP
traffic from the `jason` user to go to the `v2` subset of the `my-svc` service:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: my-vtl-svc
spec:
  hosts:
    - *
    - route:
      - destination:
        host: my-svc
        subset: v1
  http:
    - match:
      - headers:
          cookie:
            regex: "^(.*?;)?(user=jason)(;.*)?$"
    route:
      - destination:
        host: my-svc
        subset: v2
{{< /text >}}

The following diagram shows the configured traffic rules for both the traffic
with the matched cookie and for all other traffic:

{{< image width="50%"
    link="./net-config-4.svg"
    caption="Configurable traffic rules for traffic with and without a matched cookie"
    >}}

If you are working with a Kubernetes-based mesh, use virtual services to manage
the traffic to your namespaces. The following example shows the `my-namespace`
virtual service. It configures traffic routes for the two services behind the
`my-namespace.svc.cluster.local` Kubernetes namespace:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: my-namespace
spec:
  hosts:
    - *.my-namespace.svc.cluster.local
  http:
  - match:
    - uri:
        prefix: /svc-1
    route:
    - destination:
        host: svc-1
  - match:
    - uri:
        prefix: /svc-2
    route:
    - destination:
        host: svc-2
{{< /text >}}

The following diagram shows the configured traffic routes implementing a
virtual service to configure traffic for services in a namespace for two
distinct application services based on the URI prefixes:

{{< image width="50%"
    link="./net-config-5.svg"
    caption="Configurable traffic rules implementing a namespace for two  application services"
    >}}

Once you have identified and configured the virtual services suitable for your
mesh, you can add gateways to route traffic in or out of your mesh. The virtual
services together with destination rules allow you to configure the behavior of
the traffic to fulfill the needs of your mesh. Together with a service entry,
you can use virtual services to configure traffic routes to external
dependencies.

Visit our [virtual services reference documentation](/docs/reference/config/istio.networking.v1alpha3/#VirtualService) to review all the enabled keys and values.

## Gateways

The Istio gateways are layer 7 load balancers. With an Istio gateway, you can
configure routes for HTTP and TCP traffic regardless of where the gateway runs.
Your mesh can have any number of gateways and multiple different gateway
implementations can co-exist within your mesh. Using a gateway, you can
configure workload labels to reuse your existing network appliances such as:
firewall functions, caching, authentication, network address translation, and
IP address management.

By separating the layer 4 and 6 specifications from the layer 7, the Istio
gateways overcome the shortcomings of the layer 4 and 6 specifications. Istio
only configures the functions that layer 7 load balancing proxies implement
uniformly. To use standard Istio rules to control HTTP requests as well as TCP
traffic entering a gateway, you must bind a virtual service to the gateway. The
following example shows a possible gateway configuration to ingress external
HTTPS traffic to the mesh:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: ext-host-gwy
spec:
  servers:
  - port:
      number: 443
      name: https
      protocol: HTTPS
    hosts:
    - ext-host
    tls:
      mode: SIMPLE
      serverCertificate: /tmp/tls.crt
      privateKey: /tmp/tls.key
{{< /text >}}

To configure the external HTTPS traffic to flow from the `ext-host` host, you
must add the Istio gateway to a Istio virtual service as shown:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: virtual-svc
spec:
  hosts:
    - ext-svc
  gateways:
    - ext-host-gwy
{{< /text >}}

The following diagram shows the configured routes for the external HTTPS
traffic coming from the external host on port 443 to the `virtual-svc` virtual
service through the `ext-host-gwy` gateway to reach the `my-svc` service
within the mesh:

{{< image width="50%"
    link="./net-config-6.svg"
    caption="Configurable routes for the external HTTPS traffic"
    >}}

Visit our [gateways reference documentation](/docs/reference/config/istio.networking.v1alpha3/#Gateway) to review all the enabled keys and values.

### Ingress gateways

Use ingress gateways to configure ingress traffic routes into the service mesh.
You can add as many gateways as you need. For example, you can have one gateway
for private traffic and another for public traffic. Thus, you balance the
different loads independently from each other.

### Egress gateways

Use egress gateways to configure an exit route for traffic leaving the mesh.
You can configure each egress gateway to use its own policies and telemetry.
You can use egress gateways if only particular application services can or
should access external networks.

## Destination Rules

Istio uses destination rules to configure traffic policies and traffic routes
to a service. These policies include:

-  TLS settings
-  Outlier detection
-  Load balancer settings
-  Definition of subsets of destination hosts in the mesh

Use wild card prefixes in a destination rule to specify a single rule for
multiple services. Istio uses the defined subsets of the destination hosts in
the virtual services  `route:` specification to send traffic to specific
versions of the service. This naming of versions allows you to:

-  Cleanly refer to a specific service version across different virtual
   services.
-  Simplify the stats that the Istio proxies emit.
-  Encode subsets in SNI headers.

The following example destination rule configures three different subsets with
different load balancing policies for the `vtl-svc` virtual service:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: my-destination-rule
spec:
  host: my-vtl-svc
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

The following diagram shows how the different configurations in the
`my-destination-rule` destination rule affect the traffic to and from the
`my-vtl-svc` virtual service:

{{< image width="50%"
    link="./net-config-7.svg"
    caption="Configurable route examples defined in the destination rule"
    >}}

Visit our [destination rules reference documentation](/docs/reference/config/istio.networking.v1alpha3/#DestinationRule) to review all the enabled keys and values.

## Service Entries

Istio uses service entries to add services to Istio's internal service
registry. Most commonly, you use a service entry to configure the traffic
routes for external dependencies of the mesh. For example, you can configure
traffic routes for APIs consumed from the web or traffic to services in legacy
infrastructure.

Adding a service to the internal registry is required to configure traffic
routes to external services. You can enhance the configuration options of
service entries with virtual services and destination rules. Service entries
are not limited to external service configuration. A service entry can have one
of two types: mesh-internal or mesh-external:

-  **Mesh-internal service entries** explicitly add internal services to the
   Istio mesh. You can use mesh-internal service entries to add services as
   your service mesh expands to include unmanaged infrastructure. The unmanaged
   infrastructure can include components such as VMs added to a
   Kubernetes-based service mesh.

-  **Mesh-external service entries** explicitly add external services to the
   mesh. Mutual TLS authentication is disabled for mesh-external service
   entries. Istio performs policy enforcement on the client-side, instead of on
   the usual server-side used by internal service requests.

Mesh-external service entries provide the following configuration options:

-  You can configure multiple external dependencies with a single service
   entry.
-  You can configure the resolution mode for the external dependencies to
   `NONE`, `STATIC`, or `DNS`.
-  You can access secure external services over plain text ports to directly
   access external dependencies from your application.

The following example configuration shows a mesh-external service entry for the
`ext-resource` external dependency:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: svc-entry
spec:
  hosts:
  - ext-resource.com
  ports:
  - number: 443
    name: https
    protocol: HTTPS
  location: MESH_EXTERNAL
{{< /text >}}

Because a service entry configuration simply adds the external resource to the
internal service registry, you must use either a virtual service or destination
rules to complete the configuration. You configure a service entry similarly to
how you configure a service in the mesh. The following destination rule
configures the traffic route to use mutual TLS to connect to the `ext-resource`
external service that the service entry added to the mesh:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: ext-res-dr
spec:
  host: ext-resource.com
  trafficPolicy:
    tls:
      mode: MUTUAL
      clientCertificate: /etc/certs/myclientcert.pem
      privateKey: /etc/certs/client_private_key.pem
      caCertificates: /etc/certs/rootcacerts.pem
{{< /text >}}

Together, the `svc-entry` service entry and the `ext-res-dr` destination rule
configure a route for the  HTTPS traffic to and from the `ext-resource`
external dependency through the `svc-entry` service entry on port 80 and using
mutual TLS. The following diagram shows the configured traffic routes:

{{< image width="50%"
    link="./net-config-8.svg"
    caption="Configurable traffic routes using service entries and destination rules"
    >}}

Service entries do not require virtual services to address services in the
mesh. Use destination rules to configure routes to address services directly.
The use of an ingress gateway is also optional.

Visit our [service entries reference documentation](/docs/reference/config/istio.networking.v1alpha3/#ServiceEntry) to review all the enabled keys and values.
