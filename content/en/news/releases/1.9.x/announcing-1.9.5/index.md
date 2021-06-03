---
title: Announcing Istio 1.9.5
linktitle: 1.9.5
subtitle: Patch Release
description: Istio 1.9.5 patch release.
publishdate: 2021-05-11
release: 1.9.5
aliases:
    - /news/announcing-1.9.5
---

This release fixes the security vulnerabilities described in our May 11th posts, [ISTIO-SECURITY-2021-005](/news/security/istio-security-2021-005) and [ISTIO-SECURITY-2021-006](/news/security/istio-security-2021-006).

{{< relnote >}}

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

## Breaking Changes

As part of the fixes for [ISTIO-SECURITY-2021-006](/news/security/istio-security-2021-006/), the [previously deprecated](/news/releases/1.8.x/announcing-1.8/upgrade-notes/#multicluster-global-stub-domain-deprecation) `.global` stub domain for multicluster will no longer work.

This change can be temporarily disabled if desired by setting the environment variable `PILOT_ENABLE_LEGACY_AUTO_PASSTHROUGH=true` in Istiod. However, this is strongly discouraged, as it negates the fix to [ISTIO-SECURITY-2021-006](/news/security/istio-security-2021-006/).

Please follow the [Multicluster Installation documentation](/docs/setup/install/multicluster/) for more information.
