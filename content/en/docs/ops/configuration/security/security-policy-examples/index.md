---
title: Security policy examples
description: Shows common examples of using Istio security policy.
weight: 60
owner: istio/wg-security-maintainers
test: yes
---

## Background

This page shows common patterns of using Istio security policies. You may find them useful in your deployment or use this
as a quick reference to example policies.

The policies demonstrated here are just examples and require changes to adapt to your actual environment
before applying.

Also read the [authentication](/docs/tasks/security/authentication/authn-policy) and
[authorization](/docs/tasks/security/authorization) tasks for a hands-on tutorial of using the security policy in
more detail.

## Require different JWT issuer per host

JWT validation is common on the ingress gateway and you may want to require different JWT issuers for different
hosts. You can use the authorization policy for fine grained JWT validation in addition to the
[request authentication](/docs/tasks/security/authentication/authn-policy/#end-user-authentication) policy.

Use the following policy if you want to allow access to the given hosts if JWT principal matches. Access to other hosts
will always be denied.

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
  action: ALLOW
  rules:
  - from:
    - source:
        # the JWT token must have issuer with suffix "@example.com"
        requestPrincipals: ["*@example.com"]
    to:
    - operation:
        hosts: ["example.com", "*.example.com"]
  - from:
    - source:
        # the JWT token must have issuer with suffix "@another.org"
        requestPrincipals: ["*@another.org"]
    to:
    - operation:
        hosts: [".another.org", "*.another.org"]
{{< /text >}}

## Namespace isolation

The following two policies enable strict mTLS on namespace `foo`, and allow traffic from the same namespace.

{{< text yaml >}}
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
  namespace: foo
spec:
  mtls:
    mode: STRICT
---
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

## Namespace isolation with ingress exception

The following two policies enable strict mTLS on namespace `foo`, and allow traffic from the same namespace and also
from the ingress gateway.

{{< text yaml >}}
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
  namespace: foo
spec:
  mtls:
    mode: STRICT
---
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

## Require mTLS in authorization layer (defense in depth)

You have configured `PeerAuthentication` to `STRICT` but want to make sure the traffic is indeed protected by mTLS with
an extra check in the authorization layer, i.e., defense in depth.

The following policy denies the request if the principal is empty. The principal will be empty if plain text is used.
In other words, the policy allows requests if the principal is non-empty.
`"*"` means non-empty match and using with `notPrincipals` means matching on empty principal.

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

## Require mandatory authorization check with `DENY` policy

You can use the `DENY` policy if you want to require mandatory authorization check that must be satisfied and cannot be
bypassed by another more permissive `ALLOW` policy. This works because the `DENY` policy takes precedence over the
`ALLOW` policy and could deny a request early before `ALLOW` policies.

Use the following policy to enforce mandatory JWT validation in addition to the [request authentication](/docs/tasks/security/authentication/authn-policy/#end-user-authentication) policy.
The policy denies the request if the request principal is empty. The request principal will be empty if JWT validation failed.
In other words, the policy allows requests if the request principal is non-empty.
`"*"` means non-empty match and using with `notRequestPrincipals` means matching on empty request principal.

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
{{< /text >}}

Similarly, Use the following policy to require mandatory namespace isolation and also allow requests from ingress gateway.
The policy denies the request if the namespace is not `foo` and the principal is not `cluster.local/ns/istio-system/sa/istio-ingressgateway-service-account`.
In other words, the policy allows the request only if the namespace is `foo` or the principal is `cluster.local/ns/istio-system/sa/istio-ingressgateway-service-account`.

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
