---
title: ISTIO-SECURITY-2024-006
subtitle: Security Bulletin
description: CVEs reported by Envoy.
cves: [CVE-2024-45807, CVE-2024-45808, CVE-2024-45806, CVE-2024-45809, CVE-2024-45810]
cvss: "7.5"
vector: "AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H"
releases: ["1.22.0 to 1.22.4", "1.23.0 to 1.23.1"]
publishdate: 2024-09-19
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## CVE

### Envoy CVEs

- __[CVE-2024-45807](https://github.com/envoyproxy/envoy/security/advisories/GHSA-qc52-r4x5-9w37)__: (CVSS Score 7.5, High): oghttp2 may crash on `OnBeginHeadersForStream`.

- __[CVE-2024-45808](https://github.com/envoyproxy/envoy/security/advisories/GHSA-p222-xhp9-39rc)__: (CVSS Score 6.5, Moderate): Lack of validation for `REQUESTED_SERVER_NAME` field for access loggers enables injection of unexpected content into access logs.

- __[CVE-2024-45806](https://github.com/envoyproxy/envoy/security/advisories/GHSA-ffhv-fvxq-r6mf)__: (CVSS Score 6.5, Moderate): Potential for `x-envoy` headers to be manipulated by external sources.

- __[CVE-2024-45809](https://github.com/envoyproxy/envoy/security/advisories/GHSA-wqr5-qmq7-3qw3)__: (CVSS Score 5.3, Moderate): JWT filter crash in the clear route cache with remote JWKs.

- __[CVE-2024-45810](https://github.com/envoyproxy/envoy/security/advisories/GHSA-qm74-x36m-555q)__: (CVSS Score 6.5, Moderate): Envoy crashes for `LocalReply` in HTTP async client.

## Am I Impacted?

You are impacted if you are using Istio 1.22.0 to 1.22.4 or 1.23.0 to 1.23.1.

If you deploy an Istio Ingress Gateway, you are potentially vulnerable to `x-envoy` header manipulation by external sources. Envoy previously considered all private IP to be internal
by default and as a result, did not sanitize headers from external sources with private IPs. Envoy added support for the flag `envoy.reloadable_features.explicit_internal_address_config`
to explicitly un-trust all IPs. Envoy and Istio currently disable the flag by default for backwards compatibility. In future Envoy and Istio release the flag
`envoy.reloadable_features.explicit_internal_address_config` will be enabled by default. The Envoy flag can be set mesh-wide or per-proxy via the [ProxyConfig](/docs/reference/config/istio.mesh.v1alpha1/#ProxyConfig)
in `runtimeValues`.

Mesh-wide example configuration:

{{< text yaml >}}
meshConfig:
  defaultConfig:
    runtimeValues:
      "envoy.reloadable_features.explicit_internal_address_config": "true"
{{< /text >}}

Per-proxy example configuration:

{{< text yaml >}}
annotations:
  proxy.istio.io/config: |
    runtimeValues:
      "envoy.reloadable_features.explicit_internal_address_config": "true"
{{< /text >}}

Note fields in ProxyConfig are not dynamically configured; changes will require restart of workloads to take effect.
