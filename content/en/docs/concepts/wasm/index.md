---
title: WebAssembly (Wasm) Plugins
description: Describes Istio's WebAssembly Plugin system.
weight: 25
keywords: [wasm,webassembly,emscripten,extension,plugin,filter]
---

WebAssembly is a sandboxing technology which can be used to extend the Istio proxy (Envoy).  Going forward Istio extensions will be written as Envoy proxy plugins using the WebAssembly (Wasm) sandbox API. Mixer will be eliminated from the Istio architecture and all Mixer adapters must be eventually rewritten as proxy plugins.  

WebAseembly sandbox Goal:

- **Efficiency** - An extension adds low latency, CPU, and memory overhead. 
- **Function** - An extension can enforce policy, collect telemetry, and perform payload mutations.
- **Isolation** - A programming error or crash in an extension does affect other extensions.
- **Configuration** - The extensions are configured using an API that is consistent with other Isio APIs. An extension can be configured dynamically.
- **Operator** - An extension can be canaried and deployed as log-only, fail-open or fail-close.
- **Extension developer** - The extensions can be written in several programming languages.

This [video talk](https://youtu.be/XdWmm_mtVXI) is an introduction about architecture of WebAssembly integration.

## High-level architecture

Istio extensions have several components:

- **Filter SPI** for building filters

- **Sandbox** V8 embedded in Envoy

- **Host APIs** for headers, trailers and metadata

- **Call out APIs** for gRPC and HTTP calls

- **Stats and Logging APIs** for metrics and monitoring

{{< image width="80%" link="./extending.svg" caption="Extending Istio/Envoy" >}}

## Example

An example C++ WASM filter could be found
[here](https://github.com/envoyproxy/envoy-wasm/tree/19b9fd9a22e27fcadf61a06bf6aac03b735418e6/examples/wasm).

To implement a WASM filter:

-   Implement a [root context class](https://github.com/envoyproxy/envoy-wasm/blob/e8bf3ab26069a387f47a483d619221a0c482cd13/examples/wasm/envoy_filter_http_wasm_example.cc#L7) which inherits [base root context class](https://github.com/envoyproxy/envoy-wasm/blob/e8bf3ab26069a387f47a483d619221a0c482cd13/api/wasm/cpp/proxy_wasm_impl.h#L288)
-   Implement a [stream context class](https://github.com/envoyproxy/envoy-wasm/blob/e8bf3ab26069a387f47a483d619221a0c482cd13/examples/wasm/envoy_filter_http_wasm_example.cc#L14) which inherits the [base context class](https://github.com/envoyproxy/envoy-wasm/blob/master/api/wasm/cpp/proxy_wasm_impl.h#L314).
-   Override [context API](#context-object-api) methods to handle corresponding initialization and stream events from host.
-   [Register](https://github.com/envoyproxy/envoy-wasm/blob/e8bf3ab26069a387f47a483d619221a0c482cd13/examples/wasm/envoy_filter_http_wasm_example.cc#L26) the root context and stream context.


## SDK

A detailed description of the C++ SDK can be found [here](https://github.com/proxy-wasm/proxy-wasm-cpp-sdk/tree/a30aaeedf30cc1545318505574c7fb3bb8d8c243/docs/wasm_filter.md).
