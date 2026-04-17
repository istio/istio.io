---
title: Executing WebAssembly Modules
description: Describes how to make remote WebAssembly modules available in the mesh.
weight: 10
aliases:
  - /docs/tasks/extensibility/wasm-module-distribution/
  - /help/ops/extensibility/distribute-remote-wasm-module
  - /docs/ops/extensibility/distribute-remote-wasm-module
  - /ops/configuration/extensibility/wasm-module-distribution
keywords: [extensibility,Wasm,WebAssembly]
owner: istio/wg-policies-and-telemetry-maintainers
test: yes
status: Alpha
---

{{< boilerplate alpha >}}

Istio provides the ability to extend proxy functionality using [WebAssembly (Wasm)](/docs/concepts/extensibility/trafficextension/).
One of the key advantages of Wasm extensibility is that extensions can be loaded dynamically at runtime.
These extensions must first be distributed to the Envoy proxy.
Istio makes this possible by allowing the proxy agent to dynamically download Wasm modules.

## Before you begin

Deploy the [Bookinfo](/docs/examples/bookinfo/#deploying-the-application) sample application.

## Configure a Wasm module

In this example, you will add an HTTP Basic auth extension to your mesh. You will configure Istio
to pull the [Basic auth module](https://github.com/istio-ecosystem/wasm-extensions/tree/master/extensions/basic_auth)
from a remote image registry and load it. It will be configured to run on calls to `/productpage`.

To configure a WebAssembly filter with a remote Wasm module, create a `TrafficExtension` resource:

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: extensions.istio.io/v1alpha1
kind: TrafficExtension
metadata:
  name: basic-auth
  namespace: istio-system
spec:
  selector:
    matchLabels:
      istio: ingressgateway
  phase: AUTHN
  wasm:
    url: oci://ghcr.io/istio-ecosystem/wasm-extensions/basic_auth:1.12.0
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
The Istio agent will interpret the `TrafficExtension` configuration, download remote Wasm modules
from the OCI image registry to a local file, and inject the HTTP filter into Envoy by referencing that file.

{{< idea >}}
If a `TrafficExtension` is created in a specific namespace besides `istio-system`, the pods in that
namespace will be configured. If the resource is created in the `istio-system` namespace, all namespaces
will be affected.
{{< /idea >}}

## Verify the Wasm module

[Determine the ingress IP and port](/docs/tasks/traffic-management/ingress/ingress-control/#determining-the-ingress-ip-and-ports).

1. Test `/productpage` without credentials:

    {{< text bash >}}
    $ curl -s -o /dev/null -w "%{http_code}" "http://$INGRESS_HOST:$INGRESS_PORT/productpage"
    401
    {{< /text >}}

1. Test `/productpage` with credentials:

    {{< text bash >}}
    $ curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Basic YWRtaW4zOmFkbWluMw==" "http://$INGRESS_HOST:$INGRESS_PORT/productpage"
    200
    {{< /text >}}

## Ordering and scoping

When multiple `TrafficExtension` resources target the same workload, execution order is controlled
by `phase` and `priority`.

- **`phase`** sets the broad position in the filter chain: `AUTHN`, `AUTHZ`, or `STATS`.
  Extensions without a phase are inserted near the end of the chain, before the router.
- **`priority`** breaks ties within the same phase. Higher values run first.

The `match` field restricts a `TrafficExtension` to specific traffic by mode and port:

{{< text yaml >}}
spec:
  match:
  - mode: CLIENT
    ports:
    - number: 8080
{{< /text >}}

Valid modes are `CLIENT` (outbound), `SERVER` (inbound), and `CLIENT_AND_SERVER` (both, the default).

## Clean up

{{< text bash >}}
$ kubectl delete trafficextension -n istio-system basic-auth
{{< /text >}}

## Monitor Wasm module distribution

The following stats are collected by the Istio agent:

- `istio_agent_wasm_cache_lookup_count`: number of Wasm remote fetch cache lookups.
- `istio_agent_wasm_cache_entries`: number of Wasm config conversions and results, including success, no remote load, marshal failure, remote fetch failure, and miss remote fetch hint.
- `istio_agent_wasm_config_conversion_duration_bucket`: total time in milliseconds the Istio agent spends on config conversion for Wasm modules.
- `istio_agent_wasm_remote_fetch_count`: number of Wasm remote fetches and results, including success, download failure, and checksum mismatch.

If a Wasm filter configuration is rejected, either due to download failure or other reasons, istiod will also emit `pilot_total_xds_rejects` with the type label `type.googleapis.com/envoy.config.core.v3.TypedExtensionConfig`.

## Develop a Wasm extension

To learn more about Wasm module development, please refer to the guides provided in the
[`istio-ecosystem/wasm-extensions` repository](https://github.com/istio-ecosystem/wasm-extensions),
which is maintained by the Istio community and used to develop Istio's Telemetry Wasm extension:

- [Write, test, deploy, and maintain a Wasm extension with C++](https://github.com/istio-ecosystem/wasm-extensions/blob/master/doc/write-a-wasm-extension-with-cpp.md)
- [Build Istio Wasm plugin-compatible OCI images](https://github.com/istio-ecosystem/wasm-extensions/blob/master/doc/how-to-build-oci-images.md)
- [Write unit tests for C++ Wasm extensions](https://github.com/istio-ecosystem/wasm-extensions/blob/master/doc/write-cpp-unit-test.md)
- [Write integration tests for Wasm extensions](https://github.com/istio-ecosystem/wasm-extensions/blob/master/doc/write-integration-test.md)

For more details on the API, see the [`TrafficExtension` reference](/docs/reference/config/proxy_extensions/v1alpha1/traffic_extension/).

## Limitations

There are known limitations with this module distribution mechanism, which will be addressed in future releases:

- Only HTTP filters are supported.
