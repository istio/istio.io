---
title: Migrate policies
description: Convert sidecar traffic and authorization policies for use in ambient mode.
weight: 3
owner: istio/wg-networking-maintainers
test: no
prev: /docs/ambient/migrate/install-ambient-components
next: /docs/ambient/migrate/enable-ambient-mode
---

{{< tip >}}
**You may be able to skip this page.** If you only use L4 `AuthorizationPolicy` rules
(with no `methods`, `paths`, or `headers` matching), have no `VirtualService` or
`DestinationRule` resources, and have no `EnvoyFilter`, `WasmPlugin`, or
`RequestAuthentication` resources, your existing policies will work in ambient mode without
changes. Go directly to [Enable ambient mode](/docs/ambient/migrate/enable-ambient-mode/).
{{< /tip >}}

In ambient mode, L7 traffic management is handled by {{< gloss >}}waypoint{{< /gloss >}}
proxies rather than sidecar proxies. This changes how policies are expressed and enforced:

- **`VirtualService`** support with waypoints is **Alpha**. While it may work in limited
  cases, migrating to `HTTPRoute` is strongly recommended. Mixing `VirtualService` and
  `HTTPRoute` for the same workload is not supported and leads to undefined behavior.
- **`DestinationRule`** traffic policies (connection pool settings, outlier detection, TLS)
  are supported by waypoints and require no changes. However, `HTTPRoute` uses Kubernetes
  Services as `backendRefs` for routing rather than DestinationRule subsets, so
  version based traffic splitting in `HTTPRoute` requires separate Services per version.
- **`AuthorizationPolicy`** resources that use L7 rules (HTTP methods, paths, or headers),
  or that use `action: CUSTOM` or `action: AUDIT`, must use `targetRefs` (instead of
  workload `selector`) to attach the policy to supported resources, for more information check the
  [AuthorizationPolicy documentation](/docs/reference/config/security/authorization-policy/#AuthorizationPolicy-targetRefs).
- **`RequestAuthentication`** and **`WasmPlugin`** resources require a waypoint proxy and
  must be targeted using `targetRefs` to point at the waypoint.
- **`EnvoyFilter`** resources are **not supported on waypoints**. If you have `EnvoyFilter`
  resources that configure sidecar proxy behavior, they will be silently ignored after
  migration and must be handled before proceeding:
    - If the filter adds custom Envoy functionality, evaluate whether a `WasmPlugin` can
      provide equivalent behavior on the waypoint.
    - If the filter is no longer needed, delete it.
    - If there is no ambient-compatible alternative, this is a migration blocker. Do not
      proceed until the dependency is resolved.

## Audit your existing policies

Start by listing all L7 resources in your cluster:

{{< text syntax=bash snip_id=none >}}
$ kubectl get virtualservice,destinationrule -A
{{< /text >}}

Identify `AuthorizationPolicy` resources that will require a waypoint (L7 rules or
`CUSTOM`/`AUDIT` actions):

{{< text syntax=bash snip_id=none >}}
$ kubectl get authorizationpolicy -A --no-headers | while read ns name rest; do
    if kubectl get authorizationpolicy "$name" -n "$ns" -o yaml | grep -qE "(methods:|paths:|headers:|action: CUSTOM|action: AUDIT)"; then
      echo "$ns/$name"
    fi
  done
{{< /text >}}

Identify `DestinationRule` resources with subsets (these require version-specific Services
in ambient mode):

{{< text syntax=bash snip_id=none >}}
$ kubectl get destinationrule -A --no-headers | while read ns name rest; do
    if kubectl get destinationrule "$name" -n "$ns" -o yaml | grep -q "subsets:"; then
      echo "$ns/$name"
    fi
  done
{{< /text >}}

## Migrate VirtualService to HTTPRoute

{{< warning >}}
`VirtualService` support with waypoints is Alpha and may break in future releases.
Migrate your `VirtualService` resources to `HTTPRoute` before completing the migration.
Do not leave both `VirtualService` and `HTTPRoute` resources targeting the same workload, as
this leads to undefined behavior.
{{< /warning >}}

`HTTPRoute` is the stable, supported L7 routing API for ambient mode.

{{< tip >}}
The community tool [ingress2gateway](https://github.com/kubernetes-sigs/ingress2gateway)
can automate part of this conversion. Its
[Istio provider](https://github.com/kubernetes-sigs/ingress2gateway/blob/main/pkg/i2gw/providers/istio/README.md)
translates `VirtualService` resources to `HTTPRoute`, `TLSRoute`, and `TCPRoute`, and
generates `ReferenceGrant` resources for cross-namespace references. Fields that cannot
be translated directly are logged and skipped, so always review the generated output
before applying it to your cluster. Note that also IngressGateway resources are translated to Gateway API Gateway resources, so this tool can be used for the migration of both VirtualService and Gateway resources.
{{< /tip >}}

### Example: Header-based routing

The following `VirtualService` routes requests with `end-user: jason` to `reviews` version 2,
and all other requests to version 1 using subsets:

{{< text syntax=yaml snip_id=none >}}
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: reviews
spec:
  hosts:
  - reviews
  http:
  - match:
    - headers:
        end-user:
          exact: jason
    route:
    - destination:
        host: reviews
        subset: v2
  - route:
    - destination:
        host: reviews
        subset: v1
{{< /text >}}

Because `HTTPRoute` does not support DestinationRule subsets, you must first create
version specific Services:

{{< text syntax=yaml snip_id=none >}}
apiVersion: v1
kind: Service
metadata:
  name: reviews-v1
  namespace: bookinfo
spec:
  selector:
    app: reviews
    version: v1
  ports:
  - port: 9080
    name: http
---
apiVersion: v1
kind: Service
metadata:
  name: reviews-v2
  namespace: bookinfo
spec:
  selector:
    app: reviews
    version: v2
  ports:
  - port: 9080
    name: http
{{< /text >}}

Then replace the `VirtualService` with an `HTTPRoute` that attaches to the `reviews` Service
directly (using `kind: Service` as the `parentRef`). This is the correct attachment model for
ambient mode — the waypoint uses the Service as the routing anchor:

{{< text syntax=yaml snip_id=none >}}
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: reviews
  namespace: bookinfo
spec:
  parentRefs:
  - group: ""
    kind: Service
    name: reviews
    port: 9080
  rules:
  - matches:
    - headers:
      - name: end-user
        value: jason
    backendRefs:
    - name: reviews-v2
      port: 9080
  - backendRefs:
    - name: reviews-v1
      port: 9080
{{< /text >}}

For a complete reference on `HTTPRoute` capabilities, see the
[traffic management documentation](/docs/tasks/traffic-management/).

## Migrate AuthorizationPolicy for L7 rules

In sidecar mode, `AuthorizationPolicy` resources use a `selector` to target pods directly.
In ambient mode, L7 authorization policies must be enforced by a waypoint proxy and therefore
must use `targetRefs` to target the waypoint's parent `Service` or the `Gateway` itself.

### L4 policies (no change required)

L4 `AuthorizationPolicy` resources that only match on source principals, namespaces, or IP
ranges work in ambient mode without modification. They are enforced by ztunnel.

{{< text syntax=yaml snip_id=none >}}
# This L4 policy requires no changes for ambient mode
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: allow-frontend
  namespace: bookinfo
spec:
  selector:
    matchLabels:
      app: reviews
  action: ALLOW
  rules:
  - from:
    - source:
        principals: ["cluster.local/ns/bookinfo/sa/productpage"]
{{< /text >}}

### L7 policies

{{< warning >}}
Migrating L7 policies involves a brief enforcement gap. Old selector based policies must
be removed before or at pod restart, and new waypoint based policies take effect
immediately once created. Between these two operations, L7 rules are not applied. If
continuous L7 policy enforcement is required, plan a maintenance window. This gap is a known limitation and is being tracked for improvement in future releases.
{{< /warning >}}

Policies that match on HTTP methods, paths, or headers, or that use `action: CUSTOM` or
`action: AUDIT`, must target a waypoint proxy. Replace `selector` with `targetRefs`
pointing to the `Service` the waypoint protects, or to the waypoint `Gateway` resource
itself:

{{< text syntax=yaml snip_id=none >}}
# Before: sidecar-style (selector based)
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: allow-get-reviews
  namespace: bookinfo
spec:
  selector:
    matchLabels:
      app: reviews
  action: ALLOW
  rules:
  - to:
    - operation:
        methods: ["GET"]
{{< /text >}}

{{< text syntax=yaml snip_id=none >}}
# After: ambient-style (targetRefs to Service)
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: allow-get-reviews
  namespace: bookinfo
spec:
  targetRefs:
  - kind: Service
    group: ""
    name: reviews
  action: ALLOW
  rules:
  - to:
    - operation:
        methods: ["GET"]
{{< /text >}}

Alternatively, you can target the waypoint `Gateway` resource directly. This applies the
policy to all traffic processed by the waypoint, regardless of the destination Service:

{{< text syntax=yaml snip_id=none >}}
# After: ambient-style (targetRefs to waypoint Gateway)
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: allow-get-reviews
  namespace: bookinfo
spec:
  targetRefs:
  - kind: Gateway
    group: gateway.networking.k8s.io
    name: waypoint
  action: ALLOW
  rules:
  - to:
    - operation:
        methods: ["GET"]
{{< /text >}}

Targeting a `Service` is the more precise option and is recommended when the policy
should apply to a single service. Targeting the `Gateway` is useful when the policy
should apply to all services in the namespace.

## Prevent waypoint bypass

When a waypoint is used, ensure that workloads cannot be reached by bypassing it. Use a
workload `selector` DENY policy enforced by **ztunnel** (at the destination pod). Since
this policy only checks the source principal (an L4 attribute), ztunnel can enforce it
correctly.

{{< warning >}}
Do not use `targetRefs` for this policy. A `targetRefs` based DENY policy is enforced by
the waypoint, which sees the original client identity, not the waypoint's own identity.
This would cause the waypoint to deny all client traffic before the ALLOW policy can run.
{{< /warning >}}

### Decide when to apply bypass prevention

During an incremental migration, some source workloads may still be in sidecar mode.
Sidecar mode workloads bypass the waypoint and connect directly to ztunnel at the
destination, so ztunnel sees the sidecar identity as the source principal, not the
waypoint identity. A strict waypoint only DENY policy will reject their traffic.

Choose one of the following options before applying the policy:

**Option 1: Delay bypass prevention until all sources are migrated.**
Do not apply the DENY policy until every workload that calls this service has moved to
ambient mode. This is the simpler approach when you control all callers.

**Option 2: Allow traffic from both the waypoint and sidecar principals.**
Apply the policy immediately, but add the service accounts of the remaining sidecar
workloads to the `notPrincipals` exception list alongside the waypoint. Remove each
sidecar principal from the list as it is migrated. Once all callers are in ambient mode,
only the waypoint principal needs to remain.

### Apply the bypass prevention policy

Look up the service account used by your waypoint:

{{< text syntax=bash snip_id=none >}}
$ kubectl get pod -n <namespace> -l gateway.istio.io/managed=istio.io-mesh-controller \
    -o jsonpath='{.items[0].spec.serviceAccountName}'
{{< /text >}}

For Option 1, apply the policy only after all callers are migrated:

{{< text syntax=yaml snip_id=none >}}
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: deny-waypoint-bypass
  namespace: bookinfo
spec:
  selector:
    matchLabels:
      app: reviews
  action: DENY
  rules:
  - from:
    - source:
        notPrincipals:
        - "cluster.local/ns/bookinfo/sa/waypoint"
{{< /text >}}

For Option 2, include sidecar principals in the exception list during migration:

{{< text syntax=yaml snip_id=none >}}
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: deny-waypoint-bypass
  namespace: bookinfo
spec:
  selector:
    matchLabels:
      app: reviews
  action: DENY
  rules:
  - from:
    - source:
        notPrincipals:
        - "cluster.local/ns/bookinfo/sa/waypoint"
        - "cluster.local/ns/bookinfo/sa/productpage"
{{< /text >}}

{{< warning >}}
Keep your existing sidecar `AuthorizationPolicy` resources active until pods have been
restarted without sidecars. However, **delete them immediately after the pod restart** —
do not wait for full validation. Any `AuthorizationPolicy` using a workload `selector`
with L7 rules (HTTP methods, paths, or headers) that remains active after sidecars are
removed will be picked up by ztunnel, which cannot enforce L7 rules and will convert it
into a `DENY` policy for all traffic to that workload.
{{< /warning >}}

## Next steps

Proceed to [Enable ambient mode](/docs/ambient/migrate/enable-ambient-mode/) to label
namespaces, activate waypoints, and remove sidecar injection.
