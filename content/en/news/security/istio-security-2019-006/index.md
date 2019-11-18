---
title: ISTIO-SECURITY-2019-006
subtitle: Security Bulletin
description: Security vulnerability disclosure for CVE-2019-18817.
publishdate: 2019-11-07
keywords: [CVE]
aliases:
    - /news/2019/istio-security-2019-006
---

__ISTIO-SECURITY-2019-006__: Envoy, and subsequently Istio, are vulnerable to the following DoS attack:
* __[CVE-2019-18817](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-18817)__: An infinite loop can be triggered in Envoy if the option `continue_on_listener_filters_timeout` is set to `True`. This has been the case for Istio since the introduction of the Protocol Detection feature in Istio 1.3
A remote attacker may trivially trigger that vulnerability, effectively exhausting Envoy’s CPU resources and causing a denial-of-service attack.

## Affected Istio releases

The following Istio releases are vulnerable:

* 1.3, 1.3.1, 1.3.2, 1.3.3, 1.3.4

## Impact score

Overall CVSS score: 7.5 [CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H/E:H/RL:O/RC:C](https://nvd.nist.gov/vuln-metrics/cvss/v3-calculator?vector=AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H/E:H/RL:O/RC:C&version=3.1)

## Vulnerability impact and detection

Both Istio gateways and sidecars are vulnerable to this issue. If you are running one of the versions listed above, your cluster is vulnerable.

## Mitigation

* Workaround:
  The exploitation of that vulnerability can be prevented by customizing Istio installation (as described in [installation options](/docs/reference/config/installation-options/#pilot-options) ), using Helm to override the following options:

{{< text plain >}}
--set pilot.env.PILOT_INBOUND_PROTOCOL_DETECTION_TIMEOUT=0s --set global.proxy.protocolDetectionTimeout=0s
{{< /text >}}

* We are going to release a fixed version of Istio as soon as possible to address this vulnerability.

We'd like to remind our community to follow the [vulnerability reporting process](/about/security-vulnerabilities/) to report any bug that can result in a security vulnerability.
