---
title: ServiceEntry visibility
description: Control which namespaces can discover and resolve each ServiceEntry.
weight: 40
keywords: [ambient,serviceentry,visibility]
owner: istio/wg-networking-maintainers
test: no
---

A [`ServiceEntry`](/docs/reference/config/networking/service-entry/) adds a service to Istio's internal service registry. By default, a `ServiceEntry` is visible to every workload in the mesh: anyone who can create a `ServiceEntry` in *any* namespace can define *any* hostname — for example `example.com` — and impact how the entire mesh resolves and routes to it.

The [`exportTo`](/docs/ops/configuration/mesh/configuration-scoping/) field does not protect against this, because it is declared by the author of the `ServiceEntry` itself: it lets a service owner scope what they publish, but places no firm constraint. Historically, a mesh administrator would need to constrain `ServiceEntry` creation with external admission control, such as a Kubernetes `ValidatingAdmissionPolicy` or webhook.

Beginning with Istio 1.31, the [`serviceEntryVisibility`](/docs/reference/config/istio.mesh.v1alpha1/#ServiceEntryVisibility) mesh configuration setting gives the mesh administrator that control, from a single place. The {{< gloss >}}ambient{{< /gloss >}} data plane ({{< gloss >}}ztunnel{{< /gloss >}} and {{< gloss "waypoint" >}}waypoints{{< /gloss >}}) honors visibility whenever it is configured; sidecars and gateways can [opt in](#extending-visibility-to-sidecars-and-gateways). The feature is inert unless configured: if `serviceEntryVisibility` is not set, nothing changes.

The design deliberately mirrors a familiar Kubernetes pattern: a `RoleBinding` has effect only within its own namespace, while creating cluster-wide effect with a `ClusterRoleBinding` is reserved for cluster administrators. `serviceEntryVisibility` lets the mesh administrator apply the same model to `ServiceEntry`: by setting `defaultVisibility: NAMESPACE`, an administrator makes every `ServiceEntry` behave like any other namespace-scoped resource, and visibility beyond a `ServiceEntry`'s own namespace becomes a capability the administrator explicitly grants.

## How visibility is resolved

When `serviceEntryVisibility` is configured, istiod resolves a visibility for each `ServiceEntry`:

1. The `policies` list is evaluated in order. The first policy whose `matchingRules` all match (AND semantics) determines the visibility.
1. If no policy matches, `defaultVisibility` applies.

Today, the only matching rule is `namespaceSelector`: a standard Kubernetes label selector evaluated against the labels of the **namespace the `ServiceEntry` is defined in**.

{{< tip >}}
Every namespace automatically carries the `kubernetes.io/metadata.name` label, so a `namespaceSelector` can match a namespace by name.
{{< /tip >}}

A `ServiceEntry` resolves to one of three visibilities:

| Visibility | Meaning |
| --- | --- |
| `PUBLIC` | Visible to every workload connected to this control plane. This is the existing behavior, and the default when `defaultVisibility` is unset. |
| `NAMESPACE` | Visible only within the namespace the `ServiceEntry` is defined in. |
| `NONE` | Visible to no one: the `ServiceEntry` may be written, but Istio configures no data plane for it. Useful to expressly forbid a class of `ServiceEntry`. |

See the [mesh configuration reference](/docs/reference/config/istio.mesh.v1alpha1/#ServiceEntryVisibility) for complete field documentation.

## Configure visibility

The following configuration keeps every `ServiceEntry` private to its own namespace, while allowing `ServiceEntry` resources in `istio-system` — a namespace only the mesh administrator can write to — to be published to the whole mesh:

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    serviceEntryVisibility:
      # ServiceEntries matching no policy below stay in their own namespace.
      defaultVisibility: NAMESPACE
      policies:
        # ServiceEntries in istio-system are visible mesh-wide.
        - visibility: PUBLIC
          matchingRules:
            - namespaceSelector:
                matchLabels:
                  kubernetes.io/metadata.name: istio-system
{{< /text >}}

Policies can also grant visibility to groups of namespaces. For example, a policy matching a `trusted: "true"` namespace label lets you delegate the ability to publish mesh-wide `ServiceEntry` resources by labeling namespaces.

## Visibility in ambient mode

When `serviceEntryVisibility` is configured, the ambient data plane always honors it. Istiod resolves the visibility of each `ServiceEntry` and distributes it with the service definition; ztunnel then applies it on the client side, based on the namespace of the workload making the request:

* A `PUBLIC` service behaves exactly as before.
* A `NAMESPACE` service can be discovered and resolved by workloads in its own namespace. For workloads in every other namespace, it is as if the `ServiceEntry` does not exist.
* A `NONE` service is never delivered to any data plane at all.

### Hidden means absent, not blocked

{{< warning >}}
Visibility hides a `ServiceEntry`; it does not block traffic. Clients outside the namespace do not receive `NXDOMAIN` responses or connection denials — they behave exactly as they would if the `ServiceEntry` had never been created.
{{< /warning >}}

This is deliberate: if ztunnel instead failed DNS queries for hidden hostnames, a `ServiceEntry` claiming `example.com` in one namespace would break `example.com` for the whole mesh — exactly the problem this feature exists to control. Concretely, for a client outside the `ServiceEntry`'s namespace:

* **DNS**: a query for the hidden hostname is forwarded to the upstream resolver, returning the real answer (or a real `NXDOMAIN` if the name does not exist publicly).
* **Addresses**: traffic to an IP address that only a hidden `ServiceEntry` claims is treated as unknown traffic and passed through to its original destination.
* **Shared hostnames**: if a hidden `ServiceEntry` and a `PUBLIC` one define the same hostname, clients outside the hidden entry's namespace are always served by the `PUBLIC` definition.

### Waypoints

Attaching a waypoint from another namespace to a `NAMESPACE`-visibility `ServiceEntry` would let traffic and configuration escape the namespace boundary, so the control plane refuses [cross-namespace waypoint](/docs/ambient/usage/waypoint/#usewaypointnamespace) bindings for them. The refusal is reported on the `ServiceEntry` status with the condition `istio.io/WaypointBound: False` and the reason `CrossNamespaceWaypointForbidden`.

Binding a waypoint in the *same* namespace works normally, and `PUBLIC` `ServiceEntry` resources are unaffected.

## Extending visibility to sidecars and gateways

In {{< gloss >}}sidecar{{< /gloss >}} mode, service owners already scope their `ServiceEntry` resources with `exportTo`, so honoring visibility is opt-in for sidecars, allowing incremental adoption during an ambient migration without changing a working sidecar deployment:

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    serviceEntryVisibility:
      defaultVisibility: NAMESPACE
      applyToSidecars: true
{{< /text >}}

With `applyToSidecars` enabled, the resolved visibility acts as a ceiling on the `ServiceEntry`'s `exportTo`: the effective scope is the intersection of the declared `exportTo` and the resolved visibility. Despite the field name, this applies to all Envoy-based proxies, including ingress and egress gateways.

Visibility can narrow what `exportTo` declares, but never widens it. In sidecar mode, `exportTo` is a [configuration scoping](/docs/ops/configuration/mesh/configuration-scoping/) mechanism that controls how much configuration istiod sends to each proxy. Widening it to match a broader visibility would push a `ServiceEntry`'s configuration back into proxies that its owner had deliberately scoped it out of. Visibility is therefore only ever a cap: a `ServiceEntry` with an `exportTo` narrower than its visibility keeps its narrower scope.

{{< tip >}}
Sidecar clients can only route to a `ServiceEntry` with an auto-allocated address if [DNS proxying](/docs/ops/configuration/traffic-management/dns-proxy/) is enabled. In ambient mode, ztunnel provides this DNS handling automatically.
{{< /tip >}}

## Verify visibility

When `serviceEntryVisibility` is configured, istiod reports the visibility the data plane received as a `ServiceEntry` status condition of type `istio.io/VisibilityApplied`, with the reason indicating the applied visibility:

{{< text syntax=bash >}}
$ kubectl get serviceentry my-service -n team-a -o jsonpath='{.status.conditions[?(@.type=="istio.io/VisibilityApplied")].reason}'
Namespace
{{< /text >}}

The condition's status is always `True`; the `reason` field carries the resolved visibility (`Public` or `Namespace`). When `serviceEntryVisibility` is not configured, the condition is not written.

{{< warning >}}
A `NONE` `ServiceEntry` currently receives no condition at all. This is a known limitation: do not use the absence of the condition to conclude that visibility is not being applied.
{{< /warning >}}

You can also inspect the visibility ztunnel is applying for every service it knows about. The JSON and YAML outputs of `istioctl ztunnel-config service` include a `visibility` field:

{{< text syntax=bash >}}
$ istioctl ztunnel-config service --service-namespace team-a -o yaml
{{< /text >}}

Kubernetes `Service`s always report `Public`; `ServiceEntry`-backed services report their resolved visibility. Additionally, ztunnel logs at `debug` level whenever it hides a service from a client during resolution.

## What visibility does not do

* **Visibility is not authorization.** Visibility controls whether a client can *discover and resolve* a service; it does not decide whether an inbound request is allowed. Use [`AuthorizationPolicy`](/docs/reference/config/security/authorization-policy/) to control which clients may access a workload — see [Layer 4 security policy](/docs/ambient/usage/l4-policy/).
* **Visibility is not secrecy.** Reducing the visibility of a `ServiceEntry` governs what client workloads resolve; it does not conceal the service's existence. The resource remains readable through the Kubernetes API according to RBAC, and the service still appears in data plane configuration dumps such as `istioctl ztunnel-config service`.
* **It applies to `ServiceEntry` only.** Kubernetes `Service`s are always visible mesh-wide in ambient mode.
* **There is no audit or warn-only mode.** When configured, visibility always takes effect.

## See also

* [`ServiceEntryVisibility` mesh configuration reference](/docs/reference/config/istio.mesh.v1alpha1/#ServiceEntryVisibility)
* [Configuration scoping](/docs/ops/configuration/mesh/configuration-scoping/) — `exportTo` and `Sidecar` for sidecar mode, plus `discoverySelectors`, which apply in every data plane mode
* [DNS proxying](/docs/ops/configuration/traffic-management/dns-proxy/)
* [Configure waypoint proxies](/docs/ambient/usage/waypoint/)
