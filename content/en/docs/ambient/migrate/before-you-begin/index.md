---
title: Before you begin
description: Verify your environment and prepare for migration.
weight: 1
owner: istio/wg-networking-maintainers
test: no
prev: /docs/ambient/migrate
next: /docs/ambient/migrate/install-ambient-components
---

Before migrating from sidecar to ambient mode, verify that your environment meets the
requirements and create a backup of your current configuration.

{{< warning >}}
**If your workloads use L7 policies, migration is not straightforward and currently has
known limitations:**

- During migration, there is a window where L7 policies may not be enforced, old
  selector-based policies must be removed, and new waypoint-based equivalents must take
  their place. There is no atomic handoff between the two.
- While some source workloads are still in sidecar mode, traffic from those workloads
  bypasses waypoints entirely. L7 policies on the waypoint are not enforced for that
  traffic path until the source is also migrated.

**Zero-downtime migration with L7 policies is not currently supported.** Plan a
maintenance window. This is a known limitation being tracked for improvement in a future
release.

If your workloads only use L4 `AuthorizationPolicy` rules (source principal, namespace,
or IP matching, no HTTP methods, paths, or headers), this does not apply and the
migration requires no policy changes.
{{< /warning >}}

## Background: how policy enforcement changes

Understanding the key differences between sidecar and ambient policy enforcement will help
you understand the migration steps and anticipate where changes are needed.

**In sidecar mode:**
- Policies use a `selector` to target pods by label.
- The destination sidecar proxy enforces both L4 and L7 policies.
- A single `AuthorizationPolicy` can match on source principal, HTTP method, path, or header
  and be enforced at the destination pod.

**In ambient mode:**
- L4 enforcement is handled by **ztunnel**, which runs on every node.
- L7 enforcement requires a **waypoint proxy** deployed per namespace or service.
- Policies enforced by a waypoint must use `targetRefs` pointing to a `Service` or
  `Gateway`, not a pod `selector`. You cannot reuse selector based L7 policies as is.
- `VirtualService` is Alpha in ambient mode. Migrating to `HTTPRoute` is required for
  stable L7 traffic management.

## Requirements

- A [supported Istio release](/docs/releases/supported-releases/)
- Kubernetes [supported version](/docs/releases/supported-releases#support-status-of-istio-releases) ({{< supported_kubernetes_versions >}})
- Gateway API CRDs installed (required for waypoint proxies)

If you do not yet have the Gateway API CRDs installed, install them now:

{{< boilerplate gateway-api-install-crds >}}

## Verify your current installation

Run the following commands to confirm the state of your existing sidecar installation:

{{< text syntax=bash snip_id=none >}}
$ istioctl version
$ kubectl get pods -n istio-system
$ kubectl get namespaces -l istio-injection=enabled
{{< /text >}}

Check for any revision-based installations (if you use `istio.io/rev` labels rather than
`istio-injection`):

{{< text syntax=bash snip_id=none >}}
$ kubectl get namespaces -l 'istio.io/rev'
{{< /text >}}

## Audit existing resources

List the Istio resources in use across your cluster:

{{< text syntax=bash snip_id=none >}}
$ kubectl get virtualservice,destinationrule,authorizationpolicy,requestauthentication,peerauthentication,envoyfilter,wasmplugin -A
{{< /text >}}

Check which `AuthorizationPolicy` resources contain L7 rules. These will require waypoint
proxies to function in ambient mode:

{{< text syntax=bash snip_id=none >}}
$ kubectl get authorizationpolicy -A --no-headers | while read ns name rest; do
    if kubectl get authorizationpolicy "$name" -n "$ns" -o yaml | grep -qE "(methods:|paths:|headers:|action: CUSTOM|action: AUDIT)"; then
      echo "$ns/$name"
    fi
  done
{{< /text >}}

Check for `PeerAuthentication` resources with `mode: DISABLE`, these are not compatible
with ambient mode:

{{< text syntax=bash snip_id=none >}}
$ kubectl get peerauthentication -A -o yaml | grep -A2 "mtls:"
{{< /text >}}

Any `PeerAuthentication` with `mode: DISABLE` must be removed or changed before migration,
as ambient mode always enforces mTLS between mesh workloads.

`PeerAuthentication` resources with `mode: STRICT` or `mode: PERMISSIVE` are not blockers,
but they become redundant after migration: ambient mode enforces mTLS via ztunnel regardless
of these policies. You can safely remove them after migration is complete.

## Back up your configuration

Before making any changes, export your current Istio configuration:

{{< text syntax=bash snip_id=none >}}
$ kubectl get virtualservice,destinationrule,authorizationpolicy,requestauthentication,peerauthentication,gateway,httproute,telemetry -A -o yaml > istio-config-backup.yaml
$ kubectl get namespaces -o yaml > namespace-backup.yaml
{{< /text >}}

Store these backups somewhere safe outside the cluster.

## Set up traffic monitoring (optional)

Use Kiali or another observability tool to capture a baseline of your current traffic patterns before making changes. See [Kiali](/docs/ops/integrations/kiali/) for setup instructions.

## Next steps

Proceed to [Install ambient components](/docs/ambient/migrate/install-ambient-components/).
