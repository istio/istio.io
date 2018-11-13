---
title: Gateways
description: Describes the architecture, purpose, and behavior of Istio gateways for both ingress and egress traffic.
weight: 6
keywords: [ingress, egress, gateway, internal traffic, external traffic, canary, load balancing]
aliases:
---

A [gateway](/docs/reference/config/istio.networking.v1alpha3/#Gateway) is a
workload implementing a layer 7 router configuring a load balancer for HTTP/TCP
traffic. Typically, gateways are implemented as an Envoy proxy running in a
pod. To learn more about load balancing, visit our [Discovery and Load Balancing concept](../load-balancing)

Unlike the Kubernetes Ingress, an Istio gateway configures only the L4-L6
functions of the gateway, for example, ports to expose and TLS configuration.
You must specify the gateway workload in the `selector:` value of the gateway
configuration object and use an Istio [virtual service](../virtual-services) to
configure the remaining layer 7 properties.

Your mesh can have any number of gateway configuration objects and multiple
different gateway workload implementations can co-exist within your mesh. Using
a gateway, you can configure workload labels to reuse your existing network
appliances such as: firewall functions, caching, authentication, network
address translation, and IP address management.

Istio assumes that all traffic entering and leaving the service mesh transits
through Envoy proxies.

Deploying an Envoy proxy as an ingress gateway in front of
the services in your mesh, allows you to, among other things:

- Conduct A/B testing for user-facing services.

- [Roll out canary services](../traffic-routing/#canary) for user-facing
  services.

Similarly, routing traffic to external web services, for example, accessing a
maps API or a video service API, via an Envoy proxy, allows you to:

- Add failure recovery features such as:

    - [Timeouts](../failures/#timeouts)
    - [Retries](../failures/#retries)
    - [Circuit breakers](../failures/#circuit)

- Obtain detailed metrics on the connections to the services.

The following diagram shows the basic model of a service mesh with an ingress
gateway and an egress gateway.

{{< image width="85%"
    link="./ingress-egress-model.svg"
    alt="Ingress and Egress through Envoy."
    caption="Request Flow"
    >}}

You must route all traffic entering the mesh via an ingress gateway workload
using a virtual service. You bind the virtual service to the gateway
configuration object to use standard Istio [routing rules](../routing-rules) to
control HTTP requests as well as the TCP traffic entering a gateway. The
following example shows a possible gateway configuration object to ingress
external HTTPS traffic to the mesh:

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
must add the gateway configuration object to an Istio virtual service as shown
here:

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

The gateway configuration object lets HTTPS traffic from `ext-host` into the
mesh on port 443. The bound virtual service configures the traffic route for
the traffic to reach the `my-svc` service.

The following diagram shows the configured routes for the external HTTPS
traffic to the `my-svc` service within the mesh:

{{< image width="50%"
    link="./gateways.svg"
    caption="Configurable routes for the external HTTPS traffic"
    >}}

Although primarily used to manage ingress traffic, you can use a gateway to
model a purely internal or an egress proxy. Irrespective of their location in
the mesh, you can configure and control all gateways in the same way.

Visit our [gateways reference documentation](/docs/reference/config/istio.networking.v1alpha3/#Gateway)
to review all the enabled keys and values.

## Ingress gateways

Use ingress gateways to configure ingress traffic routes into the service mesh.
You can add as many gateways as you need. For example, you can have one gateway
for private traffic and another for public traffic. Thus, you balance the
different loads independently from each other.

See the [ingress task](/docs/tasks/traffic-management/ingress/) for a
complete ingress gateway example.

## Egress gateways

Use egress gateways to configure an exit route for traffic leaving the mesh.
You can configure each egress gateway to use its own policies and telemetry.
You can use egress gateways if only particular application services can or
should access external networks.

Visit the [egress task](/docs/tasks/traffic-management/egress/) for a
complete egress gateway example.
