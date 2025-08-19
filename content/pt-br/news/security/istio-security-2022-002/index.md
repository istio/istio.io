---
title: ISTIO-SECURITY-2022-002
subtitle: Security Bulletin
description: Privileged Escalation in Kubernetes Gateway API.
cves: [CVE-2022-21701]
cvss: "4.7"
vector: "AV:N/AC:L/PR:H/UI:N/S:U/C:L/I:L/A:L"
releases: ["1.12.0 to 1.12.1"]
publishdate: 2022-01-18
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## CVE

### CVE-2022-21701

Istio version 1.12.0 and 1.12.1 are vulnerable to a privilege escalation attack. Users who have `CREATE` permission for `gateways.gateway.networking.k8s.io` objects can escalate this privilege to create other resources that they may not have access to, such as `Pod`.

## Am I Impacted?

This vulnerability impacts only an Alpha level feature, the [Kubernetes Gateway API](/docs/tasks/traffic-management/ingress/gateway-api/). This is not the same as the Istio `Gateway` type (`gateways.networking.istio.io`), which is not vulnerable.

Your cluster may be impacted if:
* You have the Kubernetes Gateway CRD installed. This can be detected with `kubectl get crd gateways.gateway.networking.k8s.io`.
* You have not set the `PILOT_ENABLE_GATEWAY_API_DEPLOYMENT_CONTROLLER=false` environment variable in Istiod (this is defaulted to `true`).
* Untrusted users have `CREATE` permissions for `gateways.gateway.networking.k8s.io` objects.

## Workarounds

If you are unable to upgrade, any of the following will prevent this vulnerability:

* Remove the `gateways.gateway.networking.k8s.io` `CustomResourceDefinition`.
* Set `PILOT_ENABLE_GATEWAY_API_DEPLOYMENT_CONTROLLER=false` environment variable in Istiod.
* Remove `CREATE` permissions for `gateways.gateway.networking.k8s.io` objects from untrusted users.

## Credit

We would like to thank Anthony Weems.
