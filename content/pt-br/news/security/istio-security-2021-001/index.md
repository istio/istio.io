---
title: ISTIO-SECURITY-2021-001
subtitle: Security Bulletin
description: JWT authentication can be bypassed when AuthorizationPolicy is misused.
cves: [CVE-2021-21378]
cvss: "8.2"
vector: "AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:L/A:N"
releases: ["1.9.0"]
publishdate: 2021-03-01
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

Envoy, and subsequently Istio, is vulnerable to a newly discovered vulnerability:

* __[CVE-2021-21378](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2021-21378)__:
  JWT authentication bypass with unknown issuer token
    * CVSS Score: 8.2 [AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:L/A:N](https://www.first.org/cvss/calculator/3.0#CVSS:3.0/AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:L/A:N)

You are subject to the vulnerability if you are using `RequestAuthentication` alone for JWT validation.

You are **not** subject to the vulnerability if you use **both** `RequestAuthentication` and `AuthorizationPolicy` for JWT validation.

{{< warning >}}
Please note that `RequestAuthentication` is used to define a list of issuers that should be accepted. It does not reject
a request without JWT token.
{{< /warning >}}

For Istio, this vulnerability only exists if your service:
* Accepts JWT tokens (with `RequestAuthentication`)
* Has some service paths without `AuthorizationPolicy` applied.

For the service paths that both conditions are met, an incoming request with a JWT token, and the token issuer is not in
`RequestAuthentication` will bypass the JWT validation, instead of getting rejected.

## Mitigation

For proper JWT validation, you should always use the `AuthorizationPolicy` as documented on istio.io for
[specifying a valid token](/docs/tasks/security/authentication/authn-policy/#require-a-valid-token).
To do this you will have to audit all of your `RequestAuthentication` and subsequent `AuthorizationPolicy` resources to
make sure they align with the documented practice.

{{< boilerplate "security-vulnerability" >}}
