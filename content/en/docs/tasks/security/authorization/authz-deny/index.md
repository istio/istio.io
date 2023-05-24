---
title: Explicit Deny
description: Shows how to set up access control to deny traffic explicitly.
weight: 40
keywords: [security,access-control,rbac,authorization,deny]
owner: istio/wg-security-maintainers
test: yes
---

This task shows you how to set up Istio authorization policy of `DENY` action to explicitly deny traffic in an Istio
mesh. This is different from the `ALLOW` action because the `DENY` action has higher priority and will not be
bypassed by any `ALLOW` actions.

## Before you begin

Before you begin this task, do the following:

* Read the [Istio authorization concepts](/docs/concepts/security/#authorization).

* Follow the [Istio installation guide](/docs/setup/install/istioctl/) to install Istio.

* Deploy workloads:

    This task uses two workloads, `httpbin` and `sleep`, deployed on one namespace, `foo`.
    Both workloads run with an Envoy proxy in front of each. Deploy the example namespace
    and workloads with the following command:

    {{< text bash >}}
    $ kubectl create ns foo
    $ kubectl apply -f <(istioctl kube-inject -f @samples/httpbin/httpbin.yaml@) -n foo
    $ kubectl apply -f <(istioctl kube-inject -f @samples/sleep/sleep.yaml@) -n foo
    {{< /text >}}

* Verify that `sleep` talks to `httpbin` with the following command:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- curl http://httpbin.foo:8000/ip -sS -o /dev/null -w "%{http_code}\n"
    200
    {{< /text >}}

{{< warning >}}
If you don’t see the expected output as you follow the task, retry after a few seconds.
Caching and propagation overhead can cause some delay.
{{< /warning >}}

## Explicitly deny a request

1. The following command creates the `deny-method-get` authorization policy for the `httpbin` workload
    in the `foo` namespace. The policy sets the `action` to `DENY` to deny requests that satisfy
    the conditions set in the `rules` section. This type of policy is better known as a deny policy.
    In this case, the policy denies requests if their method is `GET`.

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: security.istio.io/v1
    kind: AuthorizationPolicy
    metadata:
      name: deny-method-get
      namespace: foo
    spec:
      selector:
        matchLabels:
          app: httpbin
      action: DENY
      rules:
      - to:
        - operation:
            methods: ["GET"]
    EOF
    {{< /text >}}

1. Verify that `GET` requests are denied:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- curl "http://httpbin.foo:8000/get" -X GET -sS -o /dev/null -w "%{http_code}\n"
    403
    {{< /text >}}

1. Verify that `POST` requests are allowed:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- curl "http://httpbin.foo:8000/post" -X POST -sS -o /dev/null -w "%{http_code}\n"
    200
    {{< /text >}}

1. Update the `deny-method-get` authorization policy to deny `GET` requests only if
    the `x-token` value of the HTTP header is not `admin`. The following example
    policy sets the value of the `notValues` field to `["admin"]` to deny requests with
    a header value that is not `admin`:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: security.istio.io/v1
    kind: AuthorizationPolicy
    metadata:
      name: deny-method-get
      namespace: foo
    spec:
      selector:
        matchLabels:
          app: httpbin
      action: DENY
      rules:
      - to:
        - operation:
            methods: ["GET"]
        when:
        - key: request.headers[x-token]
          notValues: ["admin"]
    EOF
    {{< /text >}}

1. Verify that `GET` requests with the HTTP header `x-token: admin` are allowed:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- curl "http://httpbin.foo:8000/get" -X GET -H "x-token: admin" -sS -o /dev/null -w "%{http_code}\n"
    200
    {{< /text >}}

1. Verify that GET requests with the HTTP header `x-token: guest` are denied:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- curl "http://httpbin.foo:8000/get" -X GET -H "x-token: guest" -sS -o /dev/null -w "%{http_code}\n"
    403
    {{< /text >}}

1. The following command creates the `allow-path-ip` authorization policy to allow requests
    at the `/ip` path to the `httpbin` workload. This authorization policy sets the `action` field
    to `ALLOW`. This type of policy is better known as an allow policy.

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: security.istio.io/v1
    kind: AuthorizationPolicy
    metadata:
      name: allow-path-ip
      namespace: foo
    spec:
      selector:
        matchLabels:
          app: httpbin
      action: ALLOW
      rules:
      - to:
        - operation:
            paths: ["/ip"]
    EOF
    {{< /text >}}

1. Verify that `GET` requests with the HTTP header `x-token: guest` at path `/ip` are denied
    by the `deny-method-get` policy. Deny policies takes precedence over the allow policies:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- curl "http://httpbin.foo:8000/ip" -X GET -H "x-token: guest" -s -o /dev/null -w "%{http_code}\n"
    403
    {{< /text >}}

1. Verify that `GET` requests with the HTTP header `x-token: admin` at path `/ip` are
    allowed by the `allow-path-ip` policy:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- curl "http://httpbin.foo:8000/ip" -X GET -H "x-token: admin" -s -o /dev/null -w "%{http_code}\n"
    200
    {{< /text >}}

1. Verify that `GET` requests with the HTTP header `x-token: admin` at path `/get` are
    denied because they don’t match the `allow-path-ip` policy:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- curl "http://httpbin.foo:8000/get" -X GET -H "x-token: admin" -s -o /dev/null -w "%{http_code}\n"
    403
    {{< /text >}}

## Clean up

Remove the namespace `foo` from your configuration:

{{< text bash >}}
$ kubectl delete namespace foo
{{< /text >}}
