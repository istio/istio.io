---
title: "Istio’s new sidecar-less ‘Ambient Mode’ reaches Beta in version 1.22"
description: The latest release from Istio brings service mesh Layer 4 & 7 features to production readiness without sidecars.
publishdate: 2024-05-13
attribution: "Lin Sun (Solo.io), for the Istio Steering and Technical Oversight Committees"
keywords: [Istio Day,Istio,conference,KubeCon,CloudNativeCon]
---

Istio ambient service mesh was [announced in September 2022](/blog/2022/introducing-ambient-mesh/) as an experimental branch
that introduced a new data plane mode in Istio that did not require sidecars, offering a simplified operational experience of
Istio. After 20 months of hard work and collaboration within the Istio community, with contributions from Solo.io, Google,
Microsoft, Intel, Aviatrix, Huawei, IBM, Red Hat, and others, we are excited to announce that ambient mode has reached Beta in
version 1.22! The beta release of 1.22 indicates the features of ambient mode are now ready for production workloads
with appropriate precautions. This is a huge milestone for Istio, bringing both Layer 4 and Layer 7 mesh features to production
readiness without sidecars.

## Why ambient mode?

We listened to the feedback from Istio users and observed a growing demand for mesh capabilities for their applications but
found the resource overhead and operational complexity of sidecars hard to overcome. Challenges that Istio sidecar users
have shared with us include: how Istio can break applications after sidecars are added, the large consumption of resources by
sidecars, and the inconvenience of the requirement to restart application pods with every new proxy release.

As a community, we listened and designed ambient mode to tackle these problems,
alleviating the previous barriers of complexity faced by users looking to implement service mesh. This new feature from Istio
was named 'ambient mode' as it was designed to be transparent to your application, ensuring no additional configuration was
required to adopt it and required no restarting of applications by users. In ambient mode it is trivial to add or remove
applications from the mesh. You can now simply label your namespace with `istio.io/dataplane-mode=ambient` and all applications
in the namespace are added to the mesh. This immediately secures all traffic with mTLS, all without sidecars or the need to
restart applications.

Refer to the [Introducing Ambient Mesh blog](/blog/2022/introducing-ambient-mesh/)
for more information on why we started ambient mode in Istio.

## How does ambient mode make adoption easier?

Istio’s ambient mode introduces lightweight, shared node proxies and optional Layer 7 (L7) proxies, which removes the need for
traditional sidecar proxies from the data plane. The core innovation behind ambient mode is that it slices the L4 and L7
processing into two distinct layers. This layered approach allows you to adopt Istio incrementally, enabling a smooth
transition from no mesh, to a secure overlay (L4), to optional full L7 processing — on a per-namespace basis, as needed across
your fleet.

Ambient mode works without any modification required to your existing Kubernetes deployments. Users can label a namespace to
add all of its workloads to Istio’s ambient mode, or opt-out certain deployments as needed. By utilizing ambient mode, users
bypass some of the previously restrictive elements of the sidecar model and instead can now expect server send-first protocols
to work, see most of the reserved ports are removed, and the ability for containers to bypass the sidecar – either
maliciously or not – is eliminated.

The lightweight shared L4 node proxy is called ztunnel (zero-trust tunnel). Ztunnel drastically reduces the overhead of
running a mesh by removing the need to potentially over provision memory and CPU within a cluster to handle expected loads. In
some use cases, the savings can exceed 90% or more, while still providing zero-trust security using mutual TLS with
cryptographic identity, simple L4 authorization policies, and telemetry.

The L7 proxies are called waypoints. Waypoints process L7 functions such as traffic routing, rich authorization policy
enforcement, and enterprise-grade resilience. Waypoints run outside of your application deployments and can scale independently
based on your needs, which could be for the entire namespace or for multiple services within the namespace. Compared with
sidecars, you don’t need one waypoint per application pod, and you can scale your waypoint effectively based on its scope,
thus saving significant amounts of CPU and memory in most cases.

The separation between the L4 secure overlay layer and L7 processing layer allows incremental adoption of the ambient mode data
plane in contrast to the earlier binary "all-in" injection of sidecars. Users can start with the secure overlay layer which
offers mTLS with cryptographic identity, simple L4 authorization policy, and telemetry. Later on, complex L7 handling such as
retries, traffic splitting, complex load balancing, and observability collection can be enabled on a case-by-case basis.

## What is in the scope of the Beta?

We recommend you explore the following Beta functions of ambient mode in production with appropriate precautions, after validating
them in test environments:

- [Install](/docs/ambient/install/).
- [Adding your workloads to the mesh](/docs/ambient/usage/add-workloads/) to gain mutual TLS with cryptographic identity, [L4 authorization policies](/docs/ambient/usage/l4-policy/), and telemetry.
- [Configure waypoints](/docs/ambient/usage/waypoint/) to [use L7 functions](/docs/ambient/usage/l7-features/) such as traffic shifting, request routing, rich authorization policy enforcement.
- Istio ingress gateway can work with workloads in ambient mesh supporting all existing Istio APIs.
- Use `istioctl` to operate waypoints, and troubleshoot ztunnel & waypoints.

### Alpha features

Other features we want to include in ambient mode have been implemented but remain in Alpha status in this release. Please help
test them, so they can be promoted to Beta in 1.23 or later:

- Multi-cluster installations
- DNS proxying
- Interoperability with sidecars
- IPv6/Dual stack
- SOCKS5 support (for outbound)
- Istio’s classic APIs (`VirtualService` and `DestinationRule`)

### Roadmap

We have a number of features which are not yet implemented in ambient mode but are planned for upcoming releases:

- Controlled egress traffic
- Multi-network support
- Improve `status` messages on resources to help troubleshoot and understand the mesh
- VM support

## What about sidecars?

Sidecars are not going away, and remain first-class citizens in Istio. You can continue to use sidecars and they will remain
fully supported.  For any feature outside of the Alpha or Beta scope for ambient mode, you should consider using the sidecar
mode until the feature is added to ambient mode. Some use cases, such as traffic shifting based on source labels, will
continue to be best implemented using the sidecar mode. While we believe most use cases will be best served with a mesh in
ambient mode, the Istio project remains committed to ongoing sidecar mode support.

## Try Istio’s new sidecar-less ambient mode

With the 1.22 release of Istio and the beta release of ambient mode, it will be easier than ever to try out Istio on your own
workloads. Follow the [getting started guide](/docs/ambient/getting-started/) to explore ambient or [user guide](/docs/ambient/usage/)
to learn how to incrementally adopt ambient for mutual TLS & L4 authorization policy, traffic management, rich L7
authorization policy, and more. Engage with us in the #ambient channel on our [Slack](https://slack.istio.io) or our discussion forum on
[GitHub](https://github.com/istio/istio/discussions) for any questions you may have.
