---
title: ISTIO-SECURITY-2020-006
subtitle: Security Bulletin
description: Denial of service in the HTTP2 library used by Envoy.
cves: [CVE-2020-11080]
cvss: "7.5"
vector: "AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H"
releases: ["1.4 to 1.4.9", "1.5 to 1.5.4", "1.6 to 1.6.1"]
publishdate: 2020-06-11
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

A vulnerability affecting the HTTP2 library used by Envoy has been fixed and publicly disclosed (c.f. [Denial of service: Overly large SETTINGS frames](https://github.com/nghttp2/nghttp2/security/advisories/GHSA-q5wr-xfw9-q7xr) ). Unfortunately Istio did not benefit from a responsible disclosure process.

* __[CVE-2020-11080](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-11080)__:
By sending a specially crafted packet, an attacker could cause the CPU to spike at 100%. This could be sent to the ingress gateway or a sidecar.
    * CVSS Score: 7.5 [AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H](https://nvd.nist.gov/vuln-metrics/cvss/v3-calculator?vector=AV:A/AC:L/PR:L/UI:N/S:C/C:H/I:H/A:N&version=3.1)

## Mitigation

HTTP2 support could be disabled on the Ingress Gateway as a temporary workaround using the following configuration for example (Note that HTTP2 support at ingress can be disabled if you are not exposing gRPC services through ingress):

{{< text yaml >}}

apiVersion: networking.istio.io/v1alpha3
kind: EnvoyFilter
metadata:
  name: disable-ingress-h2
  namespace: istio-system
spec:
  workloadSelector:
    labels:
      istio: ingressgateway
  configPatches:
  - applyTo: NETWORK_FILTER # http connection manager is a filter in Envoy
    match:
      context: GATEWAY
      listener:
        filterChain:
          filter:
            name: "envoy.http_connection_manager"
    patch:
      operation: MERGE
      value:
        typed_config:
          "@type": type.googleapis.com/envoy.config.filter.network.http_connection_manager.v2.HttpConnectionManager
          codec_type: HTTP1
{{< /text >}}

* For Istio 1.4.x deployments: update to [Istio 1.4.10](/news/releases/1.4.x/announcing-1.4.10) or later.
* For Istio 1.5.x deployments: update to [Istio 1.5.5](/news/releases/1.5.x/announcing-1.5.5) or later.
* For Istio 1.6.x deployments: update to [Istio 1.6.2](/news/releases/1.6.x/announcing-1.6.2) or later.

## Credit

We'd like to thank `Michael Barton` for bringing this publicly disclosed vulnerability to our attention.

{{< boilerplate "security-vulnerability" >}}
