---
title: Third Party Load Balancers
description: How to integrate Istio with third party load balancers.
weight: 90
keywords: [traffic-management,ingress]
owner: istio/wg-networking-maintainers
test: n/a
---

Istio provides both an ingress and service mesh implementation, which can be used
together or separately. While these are designed to work together seamlessly, there
are times when integrating with a third party ingress is required. This could be
for migration purposes, feature requirements, or personal preferences.

## Integration Modes

In "standalone" mode, the third party ingress is directly sending to backends.
In this case, the backends presumably have Istio sidecars injected.

{{< mermaid >}}
graph LR
    cc((Client))
    tpi(Third Party Ingress)
    a(Backend)
    cc-->tpi-->a
{{< /mermaid >}}

In this mode, things mostly just work.
Clients in a service mesh do not need to be aware that the backend they are connecting to has a sidecar.
However, the ingress will not use mTLS, which may lead to undesirable behavior.
As a result, most of the configuration for this setup is around enabling mTLS.

In "chained" mode, we use both the third party ingress *and* Istio's own Gateway in sequence.
This can be useful when you want the functionality of both layers.
In particular, this is useful with managed cloud load balancers, which have features like global addresses and managed certificates.

{{< mermaid >}}
graph LR
    cc((Client))
    tpi(Third Party Ingress)
    ii(Istio Gateway)
    a(Backend)
    cc-->tpi
    tpi-->ii
    ii-->a
{{< /mermaid >}}

## Cloud Load Balancers

Generally, cloud load balancers will work out of the box in standalone mode without mTLS.
Vendor specific configuration is required to support chained mode or standalone with mTLS.

### Google HTTP(S) Load Balancer

Integration with Google HTTP(S) Load Balancers only works out of the box with standalone mode
if mTLS is not required as mTLS is not supported.

Chained mode is possible. See
[Google documentation](https://cloud.google.com/architecture/exposing-service-mesh-apps-through-gke-ingress)
for setup instructions.

## In-Cluster Load Balancers

Generally, in-cluster load balancers will work out of the box in standalone mode without mTLS.

Standalone mode with mTLS can be achieved by inserting a sidecar into the Pod of the in-cluster load balancer.
This typically involves two steps beyond standard sidecar injection:

1. Disable inbound traffic redirection.
   While not required, typically we only want to use the sidecar for *outbound* traffic - inbound connection from clients is already handled by the load balancer itself.
   This also allows preserving the original client IP address, which would otherwise be lost by the sidecar.
   This mode can be enabled by inserting the `traffic.sidecar.istio.io/includeInboundPorts: ""` annotation on the load balancer `Pod`s.
1. Enable Service routing.
   Istio sidecars can only properly function when requests are sent to Services, not to specific pod IPs.
   Most load balancers will send to specific pod IPs by default, breaking mTLS.
   Steps to do this are vendor specific; a few examples are listed below but consulting with the specific vendor's documentation is recommended.

   Alternatively, setting the `Host` header to the service name can also work.
   However, this can result in unexpected behavior; the load balancer will pick a specific pod, but Istio will ignore it.
   See [here](/docs/ops/configuration/traffic-management/traffic-routing/#http) for more information on why this works.

### ingress-nginx

`ingress-nginx` can be configured to do service routing by inserting an annotation on `Ingress` resources:

{{< text yaml >}}
nginx.ingress.kubernetes.io/service-upstream: "true"
{{< /text >}}

### Emissary-Ingress

Emissary-ingress defaults to using Service routing, so no additional steps are required.
