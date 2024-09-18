---
title: ISTIO-SECURITY-2024-005
subtitle: Security Bulletin
description: CVEs reported by Envoy.
cves: [CVE-2024-XXXXX, CVE-2024-XXXXX, CVE-2024-XXXXX, CVE-2024-XXXXX, CVE-2024-XXXXX]
cvss: "7.5"
vector: "AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H"
releases: ["1.22.0 to 1.22.4", "1.23.0 to 1.23.1"]
publishdate: 2024-06-27
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## CVE

### Envoy CVEs

- __[CVE-2024-XXXXX]()__: (CVSS Score 7.5, High): oghttp2 may crash on ObBeginHeadersForStream.

- __[CVE-2024-XXXXX]()__: (CVSS Score 6.5, Moderate): Lack of validation for REQUESTED_SERVER_NAME field for access loggers enables injection of unexpected content into access logs.

- __[CVE-2024-XXXXX]()__: (CVSS Score 6.5, Moderate): Potential for `x-envoy` headers to be manipulated by external sources.

- __[CVE-2024-XXXXX]()__: (CVSS Score 5.3, Moderate): JWT filter crash in the clear route cache with remote JWKs.

- __[CVE-2024-XXXXX]()__: (CVSS Score 6.5, Moderate): Envoy crashes for LocalReply in http async client.

## Am I Impacted?

You are impacted if you are using Istio 1.22.0 to 1.22.4 or 1.23.0 to 1.23.1.

If you deploy an Istio Ingress Gateway, you are potentially vulnerable to `x-envoy` header manipulation by external sources. Envoy previosly considered all private IP to be internal
by default and as a result, did not sanitize headers from external sources with private IPs. Envoy added support for the flag `envoy.reloadable_features.explicit_internal_address_config`
to explicitly un-trust all IPs. Envoy and Istio currently disable the flag by default for backwords compatibility. In future Envoy and Istio release the flag
`envoy.reloadable_features.explicit_internal_address_config` will be enabled by default. The Envoy flag can be set mesh-wide or per-proxy via the [ProxyConfig](https://istio.io/latest/docs/reference/config/istio.mesh.v1alpha1/#ProxyConfig)
in `runtimeValues`.

Mesh-wide example configuration:

```yaml
meshConfig:
  defaultConfig:
    runtimeValues:
      "envoy.reloadable_features.explicit_internal_address_config": "true"
```

Per-proxy example configuration:

```yaml
annotations:
  proxy.istio.io/config: |
    runtimeValues:
      "envoy.reloadable_features.explicit_internal_address_config": "true"
```

Note fields in ProxyConfig are not dynamically configured; changes will require restart of workloads to take effect.