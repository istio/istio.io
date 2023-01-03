---
title: Copy Jwt Claim to HTTP Header
description: Shows how users can copy their jwt claims to http headers.
weight: 30
keywords: [security,authentication,jwt,claim]
aliases:
    - /docs/tasks/security/istio-auth.html
    - /docs/tasks/security/authn-policy/
owner: istio/wg-security-maintainers
test: yes
status: Experimental
---
This task shows you how to copy valid JWT claims to http headers after JWT authentication is successfully completed via Istio request authentication policy.

Note: Claims of type string, boolean, integer are supported. Array type claims are not supported as of now.

## Before you begin

Before you begin this task, do the following:

* Complete the [Istio end user authentication task](/docs/tasks/security/authentication/authn-policy/#end-user-authentication).

* Install Istio using [Istio installation guide](/docs/setup/install/istioctl/).

* Deploy two workloads: `httpbin` and `sleep`. Deploy these in one namespace,
for example `foo`. Both workloads run with an Envoy proxy in front of each.
Deploy the example namespace and workloads using these commands:

    {{< text bash >}}
    $ kubectl create ns foo
    $ kubectl apply -f <(istioctl kube-inject -f @samples/httpbin/httpbin.yaml@) -n foo
    $ kubectl apply -f <(istioctl kube-inject -f @samples/sleep/sleep.yaml@) -n foo
    {{< /text >}}

* Verify that `sleep` successfully communicates with `httpbin` using this command:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- curl http://httpbin.foo:8000/ip -sS -o /dev/null -w "%{http_code}\n"
    200
    {{< /text >}}

{{< warning >}}
If you don’t see the expected output, retry after a few seconds.
Caching and propagation can cause a delay.
{{< /warning >}}

## Allow requests with valid JWT and list-typed claims

1. The following command creates the `jwt-example` request authentication policy
for the `httpbin` workload in the `foo` namespace. This policy for `httpbin` workload
accepts a JWT issued by `testing@secure.istio.io` and copy the value of claim `foo` to a http header `X-Jwt-Claim-Foo`:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: security.istio.io/v1beta1
    kind: RequestAuthentication
    metadata:
      name: "jwt-example"
      namespace: foo
    spec:
      selector:
        matchLabels:
          app: httpbin
      jwtRules:
      - issuer: "testing@secure.istio.io"
        jwksUri: "{{< github_file >}}/security/tools/jwt/samples/jwks.json"
        outputClaimToHeaders:
        - header: "x-jwt-claim-foo"
          claim: "foo"
    EOF
    {{< /text >}}

1. Verify that a request with an invalid JWT is denied:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- curl "http://httpbin.foo:8000/headers" -sS -o /dev/null -H "Authorization: Bearer invalidToken" -w "%{http_code}\n"
    401
    {{< /text >}}

1. Get the JWT that sets the `iss` and `sub` keys to the same value, `testing@secure.istio.io`.
This causes Istio to generate the attribute `requestPrincipal` with the value `testing@secure.istio.io/testing@secure.istio.io`:

    {{< text syntax="bash" expandlinks="false" >}}
    $ TOKEN=$(curl {{< github_file >}}/security/tools/jwt/samples/demo.jwt -s) && echo "$TOKEN" | cut -d '.' -f2 - | base64 --decode -
    {"exp":4685989700,"foo":"bar","iat":1532389700,"iss":"testing@secure.istio.io","sub":"testing@secure.istio.io"}
    {{< /text >}}

1. Verify that a request with a valid JWT is allowed:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- curl "http://httpbin.foo:8000/headers" -sS -o /dev/null -H "Authorization: Bearer $TOKEN" -w "%{http_code}\n"
    200
    {{< /text >}}

1. Verify that a request contains a valid http header with JWT claim value:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- curl "http://httpbin.foo:8000/headers" -sS -H "Authorization: Bearer $TOKEN" | grep "X-Jwt-Claim-Foo" | sed -e 's/^[ \t]*//'
    "X-Jwt-Claim-Foo": "bar"
    {{< /text >}}

## Clean up

1. Remove the namespace `foo`:

    {{< text bash >}}
    $ kubectl delete namespace foo
    {{< /text >}}