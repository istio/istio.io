---
title: Add workloads to the mesh
description: Understand how to add workloads to an ambient mesh.
weight: 1
owner: istio/wg-networking-maintainers
test: no
---

In most cases, a cluster administrator will deploy the Istio mesh infrastructure. Once Istio is successfully deployed in ambient mode, it will be transparently available to applications deployed by all users in namespaces that have been configured to use it.

## Enabling ambient for an application

To add an applications or namespaces to the ambient mesh, add the label `istio.io/dataplane-mode=ambient` to the corresponding resource. You can apply this label to a namespace or to an individual pod.

Ambient mode can be seamlessly enabled (or disabled) completely transparently as far as the application pods are concerned. Unlike when operating in {{< gloss >}}sidecar{{< /gloss >}} mode, there is no need to restart applications to add them to the mesh, and they will not show as having an extra container deployed in their pod.

## Communicating between pods in different modes

There are multiple options for interoperability between ambient pods and non-ambient endpoints (including Kubernetes application pods, Istio gateways or Kubernetes Gateway API instances). This interoperability provides multiple options for seamlessly integrating ambient and non-ambient workloads within the same Istio mesh, allowing for phased introduction of ambient capability as best suits the needs of your mesh deployment and operation.

### Pods outside the mesh

You may have namespaces which are not part of the mesh at all, in either sidecar or ambient mode. In this case, the non-mesh pods initiate traffic directly to the destination pods without going through the source node's ztunnel, while the destination pod's ztunnel enforces any L4 policy to control whether traffic should be allowed or denied.

For example, setting a `PeerAuthentication` policy with mTLS mode set to `STRICT`, in the ambient namespace will cause traffic from outside the mesh to be denied.

### Pods inside the mesh in sidecar mode

Istio supports East-West interoperability between a pod using a sidecar proxy and an ambient pod within the same mesh. The sidecar proxy knows to use the HBONE protocol since the destination has been discovered to be an HBONE destination.

{{< tip >}}
For sidecar proxies to use the HBONE/mTLS signaling option when communicating with ambient destinations, they need to be configured with `ISTIO_META_ENABLE_HBONE` set to `true` in the proxy metadata. This is the default in `MeshConfig` when using the `ambient` profile, hence you do not have to do anything else when using this profile.
{{< /tip >}}

A `PeerAuthentication` policy with mTLS mode set to `STRICT` will allow traffic from a pod with an Istio sidecar proxy.

### Ingress and egress gateways and ambient pods

An ingress gateway may run in a non-ambient namespace, and expose services provided by ambient, sidecar and non-mesh pods. Interoperability is also supported between pods in an ambient mesh and Istio egress gateways.

## Pod selection logic for ambient and sidecar modes

Istio with sidecar proxies can co-exist with ambient based node level proxies within the same cluster. It is important to ensure that the same pod or namespace does not get configured to use both a sidecar proxy and ambient mode. However, if this does occur, currently sidecar injection takes precedence for such a pod or namespace.

Note that two pods within the same namespace could in theory be set to use different modes by labeling individual pods separately from the namespace label, however this is not recommended. For most common use cases a single mode should be used for all pods within a single namespace.

The exact logic to determine whether a pod is set up to use ambient mode is as follows.

1. The `istio-cni` plugin configuration exclude list configured in `cni.values.excludeNamespaces` is used to skip namespaces in the exclude list.
1. `ambient` mode is used for a pod if

    * The namespace or pod has the label `istio.io/dataplane-mode=ambient`
    * The pod does not have the opt-out label `istio.io/dataplane-mode=none`
    * The annotation `sidecar.istio.io/status` is not present on the pod

The simplest option to avoid a configuration conflict is for a user to ensure that for each namespace, it either has the label for sidecar injection (`istio-injection=enabled`) or for ambient mode (`istio.io/dataplane-mode=ambient`) but never both.

## Label reference {#ambient-labels}

You can use the following labels to add your resource to the {{< gloss >}}ambient{{< /gloss >}} mesh and manage L4 traffic with the ambient {{< gloss >}}data plane{{< /gloss >}}, use a waypoint to enforce L7 policy for your resource, and control how traffic is sent to the waypoint.

|  Name  | Feature Status | Resource | Description |
| --- | --- | --- | --- |
| `istio.io/dataplane-mode` | Beta | `Namespace` or `Pod` (latter has precedence) |  Add your resource to an ambient mesh. <br><br> Valid values: `ambient` or `none`. |
| `istio.io/use-waypoint` | Beta | `Namespace`, `Service` or `Pod` | Use a waypoint for traffic to the labeled resource for L7 policy enforcement. <br><br> Valid values: `{waypoint-name}`, `{namespace}/{waypoint-name}`, or `#none` (with hash). |
| `istio.io/waypoint-for` | Alpha | `Gateway` | Specifies what types of endpoints the waypoint will process traffic for. <br><br> Valid values: `service`, `workload`, `none` or `all`. This label is optional and the default value is `service`. |

In order for your `istio.io/use-waypoint` label value to be effective, you have to ensure the waypoint is configured for the endpoint which is using it. By default waypoints accept traffic for service endpoints. For example, when you label a pod to use a specific waypoint via the `istio.io/use-waypoint` label, the waypoint should be labeled `istio.io./waypoint-for` with the value `workload` or `all`.
