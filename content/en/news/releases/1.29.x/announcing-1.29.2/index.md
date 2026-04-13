---
title: Announcing Istio 1.29.2
linktitle: 1.29.2
subtitle: Patch Release
description: Istio 1.29.2 patch release.
publishdate: 2026-04-13
release: 1.29.2
aliases:
    - /news/announcing-1.29.2
---

This release contains security fixes. This release note describes what's different between Istio 1.29.1 and 1.29.2.

{{< relnote >}}

## Changes

- **Added** Helm v4 (server-side apply) support. Fixed a webhook `failurePolicy` field ownership
  conflict that caused `helm upgrade` with SSA to fail.
  ([Issue #58302](https://github.com/istio/istio/issues/58302)) ([Issue #59367](https://github.com/istio/istio/issues/59367))

- **Fixed** istiod errors on startup when a CRD version greater than the maximum supported version is installed on a cluster. `TLSRoute` versions v1.4 and below are supported; v1.5 and above will be ignored.
  ([Issue #59443](https://github.com/istio/istio/issues/59443))

- **Fixed** multi-cluster installations trying to validate the wrong trust domain when the
  control plane does not have an updated `istio-reader` `ClusterRole`, failing to read the
  trust domain from the remote `ConfigMap`. Now, istiod will fall back to using the
  trust domain specified in the local mesh config until it can read the remote one.
  ([Issue #59474](https://github.com/istio/istio/issues/59474))

- **Fixed** applying multiple `VirtualService` resources for the same hostname to waypoints.
  ([Issue #59483](https://github.com/istio/istio/issues/59483))

- **Fixed** an issue where `istioctl` incorrectly reported an error on `EnvoyFilter` with `REPLACE` operation on `VIRTUAL_HOST`.
  ([Issue #59495](https://github.com/istio/istio/issues/59495))

- **Fixed** a bug where the E/W gateway occasionally routed HBONE connections to a wrong service due to
  incorrect connection pooling in Envoy.
  ([Issue #58630](https://github.com/istio/istio/issues/58630))

- **Fixed** `serviceAccount` matcher regex in `AuthorizationPolicy` to properly quote the service account name, allowing for correct matching of service accounts with special characters in their names.
  ([Issue #59700](https://github.com/istio/istio/issues/59700))

- **Fixed** an issue where all `Gateways` were restarted after istiod was restarted.
  ([Issue #59709](https://github.com/istio/istio/issues/59709))

- **Fixed** `TLSRoute` hostnames not being constrained to the intersection with the `Gateway` listener hostname.
  Previously, a `TLSRoute` with a broad hostname (e.g. `*.com`) attached to a listener with a narrower hostname
  (e.g. `*.example.com`) would incorrectly match the full route hostname instead of only the intersection
  (`*.example.com`), as required by the Gateway API spec.
  ([Issue #59229](https://github.com/istio/istio/issues/59229))

- **Fixed** JWKS URI CIDR blocking by using a custom control function in a custom `DialContext`.
  The control function filters connections after DNS resolution but before dialing, allowing
  the block to follow redirects and the issuer discovery path. This also preserves features
  in the default `DialContext` like happy eyeballs and `dialSerial` (trying each resolved IP in order).

- **Fixed** a bug where the default `percent` for `retryBudget` in `DestinationRule` was
  incorrectly set to 0.2% instead of the intended 20%.
  ([Issue #59504](https://github.com/istio/istio/issues/59504))

- **Fixed** a bug where `retryBudget` set in a `DestinationRule`'s top-level `trafficPolicy`
  was silently dropped when the destination also had a subset with its own `trafficPolicy`.
  Additionally, the `retryBudget` defined at the subset level was also ignored.
  ([Issue #59667](https://github.com/istio/istio/issues/59667))

- **Fixed** missing size limit on `gzip` decompressed WASM binaries fetched over HTTP, consistent with
  the limits already applied to other fetch paths.

- **Fixed** a field manager conflict on `ValidatingWebhookConfiguration` during `helm upgrade` with
  server-side apply in tools that respect `.Release.IsUpgrade` (Helm 4, Flux). The `failurePolicy`
  field is now omitted from the webhook template on upgrade, preserving the value set at runtime
  by the webhook controller. For tools that use `helm template` with SSA, set
  `base.validationFailurePolicy: Fail` to avoid the conflict.

- **Fixed** missing `ReadHeaderTimeout` and `IdleTimeout` on the istiod webhook HTTPS server (port 15017),
  aligning it with the existing timeouts on the HTTP server (port 8080).

- **Fixed** a race condition that caused intermittent `"proxy::h2 ping error: broken pipe"` error logs.
  ([Issue #59192](https://github.com/istio/istio/issues/59192)) ([Issue #1346](https://github.com/istio/ztunnel/issues/1346))
