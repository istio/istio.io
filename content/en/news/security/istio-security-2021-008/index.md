---
title: ISTIO-SECURITY-2021-008
subtitle: Security Bulletin
description: Multiple CVEs related to AuthorizationPolicy, EnvoyFilter and Envoy.
cves: [CVE-2021-32777, CVE-2021-32781, CVE-2021-32778, CVE-2021-32780, CVE-2021-39155, CVE-2021-39156]
cvss: "8.6"
vector: "AV:L/AC:L/PR:N/UI:R/S:C/C:H/I:H/A:H"
releases: ["All releases prior to 1.9.8", "1.10.0 to 1.10.3", "1.11.0"]
publishdate: 2021-08-24
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## CVEs

Envoy, and subsequently Istio, is vulnerable to six newly discovered vulnerabilities
(note that Envoy's CVE-2021-32779 is merged with Istio's CVE-2021-39156):

### CVE-2021-39156 (CVE-2021-32779)

Istio contains a remotely exploitable vulnerability, [CVE-2021-39156](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2021-39156),
where an HTTP request with a fragment (a section in the end of a URI that begins with a `#` character) in the URI path could bypass Istio's URI path-based authorization policies.
For instance, an Istio authorization policy [denies](/docs/reference/config/security/authorization-policy/#AuthorizationPolicy-Action) requests sent to the URI path `/user/profile`.
In the vulnerable versions, a request with URI path `/user/profile#section1` bypasses the deny policy and routes to the backend (with the normalized URI path `/user/profile%23section1`), possibly leading to a security incident.

The fix depends on a fix in Envoy, which is associated with [CVE-2021-32779](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2021-32779).

* CVSS Score: 8.1 [AV:N/AC:L/PR:N/UI:R/S:U/C:H/I:H/A:N](https://nvd.nist.gov/vuln-metrics/cvss/v3-calculator?vector=AV:N/AC:L/PR:N/UI:R/S:U/C:H/I:H/A:N&version=3.1)

You are impacted by this vulnerability if:

* You use Istio patch versions earlier than 1.9.8, 1.10.4 or 1.11.1.
* You use authorization policies with
  [DENY actions](/docs/reference/config/security/authorization-policy/#AuthorizationPolicy-Action) and
  [`operation.paths`](/docs/reference/config/security/authorization-policy/#Operation), or
  [ALLOW actions](/docs/reference/config/security/authorization-policy/#AuthorizationPolicy-Action) and
  [`operation.notPaths`](/docs/reference/config/security/authorization-policy/#Operation).

With the [mitigation](#mitigation),
the fragment part of the request’s URI is removed before the authorization and routing.
This prevents a request with a fragment in its URI from bypassing authorization policies which are based on the URI without the fragment part.

To opt-out from the new behavior in the [mitigation](#mitigation),
the fragment section in the URI will be kept. You can configure your installation as follows.

{{< warning >}}
Disabling the new behavior will normalize your paths as described above and is considered unsafe. Ensure that you have accommodated for this in any security policies before using this option.
{{< /warning >}}

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  name: opt-out-fragment-cve-fix
  namespace: istio-system
spec:
  meshConfig:
    defaultConfig:
      proxyMetadata:
        HTTP_STRIP_FRAGMENT_FROM_PATH_UNSAFE_IF_DISABLED: "false"
{{< /text >}}

### CVE-2021-39155

Istio contains a remotely exploitable vulnerability where an HTTP request could potentially bypass an Istio authorization policy when using rules based on `hosts` or `notHosts`.
In the vulnerable versions, the Istio authorization policy compares the HTTP `Host` or `:authority` headers in a case-sensitive manner,
which is inconsistent with [RFC 4343](https://datatracker.ietf.org/doc/html/rfc4343). For example, the user could have an authorization policy that rejects requests with host `secret.com`,
but the attacker can bypass this by sending the request with hostname `Secret.com`.
The routing flow routes the traffic to the backend for `secret.com` which is a policy violation.

See [CVE-2021-39155](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2021-39155) for more information.

* CVSS Score: 8.3 [AV:N/AC:L/PR:N/UI:R/S:U/C:H/I:H/A:L](https://nvd.nist.gov/vuln-metrics/cvss/v3-calculator?vector=AV:N/AC:L/PR:N/UI:R/S:U/C:H/I:H/A:L&version=3.1)

You are impacted by this vulnerability if:

* You use Istio patch versions earlier than 1.9.8, 1.10.4 or 1.11.1.
* You use Istio authorization policies with
  [DENY actions](/docs/reference/config/security/authorization-policy/#AuthorizationPolicy-Action) and
  [`operation.hosts`](/docs/reference/config/security/authorization-policy/#Operation), or
  [ALLOW actions](/docs/reference/config/security/authorization-policy/#AuthorizationPolicy-Action) and
  [`operation.notHosts`](/docs/reference/config/security/authorization-policy/#Operation).

With the [mitigation](#mitigation),
when authorization policies based on `hosts` or `notHosts` are used, the Istio authorization policy compares the HTTP `Host` or `:authority` headers
in a case-insensitive manner to the `hosts` or `notHosts` specs.

### CVE-2021-32777

Envoy contains a remotely exploitable vulnerability that an HTTP request with multiple value headers could do an incomplete authorization policy check when the `ext_authz` extension is used.
When a request header contains multiple values, the external authorization server will only see the last value of the given header. See [CVE-2021-32777](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2021-32777) for more information.

* CVSS Score: 8.6

You are impacted by this vulnerability if:

* You use Istio patch versions earlier than 1.9.8, 1.10.4 or 1.11.1.
* You use [`EnvoyFilters`](/docs/reference/config/networking/envoy-filter/).

### CVE-2021-32778

Envoy contains a remotely exploitable vulnerability where an Envoy client opening and then resetting a large number of HTTP/2 requests could lead to excessive CPU consumption.
See [CVE-2021-32778](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2021-32778) for for information.

* CVSS Score: 8.6

You are impacted by this vulnerability if you use Istio patch versions earlier than 1.9.8, 1.10.4 or 1.11.1.

### CVE-2021-32780

Envoy contains a remotely exploitable vulnerability where an untrusted upstream service could
cause Envoy to terminate abnormally by sending the GOAWAY frame followed by the SETTINGS frame
with the `SETTINGS_MAX_CONCURRENT_STREAMS` parameter set to 0. See [CVE-2021-32780](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2021-32780) for more information.

* CVSS Score: 8.6

You are impacted by this vulnerability if you use Istio patch versions 1.10.0 to 1.10.3 or 1.11.0.

### CVE-2021-32781

Envoy contains a remotely exploitable vulnerability that affects Envoy's `decompressor`, `json-transcoder` or `grpc-web` extensions or
proprietary extensions that modify and increase the size of request or response bodies.
Modifying and increasing the size of the body in an Envoy extension beyond the internal buffer size could lead to
Envoy accessing deallocated memory and terminating abnormally. See [CVE-2021-32781](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2021-32781) for more information.

* CVSS Score: 8.6

You are impacted by this vulnerability if:

* You use Istio patch versions earlier than 1.9.8, 1.10.4 or 1.11.1.
* You use [`EnvoyFilters`](/docs/reference/config/networking/envoy-filter/).

### Mitigation

To mitigate the above CVEs, update your cluster to the latest supported version:

* Istio 1.9.8 or up, if using 1.9.x
* Istio 1.10.4 or up, if using 1.10.x
* Istio 1.11.1 or up, if using 1.11.x
* The patch version specified by your cloud provider

## Non-CVE vulnerabilities

### Istio does not ignore ports in `AuthorizationPolicy` `host` and `notHosts` comparisons

When creating a `VirtualService` or `Gateway`, Istio generates configuration matching both the hostname itself and the hostname with all matching ports. For instance, a `VirtualService` or `Gateway` for a host of `httpbin.foo` generates a config matching `httpbin.foo` and `httpbin.foo:*`. However, an `AuthorizationPolicy` using exact match only matches the exact string given for the `hosts` or `notHosts` fields.

Your cluster is impacted if you have an `AuthorizationPolicy` using exact string comparison for the [`hosts` or `notHosts`](/docs/reference/config/security/authorization-policy/#Operation).

#### `AuthorizationPolicy` Mitigation

Update your authorization policy [rules](/docs/reference/config/security/authorization-policy/#Rule) to use prefix match instead of exact match.  For example, to match a `VirtualService` or `Gateway` with a host of `httpbin.com` , create an `AuthorizationPolicy` with `hosts: ["httpbin.com", "httpbin.com:*"]` as shown below.

{{< text yaml >}}
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: httpbin
  namespace: foo
spec:
  action: DENY
  rules:
  - from:
    - source:
        namespaces: ["dev"]
    to:
    - operation:
        hosts: ["httpbin.com", "httpbin.com:*"]
{{< /text >}}

## Credit

We would like to thank Yangmin Zhu (Google) for reporting some of the above issues.
