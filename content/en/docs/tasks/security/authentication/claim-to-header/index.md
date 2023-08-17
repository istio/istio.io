---
title: Copy JWT Claims to HTTP Headers
description: Shows how users can copy their JWT claims to HTTP headers.
weight: 30
keywords: [security,authentication,JWT,claim]
aliases:
    - /docs/tasks/security/istio-auth.html
    - /docs/tasks/security/authn-policy/
owner: istio/wg-security-maintainers
test: yes
status: Experimental
---

{{< boilerplate experimental >}}

This task shows you how to copy valid JWT claims to HTTP headers after JWT authentication is successfully completed via an Istio request authentication policy.

{{< warning >}}
Only claims of type string, boolean, and integer are supported. Array type claims are not supported at this time.
{{< /warning >}}

## Before you begin

Before you begin this task, do the following:

* Familiarize yourself with [Istio end user authentication](/docs/tasks/security/authentication/authn-policy/#end-user-authentication) support.

* Install Istio using [Istio installation guide](/docs/setup/install/istioctl/).

* Deploy `httpbin` and `sleep` workloads in namespace `foo` with sidecar injection enabled.
    Deploy the example namespace and workloads using these commands:

    {{< text bash >}}
    $ kubectl create ns foo
    $ kubectl label namespace foo istio-injection=enabled
    $ kubectl apply -f @samples/httpbin/httpbin.yaml@ -n foo
    $ kubectl apply -f @samples/sleep/sleep.yaml@ -n foo
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
    for the `httpbin` workload in the `foo` namespace. This policy
    accepts a JWT issued by `testing@secure.istio.io` and copies the value of claim `foo` to an HTTP header `X-Jwt-Claim-Foo`:

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

1. Get the JWT which is issued by `testing@secure.istio.io` and has a claim with key `foo`.

    {{< text syntax="bash" expandlinks="false" >}}
    $ TOKEN=$(curl {{< github_file >}}/security/tools/jwt/samples/demo.jwt -s) && echo "$TOKEN" | cut -d '.' -f2 - | base64 --decode -
    {"exp":4685989700,"foo":"bar","iat":1532389700,"iss":"testing@secure.istio.io","sub":"testing@secure.istio.io"}
    {{< /text >}}

1. Verify that a request with a valid JWT is allowed:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- curl "http://httpbin.foo:8000/headers" -sS -o /dev/null -H "Authorization: Bearer $TOKEN" -w "%{http_code}\n"
    200
    {{< /text >}}

1. Verify that a request contains a valid HTTP header with JWT claim value:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- curl "http://httpbin.foo:8000/headers" -sS -H "Authorization: Bearer $TOKEN" | grep "X-Jwt-Claim-Foo" | sed -e 's/^[ \t]*//'
    "X-Jwt-Claim-Foo": "bar"
    {{< /text >}}

## Clean up

Remove the namespace `foo`:

{{< text bash >}}
$ kubectl delete namespace foo
{{< /text >}}
