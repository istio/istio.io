---
title: 可扩展性
description: 描述了 Istio 的代理扩展机制，包括 WebAssembly 和 Lua 过滤器。
weight: 50
keywords: [wasm,webassembly,emscripten,extension,plugin,filter,lua,TrafficExtension]
aliases:
  - /zh/docs/concepts/wasm/
owner: istio/wg-policies-and-telemetry-maintainers
test: n/a
---

Istio 提供了两种用于扩展 Istio 代理的机制：WebAssembly (Wasm) 和 Lua。
两者均通过 [`TrafficExtension`](/zh/docs/reference/config/proxy_extensions/v1alpha1/traffic_extension/) API 进行配置；
该 API 提供了一种统一的方式，允许以一致的定位规则以及阶段/优先级顺序，
将扩展附加到工作负载上。

## 选择滤镜类型 {#choosing-a-filter-type}

| | WebAssembly | Lua |
|---|---|---|
| **语言** | C++、Rust、Go、AssemblyScript 及更多 | 仅限 Lua |
| **分发** | 从 OCI 注册表、HTTP URL 或本地文件拉取 | 直接内联于资源中 |
| **内存** | 更高 —— 每个插件均运行于独立的沙箱中 | 比 WebAssembly 低约 10 倍 |
| **隔离** | 完整虚拟机沙箱 —— 崩溃仅限于插件内部 | 以进程内模式运行；崩溃可能导致工作线程终止。 |
| **故障策略** | 可配置 —— 默认为故障关闭 | 仅支持故障开启 — 无配置选项 |
| **软件开发生命周期** | 完整生态系统：单元测试、持续集成、版本化发布 | 受限 —— 脚本位于资源本身之中 |
| **最适合** | 复杂逻辑、可复用插件、生产级扩展 | 简单的单次转换、临时变通方案 |

通常而言，对于那些需要经过测试、版本管理及复用的生产级扩展，
应优先选用 WebAssembly；而对于轻量级、局部的变更，
若内联代码的简洁性优于对工具链的需求，则应优先选用 Lua。

## WebAssembly 插件 {#webassembly-plugins}

WebAssembly 是一种用于更复杂扩展的沙箱技术。
Proxy-Wasm 沙箱 API 取代 Mixer，成为 Istio 中的主要扩展机制。

WebAssembly 沙箱目标：

- **效率** —— 扩展引入的延迟、CPU 和内存开销极低。
- **功能** —— 扩展能够执行策略、收集遥测数据，并对负载（Payload）进行修改。
- **隔离性** —— 某个插件中的编程错误或崩溃不会影响到其他插件。
- **配置** —— 插件通过一套与 Istio 其他 API
  保持一致的 API 进行配置；扩展支持动态配置。
- **运维人员** —— 扩展支持金丝雀发布，并可配置为仅记录日志、
  故障开放（Fail-open）或故障关闭（Fail-close）模式。
- **扩展开发者** —— 插件可以使用多种编程语言进行编写。

这段[视频演讲](https://youtu.be/XdWmm_mtVXI)是对 WebAssembly 集成架构的介绍。

### 高级架构 {#high-level-architecture}

Istio 扩展（Proxy-Wasm 插件）包含多个组件：

- **过滤器服务提供接口（SPI）**：用于构建过滤器的 Proxy-Wasm 插件。
- **沙箱（Sandbox）**：嵌入在 Envoy 中的 V8 Wasm 运行时。
- **宿主 API（Host API）**：用于处理请求头、尾部数据及元数据。
- **外部调用 API（Call out API）**：用于发起 gRPC 和 HTTP 调用。
- **统计与日志 API（Stats and Logging API）**：用于指标收集与监控。

{{< image width="80%" link="./extending.svg" caption="扩展 Istio/Envoy" >}}

### 示例 {#example}

您可以在[此处](https://github.com/istio-ecosystem/wasm-extensions/tree/master/example)找到一个用于过滤器的
C++ Proxy-Wasm 插件示例。
您可以参照[这份指南](https://github.com/istio-ecosystem/wasm-extensions/blob/master/doc/write-a-wasm-extension-with-cpp.md)来使用 C++ 实现 Wasm 扩展。

### 生态系统 {#ecosystem}

- [Istio 生态系统 Wasm 扩展](https://github.com/istio-ecosystem/wasm-extensions)
- [Proxy-Wasm ABI 规范](https://github.com/proxy-wasm/spec)
- [Proxy-Wasm C++ SDK](https://github.com/proxy-wasm/proxy-wasm-cpp-sdk)
- [Proxy-Wasm Go SDK](https://github.com/proxy-wasm/proxy-wasm-go-sdk)
- [Proxy-Wasm Rust SDK](https://github.com/proxy-wasm/proxy-wasm-rust-sdk)
- [Proxy-Wasm AssemblyScript SDK](https://github.com/solo-io/proxy-runtime)
- [WebAssembly Hub](https://webassemblyhub.io/)
- [用于网络代理的 WebAssembly 扩展（视频）](https://www.youtube.com/watch?v=OIUPf8m7CGA)

## Lua 脚本 {#lua-scripts}

Lua 过滤器提供了一种轻量级的内联脚本编写方式，
用于实现简单的请求和响应转换。Lua 代码直接内联在 `TrafficExtension` 资源中，
并在 Envoy 代理内部执行，无需进行模块分发。
Lua 过滤器最适合用于简单的标头操作、日志记录或条件逻辑处理。
对于更复杂的处理任务，建议使用 WebAssembly 过滤器。

Lua 的内存占用远小于 WebAssembly。
[基准测试](https://github.com/liamawhite/lua-vs-wasm-envoy)结果显示，
无论并发度如何，Lua 的内存消耗始终维持在 20–26 MiB 左右；
而 WebAssembly 的内存消耗则随并发度的变化而波动，
从低并发时的约 110 MiB 升至高并发时的约 290 MiB：

| 并发 | Lua (MiB) | Wasm (MiB) |
|---|---|---|
| 1 | 19.79 | 117.7 |
| 2 | 23.07 | 132.5 |
| 4 | 22.63 | 152.0 |
| 8 | 23.97 | 190.9 |
| 16 | 25.66 | 291.8 |
