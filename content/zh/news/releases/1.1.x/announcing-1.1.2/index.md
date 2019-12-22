---
title: Announcing Istio 1.1.2 with Important Security Update
linktitle: 1.1.2
subtitle: Patch Release
description: Istio 1.1.2 patch release.
publishdate: 2019-04-05
release: 1.1.2
aliases:
    - /zh/about/notes/1.1.2
    - /zh/blog/2019/announcing-1.1.2
    - /zh/news/2019/announcing-1.1.2
    - /zh/news/announcing-1.1.2
---

We're announcing immediate availability of Istio 1.1.2 which contains some important security updates. Please see below for details.

{{< relnote >}}

## Security update

Two security vulnerabilities have recently been identified in the Envoy proxy
([CVE 2019-9900](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-9900) and [CVE 2019-9901](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-9901)). The
vulnerabilities have now been patched in Envoy version 1.9.1, and correspondingly in the Envoy builds
embedded in Istio 1.1.2 and Istio 1.0.7. Since Envoy is an integral part of Istio, users are advised to update Istio
immediately to mitigate security risks arising from these vulnerabilities.

The vulnerabilities are centered on the fact that Envoy did not normalize HTTP URI paths and did not fully validate HTTP/1.1 header values. These
vulnerabilities impact Istio features that rely on Envoy to enforce any of authorization, routing, or rate limiting.

## Affected Istio releases

The following Istio releases are vulnerable:

- 1.1, 1.1.1
    - These releases can be patched to Istio 1.1.2.
    - 1.1.2 is built from the same source as 1.1.1 with the addition of Envoy patches minimally sufficient to address the CVEs.

- 1.0, 1.0.1, 1.0.2, 1.0.3, 1.0.4, 1.0.5, 1.0.6
    - These releases can be patched to Istio 1.0.7
    - 1.0.7 is built from the same source as 1.0.6 with the addition of Envoy patches minimally sufficient to address the CVEs.

- 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8
    - These releases are no longer supported and will not be patched. Please upgrade to a supported release with the necessary fixes.

## Vulnerability impact

[CVE 2019-9900](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-9900) and [CVE 2019-9901](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-9901)
allow remote attackers access to unauthorized resources by using specially crafted request URI paths (9901) and NUL bytes in
HTTP/1.1 headers (9900), potentially circumventing DoS prevention systems such as rate limiting, or routing to a unexposed upstream system. Refer to
[issue 6434](https://github.com/envoyproxy/envoy/issues/6434)
and [issue 6435](https://github.com/envoyproxy/envoy/issues/6435) for more information.

As Istio is based on Envoy, Istio customers can be affected by these vulnerabilities based on whether paths and request headers are used within Istio
policies or routing rules and how the backend HTTP implementation resolves them. If prefix path matching rules are used by Mixer or by Istio authorization
policies or the routing rules, an attacker could exploit these vulnerabilities to gain access to unauthorized paths on certain HTTP backends.

## Mitigation

Eliminating the vulnerabilities requires updating to a corrected version of Envoy. We’ve incorporated the necessary updates in the latest Istio patch releases.

For Istio 1.1.x deployments: update to a minimum of [Istio 1.1.2](/zh/news/releases/1.1.x/announcing-1.1.2)

For Istio 1.0.x deployments: update to a minimum of [Istio 1.0.7](/zh/news/releases/1.0.x/announcing-1.0.7)

While Envoy 1.9.1 requires opting in to path normalization to address CVE 2019-9901, the version of Envoy embedded in Istio 1.1.2 and 1.0.7 enables path
normalization by default.

## Detection of NUL header exploit

Based on current information, this only affects HTTP/1.1 traffic. If this is not structurally possible in your network or configuration, then it is unlikely
that this vulnerability applies.

File-based access logging uses the `c_str()` representation for header values, as does gRPC access logging, so there will be no trivial detection via
Envoy’s access logs by scanning for NUL. Instead, operators might look for inconsistencies in logs between the routing that Envoy performs and the logic
intended in the `RouteConfiguration`.

External authorization and rate limit services can check for NULs in headers. Backend servers might have sufficient logging to detect NULs or unintended
access; it’s likely that many will simply reject NULs in this scenario via 400 Bad Request, as per RFC 7230.

## Detection of path traversal exploit

Envoy’s access logs (whether file-based or gRPC) will contain the unnormalized path, so it is possible to examine these logs to detect suspicious patterns and
requests that are incongruous with the intended operator configuration intent. In addition, unnormalized paths are available at `ext_authz`, rate limiting
and backend servers for log inspection.
