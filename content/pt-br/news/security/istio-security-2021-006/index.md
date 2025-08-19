---
title: ISTIO-SECURITY-2021-006
subtitle: Security Bulletin
description: An external client can access unexpected services in the cluster, bypassing authorization checks, when a gateway is configured with AUTO_PASSTHROUGH routing configuration.
cves: [CVE-2021-31921]
cvss: "10"
vector: "AV:N/AC:L/PR:N/UI:N/S:C/C:H/I:H/A:H"
releases: ["All releases prior to 1.8.6", "1.9.0 to 1.9.4"]
publishdate: 2021-05-11
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## Issue

Istio contains a remotely exploitable vulnerability where an external client can access unexpected services in the cluster,
bypassing authorization checks, when a gateway is configured with `AUTO_PASSTHROUGH` routing configuration.

## Am I impacted?

This vulnerability impacts only usage of the `AUTO_PASSTHROUGH` Gateway type, which is typically only used in multi-network multi-cluster deployments.

The TLS mode of all Gateways in the cluster can be detected with the following command:

    {{< text bash >}}
    $ kubectl get gateways.networking.istio.io -A -o "custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,TLS_MODE:.spec.servers[*].tls.mode"
    {{< /text >}}

If the output shows any `AUTO_PASSTHROUGH` Gateways, you may be impacted.

## Mitigation

Update your cluster to the latest supported version:

* Istio 1.8.6, if using 1.8.x
* Istio 1.9.5 or up
* The patch version specified by your cloud provider

## Credit

We would like to thank John Howard (Google) for reporting this issue.
