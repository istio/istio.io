---
title: Announcing Istio 1.31.3
linktitle: 1.31.3
subtitle: Patch Release
description: Istio 1.31.3 patch release.
publishdate: 2026-10-21
release: 1.31.3
aliases:
    - /news/announcing-1.31.3
---

This release contains security fixes. This release note describes what's different between Istio 1.31.2 and 1.31.3.

{{< relnote >}}

## Security update

For more information, see [ISTIO-SECURITY-2026-008](/news/security/istio-security-2026-008).

- **Removed** trust in the compromised eMudhra intermediate CA certificates. The CA bundle in the `ubuntu`-based and `distroless` images no longer includes `emSign ECC Root CA - G3`.
- __[CVE-2026-111943](https://nvd.nist.gov/vuln/detail/CVE-2026-111943)__: Updated Go to 1.26.10, which rejects certificate chains that contain any of the compromised eMudhra intermediate keys in istiod, `istioctl`, and `pilot-agent`.
- **Updated** `rustls-webpki` in ztunnel to 0.103.16, which rejects certificate chains that contain any of the compromised eMudhra intermediate keys.

## Changes

- **Fixed** the ambient node-untaint controller removing the `cni.istio.io/not-ready` taint when only istio-cni was ready. It can now also wait for ztunnel to be ready on the node, so pods are not scheduled onto a node whose ztunnel is still wedged. This is off by default on this release branch and is enabled with `PILOT_NODE_UNTAINT_CHECK_ZTUNNEL=true`. Only applies when ambient is enabled. ([Issue #52073](https://github.com/istio/istio/issues/52073))
- **Fixed** istiod failing to start when the self-signed CA certificate in `istio-ca-secret` has expired, which can happen when the deployment is scaled to zero for longer than the certificate TTL. The expired certificate is now automatically renewed using the existing private key.
- **Fixed** `istioctl bug-report --duration` not filtering logs when used without `--end-time`.

- **Fixed** unhealthy endpoint propagation when `PILOT_AUTO_SEND_UNHEALTHY_ENDPOINTS` or `PILOT_SEND_UNHEALTHY_ENDPOINTS` is enabled. Unready pods selected by `ServiceEntry` resources and unhealthy health-checked `WorkloadEntry` resources selected by Kubernetes Services or `ServiceEntry` resources are now retained with their health status instead of being omitted. With `PILOT_AUTO_SEND_UNHEALTHY_ENDPOINTS` enabled (the default), these endpoints can now appear in endpoint discovery responses with unhealthy status.
