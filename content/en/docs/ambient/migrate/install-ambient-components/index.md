---
title: Install ambient components
description: Add ztunnel and update the CNI to support ambient mode alongside existing sidecars.
weight: 2
owner: istio/wg-networking-maintainers
test: no
prev: /docs/ambient/migrate/before-you-begin
next: /docs/ambient/migrate/migrate-policies
---

This step upgrades your Istio installation to include the ambient data plane components
(ztunnel and updated CNI) while leaving all existing sidecar workloads without changes.
Your sidecars will continue to handle traffic normally throughout this step.

{{< warning >}}
Do not remove sidecar injection or add the `istio.io/dataplane-mode=ambient` label to any
namespace until the [Enable ambient mode](/docs/ambient/migrate/enable-ambient-mode/) step.
{{< /warning >}}

## Upgrade to the ambient profile

### Using istioctl

Upgrade your existing Istio installation to use the `ambient` profile. This adds the
ztunnel DaemonSet and updates the CNI plugin to support ambient mode:

{{< text syntax=bash snip_id=none >}}
$ istioctl upgrade --set profile=ambient
{{< /text >}}

{{< tip >}}
If you installed Istio with a custom `IstioOperator` or `--set` flags, you can combine
them with the ambient profile. For example:
`istioctl upgrade --set profile=ambient --set values.pilot.resources.requests.cpu=500m`
{{< /tip >}}

### Using Helm

If you installed Istio with Helm, upgrade each component to add ambient support:

{{< text syntax=bash snip_id=none >}}
$ helm upgrade istio-base istio/base -n istio-system
$ helm upgrade istiod istio/istiod -n istio-system --set profile=ambient
$ helm upgrade istio-cni istio/cni -n istio-system --set profile=ambient
$ helm install ztunnel istio/ztunnel -n istio-system
{{< /text >}}

## Verify the ambient components

After the upgrade completes, verify that ztunnel and the updated CNI are running:

{{< text syntax=bash snip_id=none >}}
$ kubectl get pods -n istio-system
{{< /text >}}

You should see the `ztunnel` DaemonSet pods running on every node, in addition to your
existing Istiod and CNI pods:

{{< text syntax=plain snip_id=none >}}
NAME                                   READY   STATUS    RESTARTS   AGE
istio-cni-node-...                     1/1     Running   0          2m
istiod-...                             1/1     Running   0          2m
ztunnel-...                            1/1     Running   0          2m
{{< /text >}}

Confirm ztunnel is running as a DaemonSet on all nodes:

{{< text syntax=bash snip_id=none >}}
$ kubectl get daemonset ztunnel -n istio-system
{{< /text >}}

## Enable HBONE support in existing sidecars

Sidecar proxies need to be restarted to pick up the new `ISTIO_META_ENABLE_HBONE=true`
configuration that the ambient profile sets in `MeshConfig`. This enables sidecars to
communicate with ambient-mode workloads using the HBONE protocol.

Restart each namespace that has sidecar injection enabled or restart your individual workloads based on your deployment strategy. For example, to restart a namespace:

{{< text syntax=bash snip_id=none >}}
$ kubectl rollout restart deployment -n <namespace>
$ kubectl rollout status deployment -n <namespace>
{{< /text >}}

Repeat for each namespace containing sidecar-injected workloads.

To verify that HBONE support is active on a restarted pod:

{{< text syntax=bash snip_id=none >}}
$ kubectl get pod <pod-name> -n <namespace> -o json | \
    jq '.spec.initContainers[] | select(.name=="istio-proxy") | .env[] | select(.name=="ISTIO_META_ENABLE_HBONE")'
{{< /text >}}

The output should show:

{{< text syntax=bash snip_id=none >}}
{
  "name": "ISTIO_META_ENABLE_HBONE",
  "value": "true"
}
{{< /text >}}

{{< tip >}}
At this stage your sidecars are still handling all traffic. The HBONE capability only
activates when a destination is discovered to be an ambient mode workload, so restarting
pods has no observable impact on traffic. If you run behavioral tests at this point, you should see no changes in functionality.
{{< /tip >}}

## Deploy waypoint proxies (optional)

{{< tip >}}
Skip this section if you only need L4 mTLS and authorization policies. Waypoints are only
required for L7 features. See [Migrate policies](/docs/ambient/migrate/migrate-policies/)
to determine if you need them.
{{< /tip >}}

For namespaces that require L7 features, deploy a waypoint proxy now. The waypoint will
be configured but **not yet activated**, traffic will continue to flow through sidecars.

Deploy a namespace scoped waypoint using `istioctl`:

{{< text syntax=bash snip_id=none >}}
$ istioctl waypoint apply -n <namespace>
{{< /text >}}

Verify the waypoint pod is running:

{{< text syntax=bash snip_id=none >}}
$ kubectl get gateway waypoint -n <namespace>
$ kubectl get pods -n <namespace> -l gateway.istio.io/managed=istio.io-mesh-controller
{{< /text >}}

{{< warning >}}
Do **not** add the `istio.io/use-waypoint` label to any namespace or service yet.
Activating waypoints before sidecars are removed can cause traffic to be processed twice.
Wait until the [Enable ambient mode](/docs/ambient/migrate/enable-ambient-mode/) step.
{{< /warning >}}

For more details on waypoint configuration options (service-level, workload-level, or
cross-namespace waypoints), see [Using waypoint proxies](/docs/ambient/usage/waypoint/).

## Next steps

Proceed to [Migrate policies](/docs/ambient/migrate/migrate-policies/) to update your traffic and
authorization policies for ambient mode.

If you have no `VirtualService` or `DestinationRule` resources, and your `AuthorizationPolicy`
resources only use L4 rules (no HTTP method/path/header matching), skip that page and go
directly to [Enable ambient mode](/docs/ambient/migrate/enable-ambient-mode/).
