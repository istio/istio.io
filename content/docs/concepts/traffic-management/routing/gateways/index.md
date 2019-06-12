---
title: Gateways
description: Learn about using gateways to configure how the Envoy proxies load balance HTTP, TCP, or gRPC traffic.
weight: 3
keywords: [traffic-management, http, tcp, grpc, ingress, egress]
---

You use a [gateway](/docs/reference/config/networking/v1alpha3/gateway/) to
manage inbound and outbound traffic for your mesh. You can manage
[multiple types of traffic](/docs/reference/config/networking/v1alpha3/gateway/#Port)
with a gateway.

Gateway configurations apply to Envoy proxies that are separate from the
service sidecar proxies. To configure a gateway means configuring an Envoy
proxy to allow or block certain traffic from entering or leaving the mesh.

Your mesh can have any number of gateway configurations, and multiple gateway
workload implementations can co-exist within your mesh. You might use multiple
gateways to have one gateway for private traffic and another for public
traffic, so you can keep all private traffic inside a firewall, for example.

For better security, you can use a gateway to make your services inaccessible
to the public internet. You can use a gateway to configure workload labels for
your existing network tasks, including:

-  Firewall functions
-  Caching
-  Authentication
-  Network address translation
-  IP address management

Gateways are primarily used to manage ingress traffic, but you can also use a
gateway to configure an egress gateway. You can use egress gateways to
configure a dedicated exit node for the traffic leaving the mesh and configure
each egress gateway to use its own policies and telemetry.

You can use egress gateways to limit which services can or should access
external networks, or to enable [secure control of egress
traffic](/blog/2019/egress-traffic-control-in-istio-part-1/) to add security to
your mesh, for example. The following diagram shows the basic model of a
request flowing through a service mesh with an ingress gateway and an egress
gateway.

{{< image width="70%"
    link="./gateways-1.svg"
    caption="Request flow"
    >}}

All traffic enters the mesh through an ingress gateway workload. To configure
the traffic, use an Istio gateway and a virtual service. You bind the virtual
service to the gateway to use standard Istio [routing rules](/docs/concepts/traffic-management/routing/virtual-services/#routing-rules)
to control HTTP requests and TCP traffic entering the mesh.

## Configure a gateway for external HTTPS traffic

The following example shows a possible gateway configuration for external HTTPS
ingress traffic:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: ext-host-gwy
spec:
  selector:
    app: my-gateway-controller
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

This gateway configuration lets HTTPS traffic from `ext-host` into the mesh on
port 443, but doesn't specify any routing for the traffic.

### Bind a gateway to a virtual service

To specify routing and for the gateway to work as intended, you must also bind
the gateway to a virtual service. You do this using the virtual service's
`gateways:` field, as shown in the following example:

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

You can then configure the virtual service with routing rules for the external
traffic. The following diagram shows the configured routes for the external
HTTPS traffic to the `my-svc` service within the mesh:

{{< image width="70%"
    link="./gateways-2.svg"
    caption="Configurable routes for the external HTTPS traffic"
    >}}

For more information:

-  Refer to the [gateways reference documentation](/docs/reference/config/networking/v1alpha3/gateway/)
   to review all the enabled keys and values.

-  Refer to the [Ingress task topic](/docs/tasks/traffic-management/ingress/) for instructions, including how to configure
   an Istio gateway for Kubernetes ingress.

-  Refer to the [Egress task topic](/docs/tasks/traffic-management/egress/) to learn how to configure egress traffic
   using a gateway network resource.
