---
title: Announcing Istio 1.8.6
linktitle: 1.8.6
subtitle: Patch Release
description: Istio 1.8.6 patch release.
publishdate: 2021-05-11
release: 1.8.6
aliases:
    - /news/announcing-1.8.6
---

This release fixes the security vulnerabilities described in our May 11th posts, [ISTIO-SECURITY-2021-005](/news/security/istio-security-2021-005) and [ISTIO-SECURITY-2021-006](/news/security/istio-security-2021-006).

{{< relnote >}}

{{< tip >}}
This is the final release of 1.8. Please upgrade your Istio installation to a supported version.
{{< /tip >}}

## Security update

{{< tip >}}
The first 2 CVEs are highly related.
{{< /tip >}}

- __[CVE-2021-31920](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2021-31920)__:
Istio contains a remotely exploitable vulnerability where an HTTP request path with multiple slashes or escaped slash characters (`%2F` or `%5C`) could potentially bypass an Istio authorization policy when path based authorization rules are used. See the [ISTIO-SECURITY-2021-005 bulletin](/news/security/istio-security-2021-005) for more details.
    - __CVSS Score__: 8.1 [AV:N/AC:L/PR:L/UI:N/S:U/C:H/I:H/A:N](https://nvd.nist.gov/vuln-metrics/cvss/v3-calculator?vector=AV:N/AC:L/PR:L/UI:N/S:U/C:H/I:H/A:N)
- __[CVE-2021-29492](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2021-29492)__:
  Envoy contains a remotely exploitable vulnerability where an HTTP request with escaped slash characters can bypass Envoy's authorization mechanisms.
    - __CVSS Score__: 8.3 [AV:N/AC:L/PR:N/UI:N/S:C/C:L/I:L/A:L](https://nvd.nist.gov/vuln-metrics/cvss/v3-calculator?vector=AV:N/AC:L/PR:N/UI:N/S:C/C:L/I:L/A:L)
- __[CVE-2021-31921](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2021-31921)__:
  Istio contains a remotely exploitable vulnerability where an external client can access unexpected services in the cluster, bypassing authorization checks, when a gateway is configured with `AUTO_PASSTHROUGH` routing configuration. See the [ISTIO-SECURITY-2021-006 bulletin](/news/security/istio-security-2021-006) for more details.
    - __CVSS Score__: 10.0 [AV:N/AC:L/PR:N/UI:N/S:C/C:H/I:H/A:H](https://nvd.nist.gov/vuln-metrics/cvss/v3-calculator?vector=AV:N/AC:L/PR:N/UI:N/S:C/C:H/I:H/A:H)

## Changes

- **Added** [security best practice for authorization policies](/docs/ops/best-practices/security/#authorization-policies)

- **Fixed** istiod so it will no longer generate listeners for privileged gateway ports (<1024) if the gateway Pod does not have sufficient permissions. [Issue 27566](https://github.com/istio/istio/issues/27566)

- **Fixed** an issue where transport socket parameters are now taken into account when configured in `EnvoyFilter`. [Issue 28996](https://github.com/istio/istio/issues/28996)

- **Fixed** `PeerAuthentication` to not turn off mTLS while using multi-network, non-mTLS endpoints from the cross-network load-balancing endpoints to prevent 500 errors. [Issue 28798](https://github.com/istio/istio/issues/28798)

- **Fixed** a bug causing runaway logs in istiod after disabling the default ingress controller. [Issue 31336](https://github.com/istio/istio/issues/31336)

- **Fixed** the Kubernetes API server so it is now considered to be cluster-local by default . This means that any pod attempting to reach `kubernetes.default.svc` will always be directed to the in-cluster server. [Issue 31340](https://github.com/istio/istio/issues/31340)

- **Fixed** Istio operator to prune resources that do not belong to the specific Istio operator CR. [Issue 30833](https://github.com/istio/istio/issues/30833)

## Breaking Changes

As part of the fixes for [ISTIO-SECURITY-2021-006](/news/security/istio-security-2021-006/), the [previously deprecated](/news/releases/1.8.x/announcing-1.8/upgrade-notes/#multicluster-global-stub-domain-deprecation) `.global` stub domain for multicluster will no longer work.

This change can be temporarily disabled if desired by setting the environment variable `PILOT_ENABLE_LEGACY_AUTO_PASSTHROUGH=true` in Istiod. However, this is strongly discouraged, as it negates the fix to [ISTIO-SECURITY-2021-006](/news/security/istio-security-2021-006/).

Please follow the [Multicluster Installation documentation](/docs/setup/install/multicluster/) for more information.
