---
title: ISTIO-SECURITY-2021-001
subtitle: Security Bulletin
description: JWT authentication can be bypassed when AuthorizationPolicy is misused
cves: [N/A]
cvss: "N/A"
vector: ""
releases: ["1.9.0"]
publishdate: 2021-03-1
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

This issue only affects Istio 1.9.0. Previous versions of Istio are not affected. This is rated an 8.2 CVE by Istio.

Envoy, and subsequently Istio, is vulnerable to a newly discovered vulnerability:

- [Envoy JWT filter bypass when using the allow_missing configuration under requires_any](https://groups.google.com/g/envoy-security-announce/c/aqtBt5VUor0).

For Istio, this vulnerability only exists if your service:
* Accepts JWT tokens (with `RequestAuthentication`)
* Some service paths don’t have `AuthorizationPolicy` applied.

If both conditions are met, then an incoming request with a JWT token, and the token issuer is not in
`RequestAuthentication` will bypass the JWT validation, instead of getting rejected.

## Mitigation

Follow the documentation for [specifying a valid token](https://istio.io/latest/docs/tasks/security/authentication/authn-policy/#require-a-valid-token)
for all JWT tokens specified. To do this you will have to audit all of your `RequestAuthentication` and subsequent
`AuthorizationPolicy` resources to make sure they align with the documented practice.

{{< boilerplate "security-vulnerability" >}}
