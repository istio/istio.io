---
title: ISTIO-SECURITY-2020-004
subtitle: Security Bulletin
description: Default Kiali security configuration allows full control of mesh.
cves: [CVE-2020-1764]
cvss: "8.7"
vector: "AV:A/AC:L/PR:L/UI:N/S:C/C:H/I:H/A:N"
releases: ["1.4 to 1.4.6", "1.5"]
publishdate: 2020-03-25
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

Istio 1.4 to 1.4.6 and Istio 1.5 contain the following vulnerability:

* __[`CVE-2020-1764`](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-1764)__:
  Istio uses a default `signing_key` for Kiali. This can allow an attacker to view and modify the Istio configuration.
    * CVSS Score: 8.7 [AV:A/AC:L/PR:L/UI:N/S:C/C:H/I:H/A:N](https://nvd.nist.gov/vuln-metrics/cvss/v3-calculator?vector=AV:A/AC:L/PR:L/UI:N/S:C/C:H/I:H/A:N&version=3.1)

In addition, another CVE is fixed in this release, described by this
[Kiali security bulletin](https://kiali.io/news/security-bulletins/kiali-security-001/).

## Detection

Your installation is vulnerable in the following configuration:

* The Kiali version is 1.15 or earlier.
* The Kiali login token and signing key is unset.

To check your Kiali version, run this command:

{{< text bash >}}
$ kubectl get pods -n istio-system -l app=kiali -o yaml | grep image:
{{< /text >}}

To determine if your login token is unset, run this command and check for blank output:

{{< text bash >}}
$ kubectl get deploy kiali -n istio-system -o yaml | grep LOGIN_TOKEN_SIGNING_KEY
{{< /text >}}

To determine if your signing key is unset, run this command and check for blank output:

{{< text bash >}}
$ kubectl get cm kiali -n istio-system -o yaml | grep signing_key
{{< /text >}}

## Mitigation

* For Istio 1.4.x deployments: update to [Istio 1.4.7](/news/releases/1.4.x/announcing-1.4.7) or later.
* For Istio 1.5.x deployments: update to [Istio 1.5.1](/news/releases/1.5.x/announcing-1.5.1) or later.
* Workaround: You can manually update the signing key to a random token using the following command:

    {{< text bash >}}
    $ kubectl get cm kiali -n istio-system -o yaml | sed "s/server:/login_token:\\\n \
    signing_key: $(tr -dc 'a-zA-Z0-9' < /dev/urandom | fold -w 20 | head -n 1)\\\nserver:/" \
    | kubectl apply -f - ; kubectl delete pod -l app=kiali -n istio-system
    {{< /text >}}
