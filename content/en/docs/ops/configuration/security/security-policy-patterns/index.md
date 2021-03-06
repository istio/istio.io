---
title: Security Policy Patterns
description: Shows common patterns of using Istio security policy.
weight: 60
owner: istio/wg-security-maintainers
test: n/a
---

## Background

This page shows common patterns of using Istio security policy. You may find them useful in your deployment or use this
as a quick reference to example policies.

The policy demonstrated here are just examples and please make necessary changes to adapt to your actual environment
before applying.

Also read the [authentication tasks](/docs/tasks/security/authentication/authn-policy) and the
[authorization tasks](/docs/tasks/security/authorization) for hands-on tutorial of using the security policy with much
more details.

### Require mandatory JWT validation

The `RequestAuthentication` policy defines a list of JWT issuers that are allowed, by default it also allows
requests without JWT token.

After defining the `RequestAuthentication` policy, use the following extra policy to enforce mandatory JWT validation
that rejects the request if it has no JWT token:

{{< text yaml >}}
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: require-jwt
  namespace: istio-system
spec:
  selector:
    matchLabels:
      istio: ingressgateway
  action: DENY
  rules:
  - from:
    - source:
        notRequestPrincipals: ["*"]
EOF
{{< /text >}}

### Require different JWT issuer per host

JWT validation is commonly used on the ingress gateway and you may want to enforce different JWT issuers on different
hosts, use the following extra policy in addition to the request authentication policy:

{{< text yaml >}}
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: jwt-per-host
  namespace: istio-system
spec:
  selector:
    matchLabels:
      istio: ingressgateway
  action: DENY
  rules:
  - from:
    - source:
        hosts: ["example.com", "*.example.com"]
        # assuming the JWT token issued for example.com has the issuer example.com
        notRequestPrincipals: ["*@example.com"]
    - source:
        hosts: [".another.org", "*.another.org"]
        # assuming the JWT token issued for another.org has the issuer another.org
        notRequestPrincipals: ["*@another.org"]
{{< /text >}}

### Namespace isolation

You want to block all traffic from outside the namespace `foo`, in other words, isolate the namespace `foo` from other
namespaces. This requires to enable mTLS first.

{{< text yaml >}}
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: foo-isolation
  namespace: foo
spec:
  action: ALLOW
  rules:
  - from:
    - source:
        namespaces: ["foo"]
{{< /text >}}

If you want to make sure the policy can not be bypassed by other `ALLOW` policies, you can use the `DENY` policy to
achieve the result:

{{< text yaml >}}
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: ns-isolation
  namespace: foo
spec:
  action: DENY
  rules:
  - from:
    - source:
        notNamespaces: ["foo"]
{{< /text >}}

### Namespace isolation with ingress exception

You want to block all traffic from outside the namespace `foo` except the traffic from the ingress gateway.
This requires to enable mTLS first.

{{< text yaml >}}
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: ns-isolation-except-ingress
  namespace: foo
spec:
  action: ALLOW
  rules:
  - from:
    - source:
        namespaces: ["foo"]
    - source:
        principals: ["cluster.local/ns/istio-system/sa/istio-ingressgateway-service-account"]
{{< /text >}}

If you want to make sure the policy can not be bypassed by another `ALLOW` policy, you can use the `DENY` policy to
achieve the result:

{{< text yaml >}}
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: ns-isolation-except-ingress
  namespace: foo
spec:
  action: DENY
  rules:
  - from:
    - source:
        notNamespaces: ["foo"]
        notPrincipals: ["cluster.local/ns/istio-system/sa/istio-ingressgateway-service-account"]
{{< /text >}}

### Require mTLS in authorization layer (defense in depth)

You have configured `PeerAuthentication` to `STRICT` but want to make sure the traffic is indeed protected by mTLS with
extra check in the authorization layer, i.e., defense in depth.

The following policy enforces mTLS for workloads in the `foo` namespace:

{{< text yaml >}}
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: require-mtls
  namespace: foo
spec:
  action: DENY
  rules:
  - from:
    - source:
        notPrincipals: ["*"]
{{< /text >}}
