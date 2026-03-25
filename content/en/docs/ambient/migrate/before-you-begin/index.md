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

## Requirements

- Istio 1.24 or later (1.25+ recommended for full feature support)
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
$ kubectl get virtualservice,destinationrule,authorizationpolicy,requestauthentication,peerauthentication -A
{{< /text >}}

Check which `AuthorizationPolicy` resources contain L7 rules. These will require waypoint
proxies to function in ambient mode:

{{< text syntax=bash snip_id=none >}}
$ kubectl get authorizationpolicy -A --no-headers | while read ns name rest; do
    if kubectl get authorizationpolicy "$name" -n "$ns" -o yaml | grep -qE "(methods:|paths:|headers:)"; then
      echo "$ns/$name"
    fi
  done
{{< /text >}}

Check for `PeerAuthentication` resources with `mode: DISABLE`, these are not compatible
with ambient mode:

{{< text syntax=bash snip_id=none >}}
$ kubectl get peerauthentication -A -o yaml | grep -A2 "mtls:"
{{< /text >}}

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
