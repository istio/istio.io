---
title: ISTIO-SECURITY-2021-002
subtitle: Security Bulletin
description: Upgrades from older Istio versions can affect access control to an ingress gateway due to a change of container ports.
cves: [N/A]
cvss: "N/A"
vector: ""
releases: ["All releases 1.6 and later"]
publishdate: 2021-04-07
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

Upgrading from Istio versions 1.5 and prior, to 1.6 and later, may result in access control bypass:

- **Incorrect gateway ports on authorization policies on upgrades**: In Istio
versions 1.6 and later, the default container ports for Istio ingress
gateways are updated from port "80" to "8080" and "443" to "8443" to allow
[gateways to run as non-root](/news/releases/1.7.x/announcing-1.7/upgrade-notes/#gateways-run-as-non-root)
by default. With this change, any existing authorization policies targeting
an Istio ingress gateway on ports `80` and `443` need to be migrated to use the
new container ports `8080` and `8443`, before upgrading to the listed versions.
Failure to migrate may result in traffic reaching ingress gateway service
ports `80` and `443` to be incorrectly allowed or blocked, thereby causing policy
violations.

Example of an authorization policy resource that needs to be updated:

    {{< text yaml >}}
    apiVersion: "security.istio.io/v1beta1"
    kind: "AuthorizationPolicy"
    metadata:
      name: block-admin-access
      namespace: istio-system
    spec:
      selector:
        matchLabels:
          istio: ingressgateway
      action: DENY
      rules:
      -  to:
        - operation:
            paths: ["/admin"]
            ports: [ "80" ]
      -  to:
        - operation:
            paths: ["/admin"]
            ports: [ "443" ]

    {{< /text >}}

The above policy in Istio versions 1.5 and prior will block all access to path
`/admin` for traffic reaching an Istio ingress gateway on container ports `80`
and `443`. On upgrading to Istio version 1.6 and later, this policy should
be updated to the following to have the same effect:

    {{< text yaml >}}
    apiVersion: "security.istio.io/v1beta1"
    kind: "AuthorizationPolicy"
    metadata:
      name: block-admin-access
      namespace: istio-system
    spec:
      selector:
        matchLabels:
          istio: ingressgateway
      action: DENY
      rules:
      -  to:
        - operation:
            paths: ["/admin"]
            ports: [ "8080" ]
      -  to:
        - operation:
            paths: ["/admin"]
            ports: [ "8443"
    {{< /text >}}

## Mitigation

- Update your authorization policies before upgrading to the
affected Istio versions. You can use this [script](./check.sh)
to check if any of the existing authorization policies
attached to the default Istio ingress gateway in the `istio-system` namespace need
to be updated. If you’re using a custom gateway installation, you can customize
the script to run with parameters applicable to your environment.

It is recommended to create a copy of your existing authorization
policies, update the copied version to use new gateway workload ports, and
apply both existing and updated policies in your cluster, before initiating
the upgrade process. You should only delete the old policies after a
successful upgrade, to ensure no policy violations occur on upgrade
failures or rollbacks.

## Credit

We'd like to thank [Neeraj Poddar](https://twitter.com/nrjpoddar)
for reporting this issue.

{{< boilerplate "security-vulnerability" >}}
