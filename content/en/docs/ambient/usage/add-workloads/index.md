---
title: Add workloads to the mesh
description: Understand how to add workloads to an ambient mesh.
weight: 10
owner: istio/wg-networking-maintainers
test: no
---

In most cases, a cluster administrator will deploy the Istio mesh infrastructure. Once Istio is successfully deployed with support for the ambient {{< gloss >}}data plane{{< /gloss >}} mode, it will be transparently available to applications deployed by all users in namespaces that have been configured to use it.

## Enabling ambient mode for applications in the mesh

To add applications or namespaces to the mesh in ambient mode, add the label `istio.io/dataplane-mode=ambient` to the corresponding resource. You can apply this label to a namespace or to an individual pod.

Ambient mode can be seamlessly enabled (or disabled) completely transparently as far as the application pods are concerned. Unlike the {{< gloss >}}sidecar{{< /gloss >}} data plane mode, there is no need to restart applications to add them to the mesh, and they will not show as having an extra container deployed in their pod.

### Layer 4 and Layer 7 functionality

The secure L4 overlay supports authentication and authorization policies. [Learn about L4 policy support in ambient mode](/docs/ambient/usage/l4-policy/). To opt-in to use Istio's L7 functionality, such as traffic routing, you will need to [deploy a waypoint proxy and enroll your workloads to use it](/docs/ambient/usage/waypoint/).

### Ambient and Kubernetes NetworkPolicy

See [ambient and Kubernetes NetworkPolicy](/docs/ambient/usage/networkpolicy/).

## Communicating between pods in different data plane modes

There are multiple options for interoperability between application pods using the ambient data plane mode, and non-ambient endpoints (including Kubernetes application pods, Istio gateways or Kubernetes Gateway API instances). This interoperability provides multiple options for seamlessly integrating ambient and non-ambient workloads within the same Istio mesh, allowing for phased introduction of ambient capability as best suits the needs of your mesh deployment and operation.

### Pods outside the mesh

You may have namespaces which are not part of the mesh at all, in either sidecar or ambient mode. In this case, the non-mesh pods initiate traffic directly to the destination pods without going through the source node's ztunnel, while the destination pod's ztunnel enforces any L4 policy to control whether traffic should be allowed or denied.

For example, setting a `PeerAuthentication` policy with mTLS mode set to `STRICT`, in a namespace with ambient mode enabled, will cause traffic from outside the mesh to be denied.

### Pods inside the mesh using sidecar mode

Istio supports East-West interoperability between a pod with a sidecar and a pod using ambient mode, within the same mesh. The sidecar proxy knows to use the HBONE protocol since the destination has been discovered to be an HBONE destination.

{{< tip >}}
For sidecar proxies to use the HBONE/mTLS signaling option when communicating with ambient destinations, they need to be configured with `ISTIO_META_ENABLE_HBONE` set to `true` in the proxy metadata. This is the default in `MeshConfig` when using the `ambient` profile, hence you do not have to do anything else when using this profile.
{{< /tip >}}

A `PeerAuthentication` policy with mTLS mode set to `STRICT` will allow traffic from a pod with an Istio sidecar proxy.

### Ingress and egress gateways and ambient mode pods

An ingress gateway may run in a non-ambient namespace, and expose services provided by ambient mode, sidecar mode or non-mesh pods. Interoperability is also supported between pods in ambient mode and Istio egress gateways.

## Pod selection logic for ambient and sidecar modes

Istio's two data plane modes, sidecar and ambient, can co-exist in the same cluster. It is important to ensure that the same pod or namespace does not get configured to use both modes at the same time. However, if this does occur, the sidecar mode currently takes precedence for such a pod or namespace.

Note that two pods within the same namespace could in theory be set to use different modes by labeling individual pods separately from the namespace label; however, this is not recommended. For most common use cases a single mode should be used for all pods within a single namespace.

The exact logic to determine whether a pod is set up to use ambient mode is as follows:

1. The `istio-cni` plugin configuration exclude list configured in `cni.values.excludeNamespaces` is used to skip namespaces in the exclude list.
1. `ambient` mode is used for a pod if

    * The namespace or pod has the label `istio.io/dataplane-mode=ambient`
    * The pod does not have the opt-out label `istio.io/dataplane-mode=none`
    * The annotation `sidecar.istio.io/status` is not present on the pod

The simplest option to avoid a configuration conflict is for a user to ensure that for each namespace, it either has the label for sidecar injection (`istio-injection=enabled`) or for ambient mode (`istio.io/dataplane-mode=ambient`), but never both.

## Label reference {#ambient-labels}

The following labels control if a resource is included in the mesh in ambient mode, if a waypoint proxy is used to enforce L7 policy for your resource, and to control how traffic is sent to the waypoint.

|  Name  | Feature Status | Resource | Description |
| --- | --- | --- | --- |
| `istio.io/dataplane-mode` | Beta | `Namespace` or `Pod` (latter has precedence) |  Add your resource to an ambient mesh. <br><br> Valid values: `ambient` or `none`. |
| `istio.io/use-waypoint` | Beta | `Namespace`, `Service` or `Pod` | Use a waypoint for traffic to the labeled resource for L7 policy enforcement. <br><br> Valid values: `{waypoint-name}` or `none`. |
| `istio.io/waypoint-for` | Alpha | `Gateway` | Specifies what types of endpoints the waypoint will process traffic for. <br><br> Valid values: `service`, `workload`, `none` or `all`. This label is optional and the default value is `service`. |

In order for your `istio.io/use-waypoint` label value to be effective, you have to ensure the waypoint is configured for the resource types it will be handling traffic for. By default waypoints accept traffic for services. For example, when you label a pod to use a specific waypoint via the `istio.io/use-waypoint` label, the waypoint should be labeled `istio.io./waypoint-for` with the value `workload` or `all`.
