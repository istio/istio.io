---
title: Extensibility
description: Describes Istio's proxy extension mechanisms including WebAssembly and Lua filters.
weight: 50
keywords: [wasm,webassembly,emscripten,extension,plugin,filter,lua,TrafficExtension]
aliases:
  - /docs/concepts/wasm/
owner: istio/wg-policies-and-telemetry-maintainers
test: n/a
---

Istio provides two mechanisms for extending the Istio proxy: WebAssembly (Wasm) and Lua.
Both are configured using the [`TrafficExtension`](/docs/reference/config/proxy_extensions/v1alpha1/traffic_extension/) API,
which provides a unified way to attach extensions to workloads with consistent targeting and phase/priority ordering.

## Choosing a filter type

| | WebAssembly | Lua |
|---|---|---|
| **Languages** | C++, Rust, Go, AssemblyScript, and more | Lua only |
| **Distribution** | Pulled from OCI registries, HTTP URLs, or local files | Inlined directly in the resource |
| **Memory** | Higher — each plugin runs in its own sandbox | ~10x lower than WebAssembly |
| **Isolation** | Full VM sandbox — a crash is contained to the plugin | Runs in-process; a crash can kill the worker thread |
| **Failure policy** | Configurable — fail-closed by default | Fail-open only — no configuration option |
| **SDLC** | Full ecosystem: unit tests, CI, versioned releases | Limited — script lives in the resource itself |
| **Best for** | Complex logic, reusable plugins, production extensions | Simple one-off transforms, temporary workarounds |

In general, prefer WebAssembly for production extensions that need testing, versioning, and reuse.
Prefer Lua for lightweight, localized changes where the simplicity of inline code outweighs the lack of tooling.

## WebAssembly Plugins

WebAssembly is a sandboxing technology for more complex extensions. The Proxy-Wasm sandbox API replaces Mixer as the primary extension mechanism in Istio.

WebAssembly sandbox goals:

- **Efficiency** - An extension adds low latency, CPU, and memory overhead.
- **Function** - An extension can enforce policy, collect telemetry, and perform payload mutations.
- **Isolation** - A programming error or crash in one plugin doesn't affect other plugins.
- **Configuration** - The plugins are configured using an API that is consistent with other Istio APIs. An extension can be configured dynamically.
- **Operator** - An extension can be canaried and deployed as log-only, fail-open or fail-close.
- **Extension developer** - The plugin can be written in several programming languages.

This [video talk](https://youtu.be/XdWmm_mtVXI) is an introduction about architecture of WebAssembly integration.

### High-level architecture

Istio extensions (Proxy-Wasm plugins) have several components:

- **Filter Service Provider Interface (SPI)** for building Proxy-Wasm plugins for filters.
- **Sandbox** V8 Wasm Runtime embedded in Envoy.
- **Host APIs** for headers, trailers and metadata.
- **Call out APIs** for gRPC and HTTP calls.
- **Stats and Logging APIs** for metrics and monitoring.

{{< image width="80%" link="./extending.svg" caption="Extending Istio/Envoy" >}}

### Example

An example C++ Proxy-Wasm plugin for a filter can be found
[here](https://github.com/istio-ecosystem/wasm-extensions/tree/master/example).
You can follow [this guide](https://github.com/istio-ecosystem/wasm-extensions/blob/master/doc/write-a-wasm-extension-with-cpp.md) to implement a Wasm extension with C++.

### Ecosystem

- [Istio Ecosystem Wasm Extensions](https://github.com/istio-ecosystem/wasm-extensions)
- [Proxy-Wasm ABI specification](https://github.com/proxy-wasm/spec)
- [Proxy-Wasm C++ SDK](https://github.com/proxy-wasm/proxy-wasm-cpp-sdk)
- [Proxy-Wasm Go SDK](https://github.com/proxy-wasm/proxy-wasm-go-sdk)
- [Proxy-Wasm Rust SDK](https://github.com/proxy-wasm/proxy-wasm-rust-sdk)
- [Proxy-Wasm AssemblyScript SDK](https://github.com/solo-io/proxy-runtime)
- [WebAssembly Hub](https://webassemblyhub.io/)
- [WebAssembly Extensions For Network Proxies (video)](https://www.youtube.com/watch?v=OIUPf8m7CGA)

## Lua Scripts

Lua filters provide a lightweight, inline scripting approach for simple request and response transformations.
Lua code is inlined directly in the `TrafficExtension` resource and executed within the Envoy proxy, no
module distribution is required. Lua filters are best suited for straightforward header manipulation,
logging, or conditional logic. For more complex processing, WebAssembly filters are recommended.

The memory footprint of Lua is significantly smaller than WebAssembly. [Benchmarks](https://github.com/liamawhite/lua-vs-wasm-envoy)
show Lua consuming roughly 20–26 MiB regardless of concurrency, while WebAssembly ranges from ~110 MiB
at low concurrency to ~290 MiB at high concurrency:

| Concurrency | Lua (MiB) | Wasm (MiB) |
|---|---|---|
| 1 | 19.79 | 117.7 |
| 2 | 23.07 | 132.5 |
| 4 | 22.63 | 152.0 |
| 8 | 23.97 | 190.9 |
| 16 | 25.66 | 291.8 |
