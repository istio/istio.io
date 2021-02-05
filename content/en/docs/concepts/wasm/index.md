---
title: Extensibility
description: Describes Istio's WebAssembly Plugin system.
weight: 50
keywords: [wasm,webassembly,emscripten,extension,plugin,filter]
owner: istio/wg-policies-and-telemetry-maintainers
test: n/a
---

WebAssembly is a sandboxing technology which can be used to extend the Istio proxy (Envoy).  The Proxy-Wasm sandbox API replaces Mixer as the primary extension mechanism in Istio.

WebAssembly sandbox goals:

- **Efficiency** - An extension adds low latency, CPU, and memory overhead.
- **Function** - An extension can enforce policy, collect telemetry, and perform payload mutations.
- **Isolation** - A programming error or crash in one plugin doesn't affect other plugins.
- **Configuration** - The plugins are configured using an API that is consistent with other Istio APIs. An extension can be configured dynamically.
- **Operator** - An extension can be canaried and deployed as log-only, fail-open or fail-close.
- **Extension developer** - The plugin can be written in several programming languages.

This [video talk](https://youtu.be/XdWmm_mtVXI) is an introduction about architecture of WebAssembly integration.

## High-level architecture

Istio extensions (Proxy-Wasm plugins) have several components:

- **Filter Service Provider Interface (SPI)** for building Proxy-Wasm plugins for filters.
- **Sandbox** V8 Wasm Runtime embedded in Envoy.
- **Host APIs** for headers, trailers and metadata.
- **Call out APIs** for gRPC and HTTP calls.
- **Stats and Logging APIs** for metrics and monitoring.

{{< image width="80%" link="./extending.svg" caption="Extending Istio/Envoy" >}}

## Example

An example C++ Proxy-Wasm plugin for a filter can be found
[here](https://github.com/envoyproxy/envoy/tree/67609bc22f68cd3e05f5c01264a33932377955c7/examples/wasm-cc).

To implement a Proxy-Wasm plugin for a filter:

- Implement a [root context class](https://github.com/envoyproxy/envoy/blob/67609bc22f68cd3e05f5c01264a33932377955c7/examples/wasm-cc/envoy_filter_http_wasm_example.cc#L8) which inherits [base root context class](https://github.com/proxy-wasm/proxy-wasm-cpp-sdk/blob/1b5f69ce1535b0c21f88c4af4ebf0ec51d255abe/proxy_wasm_api.h#L310)
- Implement a [stream context class](https://github.com/envoyproxy/envoy/blob/67609bc22f68cd3e05f5c01264a33932377955c7/examples/wasm-cc/envoy_filter_http_wasm_example.cc#L17) which inherits the [base context class](https://github.com/proxy-wasm/proxy-wasm-cpp-sdk/blob/1b5f69ce1535b0c21f88c4af4ebf0ec51d255abe/proxy_wasm_api.h#L439).
- Override [context API](https://github.com/envoyproxy/envoy/blob/67609bc22f68cd3e05f5c01264a33932377955c7/examples/wasm-cc/envoy_filter_http_wasm_example.cc#L49) methods to handle corresponding initialization and stream events from host.
- [Register](https://github.com/envoyproxy/envoy/blob/67609bc22f68cd3e05f5c01264a33932377955c7/examples/wasm-cc/envoy_filter_http_wasm_example.cc#L30) the root context and stream context.

## SDK

A detailed description of the C++ SDK can be found [here](https://github.com/proxy-wasm/proxy-wasm-cpp-sdk/tree/a30aaeedf30cc1545318505574c7fb3bb8d8c243/docs/wasm_filter.md).

## Ecosystem

- [Proxy-Wasm ABI specification](https://github.com/proxy-wasm/spec)
- [Proxy-Wasm C++ SDK](https://github.com/proxy-wasm/proxy-wasm-cpp-sdk)
- [Proxy-Wasm Rust SDK](https://github.com/proxy-wasm/proxy-wasm-rust-sdk)
- [Proxy-Wasm AssemblyScript SDK](https://github.com/solo-io/proxy-runtime)
- [WebAssembly Hub](https://docs.solo.io/web-assembly-hub/latest/tutorial_code/)
- [WebAssembly Extensions For Network Proxies (video)](https://www.youtube.com/watch?v=OIUPf8m7CGA)
