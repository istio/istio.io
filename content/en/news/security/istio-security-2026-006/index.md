---
title: ISTIO-SECURITY-2026-006
subtitle: Security Bulletin
description: Denial of service of the Istio control plane through EnvoyFilter proxy version matching.
cves: []
cvss: "7.7"
vector: "CVSS:3.1/AV:N/AC:L/PR:L/UI:N/S:C/C:N/I:N/A:H"
releases: ["1.29.0 to 1.29.6", "1.30.0 to 1.30.3"]
publishdate: 2026-08-XX
skip_seealso: true
---

{{< security_bulletin >}}

The `proxyVersion` match expression in the `EnvoyFilter` resource
(`spec.configPatches[].match.proxy.proxyVersion`) accepted a regular expression of
unbounded length. Istiod compiles this expression during admission validation and again
during configuration distribution. A user with permission to create `EnvoyFilter`
resources in a single namespace could submit very large expressions that drive excessive
memory and CPU usage in istiod, potentially crashing the control plane. Because the
validating webhook is configured to fail closed, configuration changes for all namespaces
in the mesh are rejected while istiod is unavailable, extending the impact beyond the
attacker's own namespace.

Older, unsupported Istio releases are also affected.

The `proxyVersion` match expression is now limited to 1024 characters.

## Am I Impacted?

You are impacted if you run an affected Istio release and users other than mesh
administrators are allowed to create or update `EnvoyFilter` resources, for example in
namespace-based multi-tenant environments. Meshes where only administrators can manage
`EnvoyFilter` resources are not exposed to untrusted input, but should still upgrade.

## Mitigation

- For Istio 1.30 users: upgrade to **1.30.4** or later.
- For Istio 1.29 users: upgrade to **1.29.7** or later.
- As an interim measure, restrict `EnvoyFilter` create and update permissions to trusted
  administrators using Kubernetes RBAC.

The Istio Security Committee would like to thank Artem Cherezov
(https://github.com/cherez0ff) for responsibly disclosing this issue.
