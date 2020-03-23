---
title: 扩展性
description: 讲述 Istio 的 WebAssembly 插件系统。
weight: 25
keywords: [wasm,webassembly,emscripten,extension,plugin,filter]
---

WebAssembly 是一种沙盒技术，可以用于扩展 Istio 代理（Envoy）的能力。Proxy-Wasm 沙盒 API 取代了 Mixer 作为 Istio 主要的扩展机制。在 Istio 1.6 中将会为 Proxy-Wasm 插件提供一种统一的配置 API。

WebAssembly 沙盒的目标：

- **效率** - 这是一种低延迟，低 CPU 和内存开销的扩展机制。
- **功能** - 这是一种可以执行策略，收集遥测数据和执行有效荷载变更的扩展机制。
- **隔离** - 一个插件中程序的错误或是奔溃不会影响其它插件。
- **配置** - 插件使用与其它 Istio API 一致的 API 进行配置。可以动态的配置扩展。
- **运维** - 扩展可以以仅日志，故障打开或者故障关闭的方式进行访问和部署。
- **扩展开发者** - 可以用多种编程语言编写。

这个[演讲视频](https://youtu.be/XdWmm_mtVXI)是关于 WebAssembly 集成架构的介绍。

## 高级架构 {#high-level-architecture}

Istio 扩展（Proxy-Wasm 插件）有几个组成部分：

- **过滤器服务提供商接口** 用于为过滤器构建 Proxy-Wasm 插件。
- **沙盒** 在 Envoy 中嵌入 V8 Wasm 运行时。
- **主机 API** 用于处理请求头，尾和元数据。
- **调出 API** 针对 gRPC 和 HTTP 请求。
- **统计和记录 API** 用于度量统计和监控。

{{< image width="80%" link="./extending.svg" caption="扩展 Istio/Envoy" >}}

## 例子 {#example}

[这里](https://github.com/envoyproxy/envoy-wasm/tree/19b9fd9a22e27fcadf61a06bf6aac03b735418e6/examples/wasm)是用 C++ 为过滤器实现 Proxy-Wasm 插件的例子。

为过滤器实现一个 Proxy-Wasm 插件需要：

- 实现一个继承了 [base context 类](https://github.com/envoyproxy/envoy-wasm/blob/e8bf3ab26069a387f47a483d619221a0c482cd13/api/wasm/cpp/proxy_wasm_impl.h#L288)的 [root context 类](https://github.com/envoyproxy/envoy-wasm/blob/e8bf3ab26069a387f47a483d619221a0c482cd13/examples/wasm/envoy_filter_http_wasm_example.cc#L7)。
- 实现一个继承了 [base context 类](https://github.com/envoyproxy/envoy-wasm/blob/e8bf3ab26069a387f47a483d619221a0c482cd13/api/wasm/cpp/proxy_wasm_impl.h#L314)的 [流 context 类](https://github.com/envoyproxy/envoy-wasm/blob/e8bf3ab26069a387f47a483d619221a0c482cd13/examples/wasm/envoy_filter_http_wasm_example.cc#L14)。
- 重写 [context API](https://github.com/envoyproxy/envoy-wasm/blob/e8bf3ab26069a387f47a483d619221a0c482cd13/examples/wasm/envoy_filter_http_wasm_example.cc#L14) 的方法，以此处理来自主机的相应初始化和流事件。
- [注册](https://github.com/envoyproxy/envoy-wasm/blob/e8bf3ab26069a387f47a483d619221a0c482cd13/examples/wasm/envoy_filter_http_wasm_example.cc#L26) 这个 `root context` 和流 `stream context`。

## SDK

C++ SDK 的详细说明见[这里](https://github.com/proxy-wasm/proxy-wasm-cpp-sdk/tree/a30aaeedf30cc1545318505574c7fb3bb8d8c243/docs/wasm_filter.md)。

## 生态 {#ecosystem}

- [Proxy-Wasm ABI 说明](https://github.com/proxy-wasm/spec)
- [Proxy-Wasm C++ SDK](https://github.com/proxy-wasm/proxy-wasm-cpp-sdk)
- [Proxy-Wasm Rust SDK](https://github.com/proxy-wasm/proxy-wasm-rust-sdk)
- [Proxy-Wasm AssemblyScript SDK](https://github.com/solo-io/proxy-runtime)
- [WebAssembly Hub](https://docs.solo.io/web-assembly-hub/latest/tutorial_code/)
- [网络代理的 WebAssembly 扩展（视频）](https://www.youtube.com/watch?v=OIUPf8m7CGA)
