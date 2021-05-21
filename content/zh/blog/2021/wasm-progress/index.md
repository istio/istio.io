---
title: 一年之后 Istio 和 Envoy 的 WebAssembly 的可扩展性
description: 最新Envoy 和 Istio 上基于 WebAssembly 可扩展性工作。
publishdate: 2021-03-05
attribution: "Pengyuan Bian (Google)"
keywords: [wasm,extensibility,WebAssembly]
---

一年以前的今天，1.5 发布了，我们在 Istio 中引入了 [基于WebAssembly的可扩展性](/blog/2020/wasm-announce/)。
在过去的这一年中，Istio，Envoy 和 Proxy-Wasm 社区共同努力让 WebAssembly (Wasm)的可扩展性逐步稳定、可靠和易于使用。
我们可以通过 Istio 1.9 版本来了解对 Wasm 支持的更新，还有我们未来的计划。

## WebAssembly 支持合并进了上游的 Envoy 

在 Istio 的 Envoy 分支中添加了对 Wasm 的实验性支持和 Proxies(Proxy-Wasm) 的 WebAssembly ABI 后，
从社区早期使用者这里我们收集一些很好的反馈。与开发核心 Istio Wasm 扩展获得的经验相结合，这帮助我们让运行时不断成熟和稳定。

这些改进帮助 Wasm 支持在 2020 年 10 月直接合并进了 Envoy 上游，让 Wasm 支持变成了 Envoy 的官方发布内容。
这是一个重要的里程碑，因为它标示着：

* 运行时已经可以被广泛使用。
* 编程 ABI/API，扩展配置 API 和运行时已经是稳定了。
* 你可以预期发展出来一个使用支持该技术的大社区。

## `wasm-extensions` 的生态系统库

作为 Envoy Wasm 运行时的早期采集者，Istio 扩展和遥测工作组在开发扩展方面获得了很多经验。我们构建了几个一流的扩展，包括 [原数据交换](/docs/reference/config/proxy_extensions/metadata_exchange/)，[Prometheus 统计](/docs/reference/config/proxy_extensions/stats/)和 [属性生成器](/docs/reference/config/proxy_extensions/attributegen/)。
为了更广泛地分享我们的知识，我们在 `istio-ecosystem` git 组织下面创建了一个 [`wasm-extensions` 仓库](https://github.com/istio-ecosystem/wasm-extensions)。这个仓库有 2 个目的：

* 它提供了典型的扩展示例，包括几个高要求的功能（比如 [基本身份验证](https://github.com/istio-ecosystem/wasm-extensions/tree/master/extensions/basic_auth)）。
* 它提供了一个 Wasm 扩展开发，测试和发布的指南。这个指南使用的工具链和测试框架是由 Istio 可扩展性团队使用并且维护的。

该指南目前包含了 [WebAssembly 扩展开发](https://github.com/istio-ecosystem/wasm-extensions/blob/master/doc/write-a-wasm-extension-with-cpp.md)和 C++ [单元测试](https://github.com/istio-ecosystem/wasm-extensions/blob/master/doc/write-cpp-unit-test.md) ，还有一个 Go 测试框架的[集成测试](https://github.com/istio-ecosystem/wasm-extensions/blob/master/doc/write-integration-test.md)，这个测试框架通过运行带有 Wasm 模块的 Istio 代理二进制程序来模拟一个真实的运行时。
未来，我们将会添加几个典型的扩展，例如与 Open Policy Agent 的集成，以及基于 JWT 令牌的头控制。

## 通过 Istio 代理分发 Wasm 模块

在 Istio 1.9 之前，[Envoy 远程数据源](https://www.envoyproxy.io/docs/envoy/latest/api-v3/config/core/v3/base.proto#config-core-v3-remotedatasource) 需要将远程 Wasm 模块分发到代理。
[在这个示例中](https://gist.github.com/bianpengyuan/8377898190e8052ffa36e88a16911910)，可以看到定义了 2 个 `EnvoyFilter` 资源：一个是添加远程获取的 Envoy 集群，另外一个把一个 Wasm 过滤器注入到 HTTP 过滤器链中。
[In this example](https://gist.github.com/bianpengyuan/8377898190e8052ffa36e88a16911910),
这种方法有一个缺陷：如果远程获取失败了，不论是因为错的配置或者传输错误，Envoy 将会被这个错的配置卡住。
如果 Wasm 扩展被配置成了[失败关闭](https://www.envoyproxy.io/docs/envoy/latest/api-v3/extensions/wasm/v3/wasm.proto#extensions-wasm-v3-pluginconfig)，一个错的远程获取将会让 Envoy 停止服务。
为处理这种问题，Envoy xDS 协议需要[一个根本上的解决方案](https://github.com/envoyproxy/envoy/issues/9447) 来解决异步的 xDS 响应。

Istio 1.9 通过 istio-agent 内部的 xDS 代理和 Envoy 的[扩展配置发现服务](https://www.envoyproxy.io/docs/envoy/latest/configuration/overview/extension) (ECDS)提供了一个可靠的开箱即用的分发机制，

istio-agent 会拦截从 istiod 来的扩展配置资源更新请求，从中解析出远程获取信息，下载 Wasm 模块，使用下载的 Wasm 模块的路径来重新 ECDS 配置。
如果下载失败，istio-agent 会拒绝 ECDS 更新，并且会阻止让错的配置下发到 Envoy。更多详情，请参阅[我们的 Wasm 模块分发文档](/docs/ops/configuration/extensibility/wasm-module-distribution/)。

{{< image width="75%"
    link="./architecture-istio-agent-downloading-wasm-module.svg"
    alt="远程 Wasm 模块获取流程"
    caption="远程 Wasm 模块获取流程"
    >}}

## Istio Wasm SIG 和未来的工作

虽然我们在 Wasm 可扩展性上取得了很多进展，但是这个工程中仍然有许多的工作要去做。为了联合各方的努力，更好地应对未来的挑战，我们组建了 [Istio WebAssembly SIG](https://discuss.istio.io/t/introducing-wasm-sig/9930)，目的是为 Istio 使用 Wasm 扩展提供一个标准可靠的方式。下面是我们正在做的一些事情：

* **优秀的扩展 API**：当前 Wasm 扩展需要通过 Istio 的 `EnvoyFilter` API 注入。优秀的扩展 API 将会让 Istio 使用 Wasm 更容易，并且我们希望这些 API 可以引入到 Istio 1.10 中。
* **分布构件的互操作性**：Solo.io 的 [WebAssembly OCI 镜像规范工作](https://www.solo.io/blog/announcing-the-webassembly-wasm-oci-image-spec/)定义了一个标准的 Wasm 构件格式，在它之上构建，拉去，发布和执行 Wasm 将会更容易。
* **基于容器存储接口（CSI）的构件分发**：使用 istio-agent 来分发 Wasm 模块更容易接受，但可能不是很高效，因为每个代理会保存一个 Wasm 模块副本。可以使用 [Ephemeral CSI](https://kubernetes-csi.github.io/docs/ephemeral-local-volumes.html) 作为一个更高效的解决方案，以 DaemonSet 的方式为 pod 提供配置存储。和 CNI 插件的工作方式类似，CSI 驱动器会从 xDS 流获取外带的 Wasm 模块，并且在 pod 启动的时候把它们挂在到 `rootfs`。

如果你想加入我们，我们这个小组在每周二下午 2 点开会讨论。可以在 [Istio 工作组日历](https://github.com/istio/community/blob/master/WORKING-GROUPS.md#working-group-meetings)上查看会议信息。

我们很期待看到你如何用 Wasm 来扩展 Istio!