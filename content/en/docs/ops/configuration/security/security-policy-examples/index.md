---
title: Security policy examples
description: Shows common examples of using Istio security policy.
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

### Require different JWT issuer per host

JWT validation is common on the ingress gateway and you may want to require different JWT issuers for different
hosts, you can use the authorization policy for fine grained JWT validation in addition to the
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
        hosts: ["example.com", "*.example.com"]
        # the JWT token must have issuer with suffix "@example.com"
        requestPrincipals: ["*@example.com"]
    - source:
        hosts: [".another.org", "*.another.org"]
        # the JWT token must have issuer with suffix "@another.org"
        requestPrincipals: ["*@another.org"]
{{< /text >}}

### Namespace isolation

You want to block all traffic from outside the namespace `foo`, in other words, isolate the namespace `foo` from other
namespaces. This requires you have already enabled mTLS.

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

### Namespace isolation with ingress exception

You want to block all traffic from outside the namespace `foo` but allow access from ingress gateway.
This requires you have already enabled mTLS.

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

### Require mTLS in authorization layer (defense in depth)

You have configured `PeerAuthentication` to `STRICT` but want to make sure the traffic is indeed protected by mTLS with
extra check in the authorization layer, i.e., defense in depth.

The following policy denies the request if the principal is empty. The principal will be empty if plain text is used.
In other words, the policy allows request if the principal is non-empty.
"*" means non-empty match and using with `notPrincipals` means matching on empty principal.

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

### Require mandatory authorization check with `DENY` policy

You can use the `DENY` policy If you want to require mandatory authorization check that must be satisfied and cannot be
bypassed by another more permissive policy, you can use the `DENY` policy. This is different from `ALLOW` policy because
a more permissive `ALLOW` policy will allow more requests and bypass the more restrictive `ALLOW` policy.

Use the following policy to enforce mandatory JWT validation in addition to the [request authentication](/docs/tasks/security/authentication/authn-policy/#end-user-authentication) policy.
The policy denies the request if the request principal is empty. The request principal will be empty if JWT validation failed.
In other words, the policy allows request if the request principal is non-empty.
"*" means non-empty match and using with `notRequestPrincipals` means matching on empty request principal.

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

Similarly, Use the following policy to enforce namespace isolation but allow request from ingress gateway. The policy
denies the request if the namespace is not `foo` and the principal is not `cluster.local/ns/istio-system/sa/istio-ingressgateway-service-account`.
In other words, the policy allows request if the namespace is `foo` or the principal is `cluster.local/ns/istio-system/sa/istio-ingressgateway-service-account`.

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
