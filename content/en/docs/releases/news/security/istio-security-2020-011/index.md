---
title: ISTIO-SECURITY-2020-011
subtitle: Security Bulletin
description: Envoy incorrectly restores the proxy protocol downstream address for non-HTTP connections.
cves: [N/A]
cvss: "N/A"
vector: ""
releases: ["1.8.0"]
publishdate: 2020-11-21
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

Envoy, and subsequently Istio, is vulnerable to a newly discovered vulnerability:

- [Incorrect proxy protocol downstream address for non-HTTP connections](https://groups.google.com/g/envoy-security-announce/c/aqtBt5VUor0):
Envoy incorrectly restores the proxy protocol downstream address for non-HTTP connections. Instead of restoring the address supplied by the proxy protocol filter,
Envoy restores the address of the directly connected peer and passes it to subsequent filters. This will affect logging (`%DOWNSTREAM_REMOTE_ADDRESS%`) and
authorization policy (`remoteIpBlocks` and `remote_ip`) for non-HTTP network connections because they will use the incorrect proxy protocol downstream address.

This issue does not affect HTTP connections. The address from `X-Forwarded-For` is also not affected.

Istio does not support proxy protocol, and the only way to enable it is to use a custom `EnvoyFilter` resource.
It is not tested in Istio and should be used at your own risk.

## Mitigation

- For Istio 1.8.0 deployments: do not use the proxy protocol for non-HTTP connections.

{{< boilerplate "security-vulnerability" >}}
