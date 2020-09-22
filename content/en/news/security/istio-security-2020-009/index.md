---
title: ISTIO-SECURITY-2020-009
subtitle: Security Bulletin
description: Incorrect Envoy configuration for wildcard suffixes used for Principals/Namespaces in Authorization Policies for TCP Services.
cves: [CVE-2020-16844]
cvss: "6.8"
vector: "AV:N/AC:H/PR:L/UI:N/S:U/C:H/I:H/A:N"
releases: ["1.5 to 1.5.8", "1.6 to 1.6.7"]
publishdate: 2020-08-11
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

Istio is vulnerable to a newly discovered vulnerability:

* __[`CVE-2020-16844`](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-16844)__:
Callers to TCP services that have a defined Authorization Policies with `DENY` actions using wildcard suffixes (e.g. `*-some-suffix`) for source principals or namespace fields will never be denied access.
    * CVSS Score: 6.8 [AV:N/AC:H/PR:L/UI:N/S:U/C:H/I:H/A:N](https://nvd.nist.gov/vuln-metrics/cvss/v3-calculator?vector=AV:N/AC:H/PR:L/UI:N/S:U/C:H/I:H/A:N&version=3.1)

Istio users are exposed to this vulnerability in the following ways:

If the user has an Authorization similar to

{{< text yaml >}}
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
 name: foo
 namespace: foo
spec:
 action: DENY
 rules:
 - from:
   - source:
       principals:
       - */ns/ns1/sa/foo # indicating any trust domain, ns1 namespace, foo svc account
{{< /text >}}

Istio translates the principal (and `source.principal`) field to an Envoy level string match

{{< text yaml >}}
stringMatch:
  suffix: spiffe:///ns/ns1/sa/foo
{{< /text >}}

which will not match any legitimate caller as it included the `spiffe://` string incorrectly. The correct string match should be

{{< text yaml >}}
stringMatch:
  regex: spiffe://.*/ns/ns1/sa/foo
{{< /text >}}

Prefix and exact matches in `AuthorizationPolicy` is unaffected, as are ALLOW actions in them; HTTP is also unaffected.

## Mitigation

* For Istio 1.5.x deployments: update to [Istio 1.5.9](/news/releases/1.5.x/announcing-1.5.8) or later.
* For Istio 1.6.x deployments: update to [Istio 1.6.8](/news/releases/1.6.x/announcing-1.6.8) or later.
* Do not use suffix matching in DENY policies in the source principal or namespace field for TCP services and use Prefix and Exact matching where applicable. Where possible change TCP to HTTP for port name suffixes in your Services.

{{< boilerplate "security-vulnerability" >}}
