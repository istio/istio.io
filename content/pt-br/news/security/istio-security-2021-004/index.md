---
title: ISTIO-SECURITY-2021-004
subtitle: Security Bulletin
description: Potential misuse of mTLS-only fields in AuthorizationPolicy with plain text traffic. 
cves: [N/A]
cvss: "N/A"
vector: ""
releases: ["All releases 1.5 and later"]
publishdate: 2021-04-15
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

This is a security advisory for customers to check the authorization policy to make sure [mTLS (STRICT mode) is enabled](/docs/tasks/security/authentication/authn-policy/#globally-enabling-istio-mutual-tls-in-strict-mode)
when using [mTLS-only fields](/docs/concepts/security/#dependency-on-mutual-tls) in the authorization policy.

You can stop reading if:

- Your authorization policy does not use [mTLS-only fields](/docs/concepts/security/#dependency-on-mutual-tls); or

- Your authorization policy uses mTLS-only fields and you have also enabled mTLS with STRICT mode or your authorization
policy is configured to reject plain text traffic explicitly.

## Issue

In authorization policy, the following are [mTLS-only fields](/docs/concepts/security/#dependency-on-mutual-tls):

- the `principals` and `notPrincipals` field under the `source` section
- the `namespaces` and `notNamespaces` field under the `source` section
- the `source.principal` custom condition
- the `source.namespace` custom condition

These mTLS-only fields will never match when the traffic is plain text (non mTLS) and the request might be allowed unexpectedly.

The following is an example ALLOW policy that uses mTLS-only fields to allow requests if it is not from the namespace `foo`:

{{< text yaml >}}
apiVersion: "security.istio.io/v1beta1"
kind: "AuthorizationPolicy"
metadata:
  name: allow-ns-not-foo
spec:
  action: ALLOW
  rules:
  - from:
    - source:
        notNamespaces: ["foo"]
{{< /text >}}

A **plain text request** from the namespace `foo` will actually be allowed. The mTLS-only field `notNamespaces` will be
compared to an empty value when mTLS is not used, resulting in a policy that allows the **plain text request** even if
the source namespace is `foo`.

The following is an example DENY policy that uses mTLS-only fields to reject a request if it is from the namespace `foo`:

{{< text yaml >}}
apiVersion: "security.istio.io/v1beta1"
kind: "AuthorizationPolicy"
metadata:
  name: reject-ns-foo
spec:
  action: DENY
  rules:
  - from:
    - source:
        namespaces: ["foo"]
{{< /text >}}

A **plain text request** from the namespace `foo` will not be rejected. The mTLS-only field `namespaces` will be
compared to an empty value when mTLS is not used, resulting in a policy that does not reject the **plain text request**
even if the source namespace is `foo`.

## Solution

To solve this problem, it's recommended to always [enable mTLS with STRICT mode](/docs/tasks/security/authentication/authn-policy/#enable-mutual-tls-per-namespace-or-workload)
on the workloads before using any mTLS-only fields in the authorization policy on the same workload.

If you are unable to enable mTLS with STRICT mode for the workload, the alternative solution is to update the authorization
policy to explicitly allow traffic with non-empty namespaces or reject traffic with empty namespaces (`*` implies non-empty and `not *` implies empty).
As namespace can only be extracted when mTLS is STRICT. The policies below effectively also reject any plain text traffic.

If you are unable to enable mTLS with STRICT mode for the workload, the alternative solution is to update the authorization
policy to explicitly allow traffic with non-empty namespaces or reject traffic with empty namespaces, as namespace can
only be extracted when mTLS is STRICT.

`*` implies non-empty namespaces and `not *` implies empty namespaces. The policies below also reject any plain text traffic.

{{< text yaml >}}
apiVersion: "security.istio.io/v1beta1"
kind: "AuthorizationPolicy"
metadata:
  name: allow-ns-not-foo
spec:
  action: ALLOW
  rules:
  - from:
    - source:
        notNamespaces: ["foo"]
        # Add the following to explicitly only allow mTLS traffic.
        namespaces: ["*"]
{{< /text >}}

{{< text yaml >}}
apiVersion: "security.istio.io/v1beta1"
kind: "AuthorizationPolicy"
metadata:
  name: reject-ns-foo
spec:
  action: DENY
  rules:
  - from:
    - source:
        namespaces: ["foo"]
  # Add the following rule to explicitly reject plain text traffic.
  - from:
    - source:
        notNamespaces: ["*"]
{{< /text >}}

Also check the [security policy examples](/docs/ops/configuration/security/security-policy-examples/#require-mtls-in-authorization-layer-defense-in-depth)
for more details about the above alternative solution.

## Credit

We'd like to thank [John Howard](https://github.com/howardjohn/) for reporting this issue.

{{< boilerplate "security-vulnerability" >}}
