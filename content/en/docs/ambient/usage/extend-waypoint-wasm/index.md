---
title: Extend waypoints with WebAssembly plugins
description: Describes how to make remote WebAssembly modules available for ambient mode.
weight: 55
keywords: [extensibility,Wasm,WebAssembly,Ambient]
owner: istio/wg-policies-and-telemetry-maintainers
test: yes
status: Alpha
---

{{< boilerplate alpha >}}

Istio provides the ability to [extend its functionality using WebAssembly (Wasm)](/docs/concepts/wasm/).
One of the key advantages of Wasm extensibility is that extensions can be loaded dynamically at runtime. This document outlines how to extend ambient mode within Istio with Wasm features. In ambient mode, Wasm configuration must be applied to the waypoint proxy deployed in each namespace.

## Install Ambient Mode and deploy test applications

Follow the [Ambient Getting Started Guide](/docs/ambient/getting-started) to install Istio in ambient mode. Deploy the [sample applications](/docs/ambient/getting-started/deploy-sample-app) required for exploring waypoint proxy extensibility via Wasm. Make sure to [add the sample applications](/docs/ambient/getting-started/secure-and-visualize) to the mesh before proceeding further.

## Apply Wasm configuration at the Gateway

With Kubernetes Gateway API, Istio provides a centralized entry point for managing traffic into the service mesh. We will configure a WasmPlugin at the gateway level, ensuring that all traffic passing through the gateway is subject to the extended authentication rules.

### Configure WasmPlugin for Gateway

In this example, you will add a HTTP [Basic auth module](https://github.com/istio-ecosystem/wasm-extensions/tree/master/extensions/basic_auth) to your mesh. You will configure Istio to pull the Basic auth module from a remote image registry and load it. It will be configured to run on calls to `/productpage`. Steps are more or less similar as [Istio / Distributing WebAssembly Modules](/docs/tasks/extensibility/wasm-module-distribution/), only difference being the recommended usage of `targetRefs` instead of `labelSelectors` in WasmPlugin.

To configure a WebAssembly filter with a remote Wasm module, create a `WasmPlugin` resource targeting the `bookinfo-gateway`:

{{< text bash >}}
$ kubectl get gateway
NAME               CLASS            ADDRESS                                            PROGRAMMED   AGE
bookinfo-gateway   istio            bookinfo-gateway-istio.default.svc.cluster.local   True         42m
{{< /text >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: extensions.istio.io/v1alpha1
kind: WasmPlugin
metadata:
  name: basic-auth-at-gateway
spec:
  targetRefs:
    - kind: Gateway
      group: gateway.networking.k8s.io
      name: bookinfo-gateway # gateway name retrieved from previous step
  url: oci://ghcr.io/istio-ecosystem/wasm-extensions/basic_auth:1.12.0
  phase: AUTHN
  pluginConfig:
    basic_auth_rules:
      - prefix: "/productpage"
        request_methods:
          - "GET"
          - "POST"
        credentials:
          - "ok:test"
          - "YWRtaW4zOmFkbWluMw=="
EOF
{{< /text >}}

An HTTP filter will be injected at the gateway as an authentication filter.
The Istio agent will interpret the WasmPlugin configuration, download remote Wasm modules from the OCI image registry to a local file, and inject the HTTP filter at the gateway by referencing that file.

### Verify the traffic via the Gateway

1. Test `/productpage` without credentials

    {{< text bash >}}
    $ kubectl exec deploy/sleep -- curl -s -w "%{http_code}" -o /dev/null "http://bookinfo-gateway-istio.default.svc.cluster.local/productpage"
    401
    {{< /text >}}

1. Test `/productpage` with credentials configured in the WasmPlugin resource

    {{< text bash >}}
    $ kubectl exec deploy/sleep -- curl -s -o /dev/null -H "Authorization: Basic YWRtaW4zOmFkbWluMw==" -w "%{http_code}" "http://bookinfo-gateway-istio.default.svc.cluster.local/productpage"
    200
    {{< /text >}}

## Apply Wasm Configuration at Waypoint Proxy

Waypoint proxies play a crucial role in Istio's ambient mode, facilitating secure and efficient communication within the service mesh. Below, we will explore how to apply Wasm configuration to the waypoint, enhancing the proxy functionality dynamically.

### Deploy a waypoint proxy

Follow the [waypoint deployment instructions](/docs/ambient/getting-started/#layer-7-authorization-policy) to deploy a waypoint proxy in the bookinfo namespace.

{{< text bash >}}
$ istioctl waypoint apply --enroll-namespace --wait
{{< /text >}}

### Verify traffic without WasmPlugin at the waypoint

{{< text bash >}}
$ kubectl exec deploy/sleep -- curl -s -w "%{http_code}" -o /dev/null http://productpage:9080/productpage
200
{{< /text >}}

### Apply WasmPlugin at waypoint proxy

To configure a WebAssembly filter with a remote Wasm module, create a `WasmPlugin` resource targeting the `waypoint` gateway:

{{< text bash >}}
$ kubectl get gateway
NAME               CLASS            ADDRESS                                            PROGRAMMED   AGE
bookinfo-gateway   istio            bookinfo-gateway-istio.default.svc.cluster.local   True         23h
waypoint           istio-waypoint   10.96.202.82                                       True         21h
{{< /text >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: extensions.istio.io/v1alpha1
kind: WasmPlugin
metadata:
  name: basic-auth-at-waypoint
spec:
  targetRefs:
    - kind: Gateway
      group: gateway.networking.k8s.io
      name: waypoint # gateway name retrieved from previous step
  url: oci://ghcr.io/istio-ecosystem/wasm-extensions/basic_auth:1.12.0
  phase: AUTHN
  pluginConfig:
    basic_auth_rules:
      - prefix: "/productpage"
        request_methods:
          - "GET"
          - "POST"
        credentials:
          - "ok:test"
          - "YWRtaW4zOmFkbWluMw=="
EOF
{{< /text >}}

### View the configured WasmPlugin

{{< text bash >}}
$ kubectl get wasmplugin
NAME                     AGE
basic-auth-at-gateway    28m
basic-auth-at-waypoint   14m
{{< /text >}}

### Verify the traffic via waypoint proxy

1. Test internal `/productpage` without credentials

    {{< text bash >}}
    $ kubectl exec deploy/sleep -- curl -s -w "%{http_code}" -o /dev/null http://productpage:9080/productpage
    401
    {{< /text >}}

1. Test internal `/productpage` with credentials

    {{< text bash >}}
    $ kubectl exec deploy/sleep -- curl -s -w "%{http_code}" -o /dev/null -H "Authorization: Basic YWRtaW4zOmFkbWluMw==" http://productpage:9080/productpage
    200
    {{< /text >}}

## Apply WasmPlugin for a specific Service using Waypoint

To configure a WebAssembly filter with a remote Wasm module for a specific service, create a WasmPlugin resource targeting the specific service directly.

Create a `WasmPlugin` targeting the `reviews` service so that the extension applies only to the `reviews` service. In this configuration, the authentication token and the prefix are tailored specifically for the reviews service, ensuring that only requests directed towards it are subjected to this authentication mechanism.

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: extensions.istio.io/v1alpha1
kind: WasmPlugin
metadata:
  name: basic-auth-for-service
spec:
  targetRefs:
    - kind: Service
      group: ""
      name: reviews
  url: oci://ghcr.io/istio-ecosystem/wasm-extensions/basic_auth:1.12.0
  phase: AUTHN
  pluginConfig:
    basic_auth_rules:
      - prefix: "/reviews"
        request_methods:
          - "GET"
          - "POST"
        credentials:
          - "ok:test"
          - "MXQtaW4zOmFkbWluMw=="
EOF
{{< /text >}}

### Verify the traffic targeting the Service

1. Test internal `/productpage` with credentials configured at the generic `waypoint` proxy

    {{< text bash >}}
    $ kubectl exec deploy/sleep -- curl -s -w "%{http_code}" -o /dev/null -H "Authorization: Basic YWRtaW4zOmFkbWluMw==" http://productpage:9080/productpage
    200
    {{< /text >}}

1. Test internal `/reviews` with credentials configured at the specific `reviews-svc-waypoint` proxy

    {{< text bash >}}
    $ kubectl exec deploy/sleep -- curl -s -w "%{http_code}" -o /dev/null -H "Authorization: Basic MXQtaW4zOmFkbWluMw==" http://reviews:9080/reviews/1
    200
    {{< /text >}}

1. Test internal `/reviews` without credentials

    {{< text bash >}}
    $ kubectl exec deploy/sleep -- curl -s -w "%{http_code}" -o /dev/null http://reviews:9080/reviews/1
    401
    {{< /text >}}

When executing the provided command without credentials, it verifies that accessing the internal `/productpage` results in a 401 unauthorized response, demonstrating the expected behavior of failing to access the resource without proper authentication credentials.

### Cleanup

1. Remove WasmPlugin configuration:

    {{< text bash >}}
    $ kubectl delete wasmplugin basic-auth-at-gateway basic-auth-at-waypoint basic-auth-for-service
    {{< /text >}}

1. Follow [the ambient mode uninstall guide](/docs/ambient/getting-started/#uninstall) to remove Istio and sample test applications.
