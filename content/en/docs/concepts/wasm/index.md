---
title: Extensibility
description: Describes Istio's WebAssembly Plugin system.
weight: 50
keywords: [wasm,webassembly,emscripten,extension,plugin,filter]
---

WebAssembly is a sandboxing technology which can be used to extend the Istio proxy (Envoy).  The Proxy-Wasm sandbox API replaces Mixer as the primary extension mechanism in Istio. Istio 1.6 will provide a uniform configuration API for Proxy-Wasm plugins.

WebAssembly sandbox goals:

- **Efficiency** - An extension adds low latency, CPU, and memory overhead.
- **Function** - An extension can enforce policy, collect telemetry, and perform payload mutations.
- **Isolation** - A programming error or crash in one plugin does affect other plugins.
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
[here](https://github.com/envoyproxy/envoy-wasm/tree/19b9fd9a22e27fcadf61a06bf6aac03b735418e6/examples/wasm).

To implement a Proxy-Wasm plugin for a filter:

- Implement a [root context class](https://github.com/envoyproxy/envoy-wasm/blob/e8bf3ab26069a387f47a483d619221a0c482cd13/examples/wasm/envoy_filter_http_wasm_example.cc#L7) which inherits [base root context class](https://github.com/envoyproxy/envoy-wasm/blob/e8bf3ab26069a387f47a483d619221a0c482cd13/api/wasm/cpp/proxy_wasm_impl.h#L288)
- Implement a [stream context class](https://github.com/envoyproxy/envoy-wasm/blob/e8bf3ab26069a387f47a483d619221a0c482cd13/examples/wasm/envoy_filter_http_wasm_example.cc#L14) which inherits the [base context class](https://github.com/envoyproxy/envoy-wasm/blob/e8bf3ab26069a387f47a483d619221a0c482cd13/api/wasm/cpp/proxy_wasm_impl.h#L314).
- Override [context API](https://github.com/envoyproxy/envoy-wasm/blob/e8bf3ab26069a387f47a483d619221a0c482cd13/examples/wasm/envoy_filter_http_wasm_example.cc#L14) methods to handle corresponding initialization and stream events from host.
- [Register](https://github.com/envoyproxy/envoy-wasm/blob/e8bf3ab26069a387f47a483d619221a0c482cd13/examples/wasm/envoy_filter_http_wasm_example.cc#L26) the root context and stream context.

## SDK

A detailed description of the C++ SDK can be found [here](https://github.com/proxy-wasm/proxy-wasm-cpp-sdk/tree/a30aaeedf30cc1545318505574c7fb3bb8d8c243/docs/wasm_filter.md).

## Ecosystem

- [Proxy-Wasm ABI specification](https://github.com/proxy-wasm/spec)
- [Proxy-Wasm C++ SDK](https://github.com/proxy-wasm/proxy-wasm-cpp-sdk)
- [Proxy-Wasm Rust SDK](https://github.com/proxy-wasm/proxy-wasm-rust-sdk)
- [Proxy-Wasm AssemblyScript SDK](https://github.com/solo-io/proxy-runtime)
- [WebAssembly Hub](https://docs.solo.io/web-assembly-hub/latest/tutorial_code/)
- [WebAssembly Extensions For Network Proxies (video)](https://www.youtube.com/watch?v=OIUPf8m7CGA)
