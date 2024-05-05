---
title: Overview
description: An overview of Istio's ambient dataplane mode.
weight: 1
owner: istio/wg-docs-maintainers-english
test: no
---

In **ambient mode**, Istio implements its [features](/docs/concepts) using a per-node Layer 4 (L4) proxy, and optionally a per-namespace Layer 7 (L7) proxy. The mesh created when Istio is installed in ambient mode can be referred to as an ambient mesh.

Since workload pods no longer require proxies running in sidecars in order to participate in the mesh, Istio in ambient mode is often informally referred to as "sidecar-less" mesh.

This layered approach allows you to adopt Istio in a more incremental fashion, smoothly transitioning from no mesh, to the secure overlay, to full L7 processing — on a per-namespace basis, as needed. Furthermore, workloads running in different ambient configurations, or with sidecars, interoperate seamlessly, allowing users to mix and match capabilities based on the particular needs as they change over time.

## How it works

Ambient mode splits Istio’s functionality into two distinct layers. At the base, the **ztunnel** secure overlay handles routing and zero trust security for traffic. Above that, when needed, users can enable L7 **waypoint proxies** to get access to the full range of Istio features. Waypoint proxies, while heavier than the ztunnel overlay alone, still run as an ambient component of the infrastructure, requiring no modifications to application pods.

{{< tip >}}
Pods/workloads using sidecar proxies can co-exist within the same mesh as pods that operate in ambient mode. Mesh pods that use sidecar proxies can also interoperate with pods in the same Istio mesh that are running in ambient mode. The term "ambient mesh" refers to an Istio mesh that has a superset of the capabilities and hence can support mesh pods that use either type of proxying.
{{< /tip >}}

For details on the design of the ambient {{< gloss >}}data plane{{< /gloss >}}, and how it interacts with the Istio {{< gloss >}}control plane{{< /gloss >}}, see the [data plane](/docs/ambient/architecture/data-plane) and [control plane](/docs/ambient/architecture/control-plane) architecture documentation.

## ztunnel

The ztunnel (Zero Trust tunnel) component is a purpose-built, per-node proxy that powers Istio's ambient mode.

Ztunnel is responsible for securely connecting and authenticating workloads within the ambient mesh. The ztunnel proxy is written in Rust and is intentionally scoped to handle L3 and L4 functions such as mTLS, authentication, L4 authorization and telemetry. Ztunnel does not terminate workload HTTP traffic or parse workload HTTP headers. The ztunnel ensures L3 and L4 traffic is efficiently and securely transported to waypoint proxies, where the full suite of Istio’s L7 functionality, such as HTTP telemetry and load balancing, is implemented.

The term "secure overlay" is used to collectively describe the set of L4 networking functions implemented in an ambient mesh via the ztunnel proxy. At the transport layer, this is implemented via an HTTP CONNECT-based traffic tunneling protocol called [HBONE](/docs/ambient/architecture/hbone).

Some use cases of Istio in ambient mode may be addressed solely via the L4 secure overlay features, and will not need L7 features, thereby not requiring deployment of a waypoint proxy. Other use cases requiring advanced traffic management and L7 networking features will require deployment of a waypoint.

| Application deployment use case | Istio ambient mode configuration |
| ------------------------------- | -------------------------------- |
| Zero Trust networking via mutual-TLS, encrypted and tunneled data transport of client application traffic, L4 authorization, L4 telemetry | ztunnel only (default) |
| As above, plus advanced Istio traffic management features (incl L7 authorization, telemetry and VirtualService routing) | ztunnel and waypoint proxies |

## Waypoint proxies

The waypoint proxy is a deployment of the {{< gloss >}}Envoy{{</ gloss >}} proxy; the same engine that Istio uses in sidecar mode.

Waypoint proxies run outside of application pods. They are installed, upgraded, and scale independently from applications.
