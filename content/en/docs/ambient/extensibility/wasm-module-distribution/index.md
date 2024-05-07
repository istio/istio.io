---
title: Distributing WebAssembly Modules
description: Describes how to make remote WebAssembly modules available for ambient mode.
weight: 1
keywords: [extensibility,Wasm,WebAssembly,Ambient]
owner: istio/wg-policies-and-telemetry-maintainers
test: no
status: Alpha
---

{{< boilerplate alpha >}}

Istio provides the ability to [extend its functionality using WebAssembly (Wasm)](/blog/2020/wasm-announce/).
One of the key advantages of Wasm extensibility is that extensions can be loaded dynamically at runtime. This document outlines the testing process for the implementation of Wasm features in Ambient mode within Istio. In Ambient mode, Wasm configuration must be applied to the waypoint proxy deployed in each namespace, instead of to individual sidecars. This approach is essential due to the absence of sidecars in Ambient mode, which is a key distinction from previous configurations.

### Install Ambient Mesh and deploy sample applications

Follow the [Ambient Getting Started Guide](docs/ambient/getting-started/#download) to install Istio in ambient mode. Deploy the [sample applications](docs/ambient/getting-started/#bookinfo) required for testing the Wasm behavior. Make sure to add the test [applications to ambient mesh](docs/ambient/getting-started/#addtoambient) before proceeding further.

### Apply the Wasm configuration at the Gateway

In this example, you will add a HTTP [Basic auth module](https://github.com/istio-ecosystem/wasm-extensions/tree/master/extensions/basic_auth) to your mesh. You will configure Istio to pull the Basic auth module from a remote image registry and load it. It will be configured to run on calls to `/productpage`. Steps are more or less similar as [Istio / Distributing WebAssembly Modules](docs/tasks/extensibility/wasm-module-distribution/), only difference being the usage of `targetRef` instead of `labelSelectors` in WasmPlugin.

To configure a WebAssembly filter with a remote Wasm module, create a `WasmPlugin` resource targeting the `bookinfo-gateway`:

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: extensions.istio.io/v1alpha1
kind: WasmPlugin
metadata:
  name: basic-auth-at-gateway
spec:
  targetRef:
    group: gateway.networking.k8s.io
    kind: Gateway
    name: bookinfo-gateway
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

## Verify the traffic via the Gateway

1. Test `/productpage` without credentials

    {{< text bash >}}
    $ kubectl exec deploy/sleep -- curl -s -w "%{http_code}" -o /dev/null "http://$GATEWAY_HOST/productpage"
    401
    {{< /text >}}

1. Test `/productpage` with credentials

    {{< text bash >}}
    $ kubectl exec deploy/sleep -- curl -s -o /dev/null -H "Authorization: Basic YWRtaW4zOmFkbWluMw==" -w "%{http_code}" "http://$GATEWAY_HOST/productpage"
    200
    {{< /text >}}

### Deploy a waypoint proxy

{{< text bash >}}
$ istioctl x waypoint apply --enroll-namespace --wait
{{< /text >}}

### Verify traffic works without WasmPlugin at waypoint
 
{{< text bash >}}
$ kubectl exec deploy/sleep -- curl -s -w "%{http_code}" -o /dev/null http://productpage:9080/productpage
200
{{< /text >}}

### Apply WasmPlugin at waypoint proxy

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: extensions.istio.io/v1alpha1
kind: WasmPlugin
metadata:
  name: basic-auth-at-waypoint
spec:
  targetRef:
    group: gateway.networking.k8s.io
    kind: Gateway
    name: waypoint
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

### Cleanup

{{< text bash >}}
$ kubectl delete wasmplugin basic-auth-at-gateway basic-auth-at-waypoint
{{< /text >}}

Follow [ambient uninstall guide](docs/ambient/getting-started/#uninstall) for cleanup of ambient mesh and sample test applications.