---
title: "Introducing the TrafficExtension API"
description: A new unified API for extending Istio proxies with WebAssembly and Lua, supporting both sidecar and ambient mode.
publishdate: 2026-05-07
attribution: "Liam White - Docusign"
keywords: [istio, wasm, lua, extensibility, ambient, traffic extension]
target_release: 1.30
---

Mesh extensibility has always been a core tenet of Istio's design. By allowing users to inject custom logic directly into the data plane, Istio enables a wide range of use cases for performing custom authentication, collecting specialized telemetry, or transforming requests and responses on-the-fly. Until now Istio's only supported extensibility API was `WasmPlugin`, which served WebAssembly-based extensions. Users who wanted to leverage Lua scripts could only do so indirectly via `EnvoyFilter`, a low-level mechanism that is powerful but easy to misconfigure.

Istio 1.30 introduces the `TrafficExtension` API — a single, unified API for configuring Wasm and Lua extensions across both sidecar and ambient mode deployments.

## What is TrafficExtension?

`TrafficExtension` is a new Istio API that replaces `WasmPlugin` as the primary proxy extensibility mechanism. It supports two extension types:

- **Lua scripts** — inline Lua scripts embedded directly in the resource, executed within Envoy with no module distribution required. Best for simple header manipulation, logging, and conditional logic.
- **WebAssembly plugins** — Proxy-Wasm sandbox modules loaded dynamically from OCI image registries. Supports multiple languages (Go, Rust, C++, AssemblyScript) and is recommended for complex processing, policy enforcement, telemetry collection, and payload mutations.

See the [TrafficExtension concepts page](/docs/concepts/extensibility/trafficextension/) for detailed guidance on choosing between Lua and Wasm for your use case.

Note: `TrafficExtension` is currently **alpha** — the API may change before stabilization. Feedback is welcome.

## Writing extensions

### Lua

Lua scripts are written inline. The following example reads an `x-number` request header, computes whether the value is even or odd, and adds an `x-parity` response header:

{{< text yaml >}}
apiVersion: extensions.istio.io/v1alpha1
kind: TrafficExtension
metadata:
  name: parity
  namespace: istio-system
spec:
  selector:
    matchLabels:
      istio: ingressgateway
  lua:
    inlineCode: |
      function envoy_on_request(request_handle)
        local number = tonumber(request_handle:headers():get("x-number"))
        if number == nil then return end
        local parity = number % 2 == 0 and "even" or "odd"
        request_handle:streamInfo():dynamicMetadata():set(
          "envoy.filters.http.lua", "parity", parity)
      end
      function envoy_on_response(response_handle)
        local meta = response_handle:streamInfo():dynamicMetadata():get(
          "envoy.filters.http.lua")
        if meta == nil then return end
        response_handle:headers():add("x-parity", meta["parity"])
      end
{{< /text >}}

### WebAssembly

Wasm modules are loaded from OCI registries. The following example applies basic authentication to the `/productpage` path using a prebuilt Wasm plugin:

{{< text yaml >}}
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
          request_methods: ["GET", "POST"]
          credentials: ["ok:test"]
{{< /text >}}

Prebuilt Wasm extensions are available in the [Istio ecosystem repository](https://github.com/istio-ecosystem/wasm-extensions). To build your own, see the [Proxy-Wasm SDKs](https://github.com/proxy-wasm).

## Targeting

`TrafficExtension` supports two targeting mechanisms suited to different deployment modes.

**`selector`** targets sidecar proxies using label selectors. A resource created in `istio-system` applies cluster-wide; a resource in any other namespace applies only to workloads in that namespace.

**`targetRefs`** targets Gateways or Services directly — required for ambient mode waypoint proxies, which do not use map to workloads using label-based selectors. The same `basic-auth` extension applied to an ambient Gateway looks like this:

{{< text yaml >}}
apiVersion: extensions.istio.io/v1alpha1
kind: TrafficExtension
metadata:
  name: basic-auth-gateway
spec:
  targetRefs:
    - kind: Gateway
      group: gateway.networking.k8s.io
      name: bookinfo-gateway
  phase: AUTHN
  wasm:
    url: oci://ghcr.io/istio-ecosystem/wasm-extensions/basic_auth:1.12.0
    pluginConfig:
      basic_auth_rules:
        - prefix: "/productpage"
          request_methods: ["GET", "POST"]
          credentials: ["ok:test"]
{{< /text >}}

## Ordering extensions

When multiple extensions target the same proxy, `phase` and `priority` control execution order.

`phase` places the extension at a known point in the filter chain:

| Phase | Position |
|-------|----------|
| `AUTHN` | Authentication phase |
| `AUTHZ` | Authorization phase |
| `STATS` | Statistics/observability phase |
| *(unset)* | Near the router (default) |

Within a phase, `priority` breaks ties — higher values run earlier in the request path.

## Migrating from WasmPlugin

`TrafficExtension` supersedes `WasmPlugin` as the recommended extensibility API. Existing `WasmPlugin` resources are fully compatible with the new API — in fact, Istio now internally transforms all `WasmPlugin` resources into `TrafficExtension` resources before distributing configuration to Envoy.

There is no forced migration in Istio 1.30. When you are ready to migrate, the [TrafficExtension API reference](/docs/reference/config/proxy_extensions/v1alpha1/traffic_extension/) documents the full spec.

## Get started

- [TrafficExtension concepts](/docs/concepts/extensibility/trafficextension/) — extension types, targeting, and ordering explained
- [Execute WebAssembly modules](/docs/tasks/extensibility/wasm-modules/) — step-by-step task for sidecar deployments
- [Execute Lua scripts](/docs/tasks/extensibility/lua-scripts/) — step-by-step task for sidecar deployments
- [Extend waypoints with WebAssembly](/docs/ambient/usage/extend-waypoint-wasm/) — ambient mode guide
- [Extend waypoints with Lua](/docs/ambient/usage/extend-waypoint-lua/) — ambient mode guide

## Community

`TrafficExtension` is alpha, and your feedback directly shapes the API before it stabilizes. If you encounter issues or have suggestions, please [open a GitHub issue](https://github.com/istio/istio/issues) or join the discussion on [Istio Slack](https://slack.istio.io/). We'd love to hear how you're using proxy extensions in your deployments.

Ready to get involved? Visit Istio's [community page](/get-involved/).
