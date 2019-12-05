---
title: Service Account Secret Creation
description: Describes how Citadel determines whether to create service account secrets.
weight: 30
---

When a Citadel instance notices that a `ServiceAccount` is created in a namespace, it must decide whether
it should generate an `istio.io/key-and-cert` secret for that `ServiceAccount`.
In order to make that decision, Citadel considers three inputs (note: there can be multiple Citadel instances
deployed in a single cluster, and the following targeting rules are applied to each instance):

1. `ca.istio.io/env` namespace label: *string valued* label containing the namespace of the desired Citadel instance

1. `ca.istio.io/override` namespace label: *boolean valued* label which overrides all other configurations and forces all Citadel instances either to target or ignore a namespace

1. [`enableNamespacesByDefault` security configuration](/zh/docs/reference/config/installation-options/#security-options): default behavior if no labels are found on the `ServiceAccount`'s namespace

From these three values, the decision process mirrors that of the [`Sidecar Injection Webhook`](/zh/docs/ops/configuration/mesh/injection-concepts/). The detailed behavior is that:

- If `ca.istio.io/override` exists and is `true`, generate key/cert secrets for workloads.

- Otherwise, if `ca.istio.io/override` exists and is `false`, don't generate key/cert secrets for workloads.

- Otherwise, if a `ca.istio.io/env: "ns-foo"` label is defined in the service account's namespace, the Citadel instance in namespace `ns-foo` will be used for generating key/cert secrets for workloads in the `ServiceAccount`'s namespace.

- Otherwise, set `enableNamespacesByDefault` to `true` during installation. If it is `true`, the default Citadel instance will be used for generating key/cert secrets for workloads in the `ServiceAccount`'s namespace.

- Otherwise, no secrets are created for the `ServiceAccount`'s namespace.

This logic is captured in the truth table below:

| `ca.istio.io/override` value | `ca.istio.io/env` match | `enableNamespacesByDefault` configuration | Workload secret created |
|------------------------------|-------------------------|-------------------------------------------|-------------------------|
|`true`|yes|`true`|yes|
|`true`|yes|`false`|yes|
|`true`|no|`true`|yes|
|`true`|no|`false`|yes|
|`true`|unset|`true`|yes|
|`true`|unset|`false`|yes|
|`false`|yes|`true`|no|
|`false`|yes|`false`|no|
|`false`|no|`true`|no|
|`false`|no|`false`|no|
|`false`|unset|`true`|no|
|`false`|unset|`false`|no|
|unset|yes|`true`|yes|
|unset|yes|`false`|yes|
|unset|no|`true`|no|
|unset|no|`false`|no|
|unset|unset|`true`|yes|
|unset|unset|`false`|no|

{{< idea >}}
When a namespace transitions from _disabled_ to _enabled_, Citadel will retroactively generate secrets for all `ServiceAccounts` in that namespace. When transitioning from _enabled_ to _disabled_, however, Citadel will not delete the namespace's generated secrets until the root certificate is renewed.
{{< /idea >}}
