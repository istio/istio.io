---
title: Better External Authorization
subtitle: Integrate external authorization system (e.g. OPA, oauth2-proxy, etc.) with Istio using AuthorizationPolicy
description: AuthorizationPolicy now supports CUSTOM action to delegate the authorization to external system.
publishdate: 2021-02-09
attribution: Yangmin Zhu (Google)
keywords: [authorization,access control,opa,oauth2]
---

## Background

Istio's authorization policy provides access control for services in the mesh. It is fast, powerful and a widely used
feature. We have made continuous improvements to make policy more flexible since its first release in Istio 1.4, including
the [`DENY` action](/docs/tasks/security/authorization/authz-deny/), [exclusion semantics](/docs/tasks/security/authorization/authz-deny/),
[`X-Forwarded-For` header support](/docs/tasks/security/authorization/authz-ingress/), [nested JWT claim support](/docs/tasks/security/authorization/authz-jwt/)
and more. These features improve the flexibility of the authorization policy, but there are still many use cases that
cannot be supported with this model, for example:

- You have your own in-house authorization system that cannot be easily migrated to, or cannot be easily replaced by, the
  authorization policy.

- You want to integrate with a 3rd-party solution (e.g. [Open Policy Agent](https://www.openpolicyagent.org/docs/latest/envoy-introduction/)
  or [`oauth2` proxy](https://github.com/oauth2-proxy/oauth2-proxy)) which may require use of the
  [low-level Envoy configuration APIs](/docs/reference/config/networking/envoy-filter/) in Istio, or may not be possible
  at all.

- Authorization policy lacks necessary semantics for your use case.

## Solution

In Istio 1.9, we have implemented extensibility into authorization policy by introducing a [`CUSTOM` action](/docs/reference/config/security/authorization-policy/#AuthorizationPolicy-Action),
which allows you to delegate the access control decision to an external authorization service.

The `CUSTOM` action allows you to integrate Istio with an external authorization system that implements its own custom
authorization logic. The following diagram shows the high level architecture of this integration:

{{< image width="100%" link="./external_authz.svg" caption="External Authorization Architecture" >}}

At configuration time, the mesh admin configures an authorization policy with a `CUSTOM` action to enable the
external authorization on a proxy (either gateway or sidecar). The admin should verify the external auth service is up
and running.

At runtime,

1. A request is intercepted by the proxy, and the proxy will send check requests to the external auth service, as
   configured by the user in the authorization policy.

1. The external auth service will make the decision whether to allow it or not.

1. If allowed, the request will continue and will be enforced by any local authorization defined by `ALLOW`/`DENY` action.

1. If denied, the request will be rejected immediately.

Let's look at an example authorization policy with the `CUSTOM` action:

{{< text yaml >}}
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: ext-authz
  namespace: istio-system
spec:
  # The selector applies to the ingress gateway in the istio-system namespace.
  selector:
    matchLabels:
      app: istio-ingressgateway
  # The action "CUSTOM" delegates the access control to an external authorizer, this is different from
  # the ALLOW/DENY action that enforces the access control right inside the proxy.
  action: CUSTOM
  # The provider specifies the name of the external authorizer defined in the meshconfig, which tells where and how to
  # talk to the external auth service. We will cover this more later.
  provider:
    name: "my-ext-authz-service"
  # The rule specifies that the access control is triggered only if the request path has the prefix "/admin/".
  # This allows you to easily enable or disable the external authorization based on the requests, avoiding the external
  # check request if it is not needed.
  rules:
  - to:
    - operation:
        paths: ["/admin/*"]
{{< /text >}}

It refers to a provider called `my-ext-authz-service` which is defined in the mesh config:

{{< text yaml >}}
extensionProviders:
# The name "my-ext-authz-service" is referred to by the authorization policy in its provider field.
- name: "my-ext-authz-service"
  # The "envoyExtAuthzGrpc" field specifies the type of the external authorization service is implemented by the Envoy
  # ext-authz filter gRPC API. The other supported type is the Envoy ext-authz filter HTTP API.
  # See more in https://www.envoyproxy.io/docs/envoy/v1.16.2/intro/arch_overview/security/ext_authz_filter.
  envoyExtAuthzGrpc:
    # The service and port specifies the address of the external auth service, "ext-authz.istio-system.svc.cluster.local"
    # means the service is deployed in the mesh. It can also be defined out of the mesh or even inside the pod as a separate
    # container.
    service: "ext-authz.istio-system.svc.cluster.local"
    port: 9000
{{< /text >}}

The authorization policy of [`CUSTOM` action](/docs/reference/config/security/authorization-policy/#AuthorizationPolicy-Action)
enables the external authorization in runtime, it could be configured to trigger the external authorization conditionally
based on the request using the same rule that you have already been using with other actions.

The external authorization service is currently defined in the [`meshconfig` API](/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig-ExtensionProvider)
and referred to by its name. It could be deployed in the mesh with or without proxy. If with the proxy, you could
further use `PeerAuthentication` to enable mTLS between the proxy and your external authorization service.

The `CUSTOM` action is currently in the **experimental stage**; the API might change in a non-backward compatible way based on user feedback.
The authorization policy rules currently don't support authentication fields (e.g. source principal or JWT claim) when used with the
`CUSTOM` action. Only one provider is allowed for a given workload, but you can still use different providers on different workloads.

For more information, please see the [Better External Authorization design doc](https://docs.google.com/document/d/1V4mCQCw7mlGp0zSQQXYoBdbKMDnkPOjeyUb85U07iSI/edit#).

## Example with OPA

In this section, we will demonstrate using the `CUSTOM` action with the Open Policy Agent as the external authorizer on
the ingress gateway. We will conditionally enable the external authorization on all paths except `/ip`.

You can also refer to the [external authorization task](/docs/tasks/security/authorization/authz-custom/) for a more
basic introduction that uses a sample `ext-authz` server.

### Create the example OPA policy

Run the following command create an OPA policy that allows the request if the prefix of the path is matched with the
claim "path" (base64 encoded) in the JWT token:

{{< text bash >}}
$ cat > policy.rego <<EOF
package envoy.authz

import input.attributes.request.http as http_request

default allow = false

token = {"valid": valid, "payload": payload} {
    [_, encoded] := split(http_request.headers.authorization, " ")
    [valid, _, payload] := io.jwt.decode_verify(encoded, {"secret": "secret"})
}

allow {
    is_token_valid
    action_allowed
}

is_token_valid {
  token.valid
  now := time.now_ns() / 1000000000
  token.payload.nbf <= now
  now < token.payload.exp
}

action_allowed {
  startswith(http_request.path, base64url.decode(token.payload.path))
}
EOF
$ kubectl create secret generic opa-policy --from-file policy.rego
{{< /text >}}

### Deploy httpbin and OPA

Enable the sidecar injection:

{{< text bash >}}
$ kubectl label ns default istio-injection=enabled
{{< /text >}}

Run the following command to deploy the example application httpbin and OPA. The OPA could be deployed either as a
separate container in the httpbin pod or completely in a separate pod:

{{< tabset category-name="opa-deploy" >}}

{{< tab name="Deploy OPA in the same pod" category-value="opa-same" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: httpbin-with-opa
  labels:
    app: httpbin-with-opa
    service: httpbin-with-opa
spec:
  ports:
  - name: http
    port: 8000
    targetPort: 80
  selector:
    app: httpbin-with-opa
---
# Define the service entry for the local OPA service on port 9191.
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: local-opa-grpc
spec:
  hosts:
  - "local-opa-grpc.local"
  endpoints:
  - address: "127.0.0.1"
  ports:
  - name: grpc
    number: 9191
    protocol: GRPC
  resolution: STATIC
---
kind: Deployment
apiVersion: apps/v1
metadata:
  name: httpbin-with-opa
  labels:
    app: httpbin-with-opa
spec:
  replicas: 1
  selector:
    matchLabels:
      app: httpbin-with-opa
  template:
    metadata:
      labels:
        app: httpbin-with-opa
    spec:
      containers:
        - image: docker.io/kennethreitz/httpbin
          imagePullPolicy: IfNotPresent
          name: httpbin
          ports:
          - containerPort: 80
        - name: opa
          image: openpolicyagent/opa:latest-envoy
          securityContext:
            runAsUser: 1111
          volumeMounts:
          - readOnly: true
            mountPath: /policy
            name: opa-policy
          args:
          - "run"
          - "--server"
          - "--addr=localhost:8181"
          - "--diagnostic-addr=0.0.0.0:8282"
          - "--set=plugins.envoy_ext_authz_grpc.addr=:9191"
          - "--set=plugins.envoy_ext_authz_grpc.query=data.envoy.authz.allow"
          - "--set=decision_logs.console=true"
          - "--ignore=.*"
          - "/policy/policy.rego"
          livenessProbe:
            httpGet:
              path: /health?plugins
              scheme: HTTP
              port: 8282
            initialDelaySeconds: 5
            periodSeconds: 5
          readinessProbe:
            httpGet:
              path: /health?plugins
              scheme: HTTP
              port: 8282
            initialDelaySeconds: 5
            periodSeconds: 5
      volumes:
        - name: proxy-config
          configMap:
            name: proxy-config
        - name: opa-policy
          secret:
            secretName: opa-policy
EOF
{{< /text >}}

{{< /tab >}}

{{< tab name="Deploy OPA in a separate pod" category-value="opa-standalone" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: opa
  labels:
    app: opa
spec:
  ports:
  - name: grpc
    port: 9191
    targetPort: 9191
  selector:
    app: opa
---
kind: Deployment
apiVersion: apps/v1
metadata:
  name: opa
  labels:
    app: opa
spec:
  replicas: 1
  selector:
    matchLabels:
      app: opa
  template:
    metadata:
      labels:
        app: opa
    spec:
      containers:
        - name: opa
          image: openpolicyagent/opa:latest-envoy
          securityContext:
            runAsUser: 1111
          volumeMounts:
          - readOnly: true
            mountPath: /policy
            name: opa-policy
          args:
          - "run"
          - "--server"
          - "--addr=localhost:8181"
          - "--diagnostic-addr=0.0.0.0:8282"
          - "--set=plugins.envoy_ext_authz_grpc.addr=:9191"
          - "--set=plugins.envoy_ext_authz_grpc.query=data.envoy.authz.allow"
          - "--set=decision_logs.console=true"
          - "--ignore=.*"
          - "/policy/policy.rego"
          ports:
          - containerPort: 9191
          livenessProbe:
            httpGet:
              path: /health?plugins
              scheme: HTTP
              port: 8282
            initialDelaySeconds: 5
            periodSeconds: 5
          readinessProbe:
            httpGet:
              path: /health?plugins
              scheme: HTTP
              port: 8282
            initialDelaySeconds: 5
            periodSeconds: 5
      volumes:
        - name: proxy-config
          configMap:
            name: proxy-config
        - name: opa-policy
          secret:
            secretName: opa-policy
EOF
{{< /text >}}

Deploy the httpbin as well:

{{< text bash >}}
$ kubectl apply -f @samples/httpbin/httpbin.yaml@
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

### Define external authorizer

Run the following command to edit the `meshconfig`:

{{< text bash >}}
$ kubectl edit configmap istio -n istio-system
{{< /text >}}

Add the following `extensionProviders` to the `meshconfig`:

{{< tabset category-name="opa-deploy" >}}

{{< tab name="Deploy OPA in the same pod" category-value="opa-same" >}}

{{< text yaml >}}
apiVersion: v1
data:
  mesh: |-
    # Add the following contents:
    extensionProviders:
    - name: "opa.local"
      envoyExtAuthzGrpc:
        service: "local-opa-grpc.local"
        port: "9191"
{{< /text >}}

{{< /tab >}}

{{< tab name="Deploy OPA in a separate pod" category-value="opa-standalone" >}}

{{< text yaml >}}
apiVersion: v1
data:
  mesh: |-
    # Add the following contents:
    extensionProviders:
    - name: "opa.default"
      envoyExtAuthzGrpc:
        service: "opa.default.svc.cluster.local"
        port: "9191"
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

### Create an AuthorizationPolicy with a CUSTOM action

Run the following command to create the authorization policy that enables the external authorization on all paths
except `/ip`:

{{< tabset category-name="opa-deploy" >}}

{{< tab name="Deploy OPA in the same pod" category-value="opa-same" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: httpbin-opa
spec:
  selector:
    matchLabels:
      app: httpbin-with-opa
  action: CUSTOM
  provider:
    name: "opa.local"
  rules:
  - to:
    - operation:
        notPaths: ["/ip"]
EOF
{{< /text >}}

{{< /tab >}}

{{< tab name="Deploy OPA in a separate pod" category-value="opa-standalone" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: httpbin-opa
spec:
  selector:
    matchLabels:
      app: httpbin
  action: CUSTOM
  provider:
    name: "opa.default"
  rules:
  - to:
    - operation:
        notPaths: ["/ip"]
EOF
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

### Test the OPA policy

1. Create a client pod to send the request:

    {{< text bash >}}
    $ kubectl apply -f @samples/sleep/sleep.yaml@
    $ export SLEEP_POD=$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})
    {{< /text >}}

1. Use a test JWT token signed by the OPA:

    {{< text bash >}}
    $ export TOKEN_PATH_HEADERS="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJwYXRoIjoiTDJobFlXUmxjbk09IiwibmJmIjoxNTAwMDAwMDAwLCJleHAiOjE5MDAwMDAwMDB9.9yl8LcZdq-5UpNLm0Hn0nnoBHXXAnK4e8RSl9vn6l98"
    {{< /text >}}

    The test JWT token has the following claims:

    {{< text json >}}
    {
      "path": "L2hlYWRlcnM=",
      "nbf": 1500000000,
      "exp": 1900000000
    }
    {{< /text >}}

    The `path` claim has value `L2hlYWRlcnM=` which is the base64 encode of `/headers`.

1. Send a request to path `/headers` without a token. This should be rejected with 403 because there is no JWT token:

    {{< text bash >}}
    $ kubectl exec ${SLEEP_POD} -c sleep  -- curl http://httpbin-with-opa:8000/headers -s -o /dev/null -w "%{http_code}\n"
    403
    {{< /text >}}

1. Send a request to path `/get` with a valid token. This should be rejected with 403 because the path `/get` is not matched with the token `/headers`:

    {{< text bash >}}
    $ kubectl exec ${SLEEP_POD} -c sleep  -- curl http://httpbin-with-opa:8000/get -H "Authorization: Bearer $TOKEN_PATH_HEADERS" -s -o /dev/null -w "%{http_code}\n"
    403
    {{< /text >}}

1. Send a request to path `/headers` with valid token. This should be allowed with 200 because the path is matched with the token:

    {{< text bash >}}
    $ kubectl exec ${SLEEP_POD} -c sleep  -- curl http://httpbin-with-opa:8000/headers -H "Authorization: Bearer $TOKEN_PATH_HEADERS" -s -o /dev/null -w "%{http_code}\n"
    200
    {{< /text >}}

1. Send request to path `/ip` without token. This should be allowed with 200 because the path `/ip` is excluded from
   authorization:

    {{< text bash >}}
    $ kubectl exec ${SLEEP_POD} -c sleep  -- curl http://httpbin-with-opa:8000/ip -s -o /dev/null -w "%{http_code}\n"
    200
    {{< /text >}}

1. Check the proxy and OPA logs to confirm the result.

## Summary

In Istio 1.9, the `CUSTOM` action in the authorization policy allows you to easily integrate Istio with any external
authorization system with the following benefits:

- First-class support in the authorization policy API

- Ease of usage: define the external authorizer simply with a URL and enable with the authorization policy, no more
  hassle with the `EnvoyFilter` API

- Conditional triggering,  allowing improved performance

- Support for various deployment type of the external authorizer:

    - A normal service and pod with or without proxy

    - Inside the workload pod as a separate container

    - Outside the mesh

We're working to promote this feature to a more stable stage in following versions and welcome your feedback at
[discuss.istio.io](https://discuss.istio.io/c/security/).

## Acknowledgements

Thanks to `Craig Box`, `Christian Posta` and `Limin Wang` for reviewing drafts of this blog.
