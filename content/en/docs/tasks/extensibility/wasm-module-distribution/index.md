---
title: Distributing WebAssembly Modules
description: Describes how to make remote WebAssembly modules available in the mesh.
weight: 10
aliases:
  - /help/ops/extensibility/distribute-remote-wasm-module
  - /docs/ops/extensibility/distribute-remote-wasm-module
  - /ops/configuration/extensibility/wasm-module-distribution
keywords: [extensibility,Wasm,WebAssembly]
owner: istio/wg-policies-and-telemetry-maintainers
test: yes
status: Alpha
---

{{< boilerplate alpha >}}

Istio provides the ability to [extend proxy functionality using WebAssembly (Wasm)](/blog/2020/wasm-announce/).
One of the key advantages of Wasm extensibility is that extensions can be loaded dynamically at runtime.
These extensions must first be distributed to the Envoy proxy.
Istio makes this possible by allowing the proxy agent to dynamically download Wasm modules.

## Setup the Test Application

Before you begin this task, please deploy the [Bookinfo](/docs/examples/bookinfo/#deploying-the-application) sample application.

## Configure Wasm Modules

In this example, you will add a HTTP Basic auth extension to your mesh. You will configure Istio to pull the [Basic auth module](https://github.com/istio-ecosystem/wasm-extensions/tree/master/extensions/basic_auth) from a remote image registry and load it. It will be configured to run on calls to `/productpage`.

To configure a WebAssembly filter with a remote Wasm module, create a `WasmPlugin` resource:

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: extensions.istio.io/v1alpha1
kind: WasmPlugin
metadata:
  name: basic-auth
  namespace: istio-system
spec:
  selector:
    matchLabels:
      istio: ingressgateway
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

An HTTP filter will be injected into ingress gateway proxies as an authentication filter.
The Istio agent will interpret the `WasmPlugin` configuration, download remote Wasm modules from the OCI image registry to a local file, and inject the HTTP filter into Envoy by referencing that file.

{{< idea >}}
If a `WasmPlugin` is created in a specific namespace besides `istio-system`, the pods in that namespace will be configured. If the resource is created in the `istio-system` namespace, all namespaces will be affected.
{{< /idea >}}

## Check the configured Wasm module

1. Test `/productpage` without credentials

    {{< text bash >}}
    $ curl -s -o /dev/null -w "%{http_code}" "http://$INGRESS_HOST:$INGRESS_PORT/productpage"
    401
    {{< /text >}}

1. Test `/productpage` with credentials

    {{< text bash >}}
    $ curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Basic YWRtaW4zOmFkbWluMw==" "http://$INGRESS_HOST:$INGRESS_PORT/productpage"
    200
    {{< /text >}}

For more example usage of the `WasmPlugin` API, please take a look at the [API reference](/docs/reference/config/proxy_extensions/wasm-plugin/).

## Clean up Wasm modules

{{< text bash >}}
$ kubectl delete wasmplugins.extensions.istio.io -n istio-system basic-auth
{{< /text >}}

## Monitor Wasm Module Distribution

There are several stats which track the distribution status of remote Wasm modules.

The following stats are collected by Istio agent:

- `istio_agent_wasm_cache_lookup_count`: number of Wasm remote fetch cache lookups.
- `istio_agent_wasm_cache_entries`: number of Wasm config conversions and results, including success, no remote load, marshal failure, remote fetch failure, and miss remote fetch hint.
- `istio_agent_wasm_config_conversion_duration_bucket`: Total time in milliseconds istio-agent spends on config conversion for Wasm modules.
- `istio_agent_wasm_remote_fetch_count`: number of Wasm remote fetches and results, including success, download failure, and checksum mismatch.

If a Wasm filter configuration is rejected, either due to download failure or other reasons, istiod will also emit `pilot_total_xds_rejects` with the type label `type.googleapis.com/envoy.config.core.v3.TypedExtensionConfig`.

## Develop a Wasm Extension

To learn more about Wasm module development, please refer to the guides provided in the [`istio-ecosystem/wasm-extensions` repository](https://github.com/istio-ecosystem/wasm-extensions),
which is maintained by the Istio community and used to develop Istio's Telemetry Wasm extension:

- [Write, test, deploy, and maintain a Wasm extension with C++](https://github.com/istio-ecosystem/wasm-extensions/blob/master/doc/write-a-wasm-extension-with-cpp.md)
- [Build Istio Wasm plugin-compatible OCI images](https://github.com/istio-ecosystem/wasm-extensions/blob/master/doc/how-to-build-oci-images.md)
- [Write unit tests for C++ Wasm extensions](https://github.com/istio-ecosystem/wasm-extensions/blob/master/doc/write-cpp-unit-test.md)
- [Write integration tests for Wasm extensions](https://github.com/istio-ecosystem/wasm-extensions/blob/master/doc/write-integration-test.md)

## Limitations

There are known limitations with this module distribution mechanism, which will be addressed in future releases:

- Only HTTP filters are supported.
