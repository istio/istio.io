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
- **`DestinationRule`** subset-based routing is not supported by waypoints. Subsets must be
  replaced with individual Kubernetes Services per version.
- **`AuthorizationPolicy`** resources that use L7 rules (HTTP methods, paths, or headers),
  or that use `action: CUSTOM` or `action: AUDIT`, must target waypoint proxies via
  `targetRefs` rather than using workload `selector`.
- **`RequestAuthentication`**, **`EnvoyFilter`**, and **`WasmPlugin`** resources require
  a waypoint proxy and may need updates to target the waypoint correctly.

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

Policies that match on HTTP methods, paths, or headers, or that use `action: CUSTOM` or
`action: AUDIT`, must target a waypoint proxy. Replace `selector` with `targetRefs`
pointing to the `Service` the waypoint protects:

{{< text syntax=yaml snip_id=none >}}
# Before: sidecar-style (selector-based)
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

## Prevent waypoint bypass

When a waypoint is used, ensure that workloads cannot be reached by bypassing it. This
policy must be enforced by **ztunnel** (at the destination pod), not by the waypoint itself.
Use a workload `selector` so that ztunnel denies any traffic that did not come from the
waypoint. Since this only checks the source principal (an L4 attribute), ztunnel can
enforce it correctly.

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

Replace `bookinfo/sa/waypoint` with the actual service account used by your waypoint:

{{< text syntax=bash snip_id=none >}}
$ kubectl get pod -n <namespace> -l gateway.istio.io/managed=istio.io-mesh-controller \
    -o jsonpath='{.items[0].spec.serviceAccountName}'
{{< /text >}}

{{< warning >}}
Do not use `targetRefs` for this policy. A `targetRefs` based DENY policy is enforced by
the waypoint, which sees the original client identity not the waypoint's own identity.
This would cause the waypoint to deny all client traffic before the ALLOW policy can run.
{{< /warning >}}

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
