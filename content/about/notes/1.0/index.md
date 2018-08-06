---
title: Istio 1.0
weight: 92
page_icon: /img/notes.svg
---

We're proud to release Istio 1.0! Istio has been in development for nearly two years, and the 1.0 release represents a substantial
milestone for us. All of our [core features](/about/feature-stages/) are now ready for production use.

These release notes describe what's different between Istio 0.8 and Istio 1.0. Istio 1.0 only has a few new features
relative to 0.8 as most of the effort for this release went into fixing bugs and improving performance.

## Networking

- **SNI Routing using Virtual Services**. Newly introduced `TLS` sections in
[`VirtualService`](/docs/reference/config/istio.networking.v1alpha3/#VirtualService) can be used to route TLS traffic
based on SNI values. Service ports named as TLS/HTTPS can be used in conjunction with
virtual service TLS routes. TLS/HTTPS ports without an accompanying virtual service will be treated as opaque TCP.

- **Streaming gRPC Restored**. Istio 0.8 caused periodic termination of long running streaming gRPC connections. This has been fixed in 1.0.

- **Old (v1alpha1) Networking APIs Removed**. Support for the old `v1alpha1` traffic management model
has been removed.

- **Istio Ingress Deprecated**. The old Istio ingress is deprecated and disabled by default. We encourage users to use [gateways](/docs/concepts/traffic-management/#gateways) instead.

## Policy and Telemetry

- **Updated Attributes**. The set of [attributes](/docs/reference/config/policy-and-telemetry/attribute-vocabulary/) used to describe the source and
destination of traffic have been completely revamped in order to be more
precise and comprehensive.

- **Policy Check Cache**. Mixer now features a large level 2 cache for policy checks, complementing the level 1 cache
present in the sidecar proxy. This further reduces the average latency of externally-enforced
policy checks.

- **Telemetry Buffering**. Mixer now buffers report calls before dispatching to adapters, which gives an opportunity for
adapters to process telemetry data in bigger chunks, reducing overall computational overhead
in Mixer and its adapters.

- **Out of Process Adapters**. Mixer now includes initial support for out-of-process adapters. This will
be the recommended approach moving forward for integrating with Mixer. Initial documentation on
how to build an out-of-process adapter is provided by the
[Out Of Process Adapter Dev Guide](https://github.com/istio/istio/wiki/Mixer-Out-Of-Process-Adapter-Dev-Guide)
and the [Out Of Process Adapter Walk-through](https://github.com/istio/istio/wiki/Mixer-Out-Of-Process-Adapter-Walkthrough).

- **Client-Side Telemetry**. It's now possible to collect telemetry from the client of an interaction,
in addition to the server-side telemetry.

### Adapters

- **SignalFX**. There is a new [`signalfx`](/docs/reference/config/policy-and-telemetry/adapters/signalfx/) adapter.

- **Stackdriver**. The [`stackdriver`](/docs/reference/config/policy-and-telemetry/adapters/stackdriver/) adapter has been substantially enhanced in this
release to add new features and improve performance.

## Security

- **Authorization**. We've reimplemented our [authorization functionality](/docs/concepts/security/#authorization).
RPC-level authorization policies can now be implemented without the need for Mixer and Mixer adapters.

- **Improved Mutual TLS Authentication Control**. It's now easier to [control mutual TLS authentication](/docs/concepts/security/#authentication) between services. We provide 'PERMISSIVE' mode so that you can
[incrementally turn on mutual TLS](/docs/tasks/security/mtls-migration/) for your services.
We removed service annotations and have a [unique approach to turn on mutual TLS](/docs/tasks/security/authn-policy/),
coupled with client-side [destination rules](/docs/concepts/traffic-management/#destination-rules).

- **JWT Authentication**. We now support [JWT authentication](/docs/concepts/security/#authentication) which can
be configured using [authentication policies](/docs/concepts/security/#authentication-policies).

## `istioctl`

- Added the [`istioctl authn tls-check`](/docs/reference/commands/istioctl/#istioctl-authn-tls-check) command.

- Added the [`istioctl proxy-status`](/docs/reference/commands/istioctl/#istioctl-proxy-status) command.

- Added the `istioctl experimental convert-ingress` command.

- Removed the `istioctl experimental convert-networking-config` command.

- Enhancements and bug fixes:

    - Align `kubeconfig` handling with `kubectl`

    - `istioctl get all` returns all types of networking and authentication configuration.

    - Added the `--all-namespaces` flag to `istioctl get` to retrieve resources across all namespaces.

## Known issues with 1.0

- Amazon's EKS service does not implement automatic sidecar injection.  Istio can be used in Amazon's
  EKS by using [manual injection](/docs/setup/kubernetes/sidecar-injection/#manual-sidecar-injection) for
  sidecars and turning off galley using the [Helm parameter](/docs/setup/kubernetes/helm-install)
  `--set galley.enabled=false`.

- In a [multicluster deployment](/docs/setup/kubernetes/multicluster-install) the mixer-telemetry
  and mixer-policy components do not connect to the Kubernetes API endpoints of any of the remote
  clusters.  This results in a loss of telemetry fidelity as some of the metadata associated
  with workloads on remote clusters is incomplete.

- There are Kubernetes manifests available for using Citadel standalone or with Citadel health checking enabled.
  There is not a Helm implementation of these modes.  See [Issue 6922](https://github.com/istio/istio/issues/6922)
  for more details.

- Mesh expansion functionality, which lets you add raw VMs to a mesh is broken in 1.0. We're expecting to produce a
patch that fixes this problem within a few days.