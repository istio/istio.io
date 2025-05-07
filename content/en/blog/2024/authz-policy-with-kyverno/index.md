---
title: Policy based authorization using Kyverno
description: Delegate Layer 7 authorization decision logic using Kyverno's Authz Server, leveraging policies based on CEL.
publishdate: 2024-11-25
attribution: "Charles-Edouard Brétéché (Nirmata)"
keywords: [istio,kyverno,policy,platform,authorization]
---

Istio supports integration with many different projects.  The Istio blog recently featured a post on [L7 policy functionality with OpenPolicyAgent](../l7-policy-with-opa). Kyverno is a similar project, and today we will dive how Istio and the Kyverno Authz Server can be used together to enforce Layer 7 policies in your platform.

We will show you how to get started with a simple example.
You will come to see how this combination is a solid option to deliver policy quickly and transparently to application team everywhere in the business, while also providing the data the security teams need for audit and compliance.

## Try it out

When integrated with Istio, the Kyverno Authz Server can be used to enforce fine-grained access control policies for microservices.

This guide shows how to enforce access control policies for a simple microservices application.

### Prerequisites

- A Kubernetes cluster with Istio installed.
- The `istioctl` command-line tool installed.

Install Istio and configure your [mesh options](/docs/reference/config/istio.mesh.v1alpha1/) to enable Kyverno:

{{< text bash >}}
$ istioctl install -y -f - <<EOF
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    accessLogFile: /dev/stdout
    accessLogFormat: |
      [KYVERNO DEMO] my-new-dynamic-metadata: '%DYNAMIC_METADATA(envoy.filters.http.ext_authz)%'
    extensionProviders:
    - name: kyverno-authz-server
      envoyExtAuthzGrpc:
        service: kyverno-authz-server.kyverno.svc.cluster.local
        port: '9081'
EOF
{{< /text >}}

Notice that in the configuration, we define an `extensionProviders` section that points to the Kyverno Authz Server installation:

{{< text yaml >}}
[...]
    extensionProviders:
    - name: kyverno-authz-server
      envoyExtAuthzGrpc:
        service: kyverno-authz-server.kyverno.svc.cluster.local
        port: '9081'
[...]
{{< /text >}}

#### Deploy the Kyverno Authz Server

The Kyverno Authz Server is a GRPC server capable of processing Envoy External Authorization requests.

It is configurable using Kyverno `AuthorizationPolicy` resources, either stored in-cluster or provided externally.

{{< text bash >}}
$ kubectl create ns kyverno
$ kubectl label namespace kyverno istio-injection=enabled
$ helm install kyverno-authz-server --namespace kyverno --wait --version 0.1.0 --repo https://kyverno.github.io/kyverno-envoy-plugin kyverno-authz-server
{{< /text >}}

#### Deploy the sample application

httpbin is a well-known application that can be used to test HTTP requests and helps to show quickly how we can play with the request and response attributes.

{{< text bash >}}
$ kubectl create ns my-app
$ kubectl label namespace my-app istio-injection=enabled
$ kubectl apply -f {{< github_file >}}/samples/httpbin/httpbin.yaml -n my-app
{{< /text >}}

#### Deploy an Istio AuthorizationPolicy

An `AuthorizationPolicy` defines the services that will be protected by the Kyverno Authz Server.

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: my-kyverno-authz
  namespace: istio-system # This enforce the policy on all the mesh, istio-system being the mesh root namespace
spec:
  selector:
    matchLabels:
      ext-authz: enabled
  action: CUSTOM
  provider:
    name: kyverno-authz-server
  rules: [{}] # Empty rules, it will apply to selectors with ext-authz: enabled label
EOF
{{< /text >}}

Notice that in this resource, we define the Kyverno Authz Server `extensionProvider` you set in the Istio configuration:

{{< text yaml >}}
[...]
  provider:
    name: kyverno-authz-server
[...]
{{< /text >}}

#### Label the app to enforce the policy

Let’s label the app to enforce the policy. The label is needed for the Istio `AuthorizationPolicy` to apply to the sample application pods.

{{< text bash >}}
$ kubectl patch deploy httpbin -n my-app --type=merge -p='{
  "spec": {
    "template": {
      "metadata": {
        "labels": {
          "ext-authz": "enabled"
        }
      }
    }
  }
}'
{{< /text >}}

#### Deploy a Kyverno AuthorizationPolicy

A Kyverno `AuthorizationPolicy` defines the rules used by the Kyverno Authz Server to make a decision based on a given Envoy [CheckRequest](https://www.envoyproxy.io/docs/envoy/latest/api-v3/service/auth/v3/external_auth.proto#service-auth-v3-checkrequest).

It uses the [CEL language](https://github.com/google/cel-spec) to analyze an incoming `CheckRequest` and is expected to produce a [CheckResponse](https://www.envoyproxy.io/docs/envoy/latest/api-v3/service/auth/v3/external_auth.proto#service-auth-v3-checkresponse) in return.

The incoming request is available under the `object` field, and the policy can define `variables` that will be made available to all `authorizations`.

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: envoy.kyverno.io/v1alpha1
kind: AuthorizationPolicy
metadata:
  name: demo-policy.example.com
spec:
  failurePolicy: Fail
  variables:
  - name: force_authorized
    expression: object.attributes.request.http.?headers["x-force-authorized"].orValue("")
  - name: allowed
    expression: variables.force_authorized in ["enabled", "true"]
  authorizations:
  - expression: >
      variables.allowed
        ? envoy.Allowed().Response()
        : envoy.Denied(403).Response()
EOF
{{< /text >}}

Notice that you can build the `CheckResponse` by hand or use [CEL helper functions](https://kyverno.github.io/kyverno-envoy-plugin/latest/cel-extensions/) like `envoy.Allowed()` and `envoy.Denied(403)` to simplify creating the response message:

{{< text yaml >}}
[...]
  - expression: >
      variables.allowed
        ? envoy.Allowed().Response()
        : envoy.Denied(403).Response()
[...]
{{< /text >}}

## How it works

When applying the `AuthorizationPolicy`, the Istio control plane (istiod) sends the required configurations to the sidecar proxy (Envoy) of the selected services in the policy.
Envoy will then send the request to the Kyverno Authz Server to check if the request is allowed or not.

{{< image width="75%" link="./overview.svg" alt="Istio and Kyverno Authz Server" >}}

The Envoy proxy works by configuring filters in a chain. One of those filters is `ext_authz`, which implements an external authorization service with a specific message. Any server implementing the correct protobuf can connect to the Envoy proxy and provide the authorization decision; The Kyverno Authz Server is one of those servers.

{{< image link="./filters-chain.svg" alt="Filters" >}}

Reviewing [Envoy's Authorization service documentation](https://www.envoyproxy.io/docs/envoy/latest/api-v3/service/auth/v3/external_auth.proto), you can see that the message has these attributes:

- Ok response

    {{< text json >}}
    {
      "status": {...},
      "ok_response": {
        "headers": [],
        "headers_to_remove": [],
        "response_headers_to_add": [],
        "query_parameters_to_set": [],
        "query_parameters_to_remove": []
      },
      "dynamic_metadata": {...}
    }
    {{< /text >}}

- Denied response

    {{< text json >}}
    {
      "status": {...},
      "denied_response": {
        "status": {...},
        "headers": [],
        "body": "..."
      },
      "dynamic_metadata": {...}
    }
    {{< /text >}}

This means that based on the response from the authz server, Envoy can add or remove headers, query parameters, and even change the response body.

We can do this as well, as documented in the [Kyverno Authz Server documentation](https://kyverno.github.io/kyverno-envoy-plugin).

## Testing

Let's test the simple usage (authorization) and then let's create a more advanced policy to show how we can use the Kyverno Authz Server to modify the request and response.

Deploy an app to run curl commands to the httpbin sample application:

{{< text bash >}}
$ kubectl apply -n my-app -f {{< github_file >}}/samples/curl/curl.yaml
{{< /text >}}

Apply the policy:

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: envoy.kyverno.io/v1alpha1
kind: AuthorizationPolicy
metadata:
  name: demo-policy.example.com
spec:
  failurePolicy: Fail
  variables:
  - name: force_authorized
    expression: object.attributes.request.http.?headers["x-force-authorized"].orValue("")
  - name: allowed
    expression: variables.force_authorized in ["enabled", "true"]
  authorizations:
  - expression: >
      variables.allowed
        ? envoy.Allowed().Response()
        : envoy.Denied(403).Response()
EOF
{{< /text >}}

The simple scenario is to allow requests if they contain the header `x-force-authorized` with the value `enabled` or `true`.
If the header is not present or has a different value, the request will be denied.

In this case, we combined allow and denied response handling in a single expression. However it is possible to use multiple expressions, the first one returning a non null response will be used by the Kyverno Authz Server, this is useful when a rule doesn't want to make a decision and delegate to the next rule:

{{< text yaml >}}
[...]
  authorizations:
  # allow the request when the header value matches
  - expression: >
      variables.allowed
        ? envoy.Allowed().Response()
        : null
  # else deny the request
  - expression: >
      envoy.Denied(403).Response()
[...]
{{< /text >}}

### Simple rule

The following request will return `403`:

{{< text bash >}}
$ kubectl exec -n my-app deploy/curl -- curl -s -w "\nhttp_code=%{http_code}" httpbin:8000/get
{{< /text >}}

The following request will return `200`:

{{< text bash >}}
$ kubectl exec -n my-app deploy/curl -- curl -s -w "\nhttp_code=%{http_code}" httpbin:8000/get -H "x-force-authorized: true"
{{< /text >}}

### Advanced manipulations

Now the more advanced use case, apply the second policy:

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: envoy.kyverno.io/v1alpha1
kind: AuthorizationPolicy
metadata:
  name: demo-policy.example.com
spec:
  variables:
  - name: force_authorized
    expression: object.attributes.request.http.headers[?"x-force-authorized"].orValue("") in ["enabled", "true"]
  - name: force_unauthenticated
    expression: object.attributes.request.http.headers[?"x-force-unauthenticated"].orValue("") in ["enabled", "true"]
  - name: metadata
    expression: '{"my-new-metadata": "my-new-value"}'
  authorizations:
    # if force_unauthenticated -> 401
  - expression: >
      variables.force_unauthenticated
        ? envoy
            .Denied(401)
            .WithBody("Authentication Failed")
            .Response()
        : null
    # if force_authorized -> 200
  - expression: >
      variables.force_authorized
        ? envoy
            .Allowed()
            .WithHeader("x-validated-by", "my-security-checkpoint")
            .WithoutHeader("x-force-authorized")
            .WithResponseHeader("x-add-custom-response-header", "added")
            .Response()
            .WithMetadata(variables.metadata)
        : null
    # else -> 403
  - expression: >
      envoy
        .Denied(403)
        .WithBody("Unauthorized Request")
        .Response()
EOF
{{< /text >}}

In that policy, you can see:

- If the request has the `x-force-unauthenticated: true`  header  (or `x-force-unauthenticated: enabled`), we will return `401` with the "Authentication Failed" body
- Else, if the request has the `x-force-authorized: true`  header  (or `x-force-authorized: enabled`), we will return `200` and manipulate request headers, response headers and inject dynamic metadata
- In all other cases, we will return `403` with the "Unauthorized Request" body

The corresponding CheckResponse will be returned to the Envoy proxy from the Kyverno Authz Server. Envoy will use those values to modify the request and response accordingly.

#### Change returned body

Let's test the new capabilities:

{{< text bash >}}
$ kubectl exec -n my-app deploy/curl -- curl -s -w "\nhttp_code=%{http_code}" httpbin:8000/get
{{< /text >}}

Now we can change the response body.

With `403` the body will be changed to "Unauthorized Request", running the previous command, you should receive:

{{< text plain >}}
Unauthorized Request
http_code=403
{{< /text >}}

#### Change returned body and status code

Running the request with the header `x-force-unauthenticated: true`:

{{< text bash >}}
$ kubectl exec -n my-app deploy/curl -- curl -s -w "\nhttp_code=%{http_code}" httpbin:8000/get -H "x-force-unauthenticated: true"
{{< /text >}}

This time you should receive the body "Authentication Failed" and error `401`:

{{< text plain >}}
Authentication Failed
http_code=401
{{< /text >}}

#### Adding headers to request

Running a valid request:

{{< text bash >}}
$ kubectl exec -n my-app deploy/curl -- curl -s -w "\nhttp_code=%{http_code}" httpbin:8000/get -H "x-force-authorized: true"
{{< /text >}}

You should receive the echo body with the new header `x-validated-by: my-security-checkpoint` and the header `x-force-authorized` removed:

{{< text plain >}}
[...]
    "X-Validated-By": [
      "my-security-checkpoint"
    ]
[...]
http_code=200
{{< /text >}}

#### Adding headers to response

Running the same request but showing only the header:

{{< text bash >}}
$ kubectl exec -n my-app deploy/curl -- curl -s -I -w "\nhttp_code=%{http_code}" httpbin:8000/get -H "x-force-authorized: true"
{{< /text >}}

You will find the response header added during the Authz check `x-add-custom-response-header: added`:

{{< text plain >}}
HTTP/1.1 200 OK
[...]
x-add-custom-response-header: added
[...]
http_code=200
{{< /text >}}

### Sharing data between filters

Finally, you can pass data to the following Envoy filters using `dynamic_metadata`.

This is useful when you want to pass data to another `ext_authz` filter in the chain or you want to print it in the application logs.

{{< image link="./dynamic-metadata.svg" alt="Metadata" >}}

To do so, review the access log format you set earlier:

{{< text plain >}}
[...]
    accessLogFormat: |
      [KYVERNO DEMO] my-new-dynamic-metadata: "%DYNAMIC_METADATA(envoy.filters.http.ext_authz)%"
[...]
{{< /text >}}

`DYNAMIC_METADATA` is a reserved keyword to access the metadata object. The rest is the name of the filter that you want to access.

In our case, the name `envoy.filters.http.ext_authz` is created automatically by Istio. You can verify this by dumping the Envoy configuration:

{{< text bash >}}
$ istioctl pc all deploy/httpbin -n my-app -oyaml | grep envoy.filters.http.ext_authz
{{< /text >}}

You will see the configurations for the filter.

Let's test the dynamic metadata. In the advance rule, we are creating a new metadata entry: `{"my-new-metadata": "my-new-value"}`.

Run the request and check the logs of the application:

{{< text bash >}}
$ kubectl exec -n my-app deploy/curl -- curl -s -I httpbin:8000/get -H "x-force-authorized: true"
{{< /text >}}

{{< text bash >}}
$ kubectl logs -n my-app deploy/httpbin -c istio-proxy --tail 1
{{< /text >}}

You will see in the output the new attributes configured by the Kyverno policy:

{{< text plain >}}
[...]
[KYVERNO DEMO] my-new-dynamic-metadata: '{"my-new-metadata":"my-new-value","ext_authz_duration":5}'
[...]
{{< /text >}}

## Conclusion

In this guide, we have shown how to integrate Istio and the Kyverno Authz Server to enforce policies for a simple microservices application.
We also showed how to use policies to modify the request and response attributes.

This is the foundational example for building a platform-wide policy system that can be used by all application teams.
