---
title: Istio 和 Envoy 的 WebAssembly 可扩展性：回顾一周年
description: Istio 和 Envoy 的 WebAssembly 可扩展性的最新进展。
publishdate: 2021-03-05
attribution: "Pengyuan Bian (Google)"
keywords: [wasm,extensibility,WebAssembly]
---

在一年前的今天，我们向 Istio 1.5 版本中引入了基于 WebAssembly 的可扩展性。

在过去的一年里，Istio、Envoy 和 Proxy-Wasm 社区继续共同努力，使 WebAssembly（Wasm）可扩展性更加稳定、可靠且易于采用。让我们通过 Istio 1.9 发布版对 Wasm 支持进行更新，并谈谈我们未来的计划。

## WebAssembly 支持已合并到上游 Envoy

在将 Wasm 和 WebAssembly for Proxies (Proxy-Wasm) ABI 的实验性支持添加到 Istio 对 Envoy 的分支后，我们从早期用户收集了一些很好的反馈。这些反馈与开发核心 Istio Wasm 扩展所获得的经验相结合，帮助 WebAssembly 在运行时变的更加成熟和稳定。
这些改进解决了可直接将 Wasm 支持合并到 Envoy 上游的阻碍，于是在 2020 年 10 月它成为所有官方 Envoy 版本的一部分。
这是一个重要的里程碑，因为它表明：

* 运行时已准备好进行更广泛的采用。
* 编程 ABI/API、扩展配置 API 和运行时行为正在变得稳定。
* 您可以期待未来有更大的采用和支持社区。

## `wasm-extensions` 生态系统仓库

作为 Envoy Wasm 运行时的早期用户，Istio 的可扩展性和可观测工作组在开发扩展方面获得了很多经验。我们构建了几个一流的扩展，包括 Metadata 交换、Prometheus 统计信息和属性生成。
为了更广泛地分享我们的学习成果，我们在 `istio-ecosystem` 组织中创建了一个 `wasm-extensions` 存储库。该存储库有两个目的：

* 它提供了规范的示例扩展，涵盖了几个热门需求的功能（例如[基本身份验证](https://github.com/istio-ecosystem/wasm-extensions/tree/master/extensions/basic_auth)）。
* 它提供了 Wasm 扩展开发、测试和发布指南。该指南基于与 Istio 可扩展性团队使用、维护和测试的相同构建工具链和测试框架。

该指南目前涵盖了使用 C++ 进行 [WebAssembly 扩展开发](https://github.com/istio-ecosystem/wasm-extensions/blob/master/doc/write-a-wasm-extension-with-cpp.md)和单元测试，
以及使用 Go 测试框架进行[集成测试](https://github.com/istio-ecosystem/wasm-extensions/blob/master/doc/write-integration-test.md)，
通过运行带有 Istio 代理二进制文件的 Wasm 模块来模拟真实运行时。
在未来，我们还将添加几个更多的规范扩展，例如与 Open Policy Agent 的集成以及基于 JWT 令牌的请求头操作。

## 通过 Istio 代理分发 Wasm 模块

在 Istio 1.9 之前，需要使用 [Envoy 远程数据源](https://www.envoyproxy.io/docs/envoy/latest/api-v3/config/core/v3/base.proto#config-core-v3-remotedatasource) 将远程 Wasm 模块分发到代理。
[在此示例中](https://gist.github.com/bianpengyuan/8377898190e8052ffa36e88a16911910)，可以看到定义了两个 `EnvoyFilter` 资源：一个用于添加远程获取 Envoy 集群，另一个用于将 Wasm 过滤器注入 HTTP 过滤器链中。
这种方法有一个缺点：如果由于错误的配置或瞬态错误而导致远程获取失败，则 Envoy 将被错误的配置卡住。
如果将 Wasm 扩展配置为 [fail closed](https://www.envoyproxy.io/docs/envoy/latest/api-v3/extensions/wasm/v3/wasm.proto#extensions-wasm-v3-pluginconfig)，则错误的远程获取将阻止 Envoy 提供服务。
要解决这个问题，需要对 Envoy xDS 协议进行[根本性改变](https://github.com/envoyproxy/envoy/issues/9447)，使其允许异步 xDS 响应。

Istio 1.9 通过利用 istio-agent 内部的 xDS 代理和 Envoy 的[扩展配置发现服务](https://www.envoyproxy.io/docs/envoy/latest/configuration/overview/extension) (ECDS)，提供了一个可靠的开箱即用的分发机制。

istio-agent 拦截来自 istiod 的扩展配置资源更新，从中读取远程获取提示，下载 Wasm 模块，并使用已下载的 Wasm 模块路径重写 ECDS 配置。
如果下载失败，istio-agent 将拒绝 ECDS 更新并阻止错误配置到达 Envoy。有关更多详细信息，请参见[我们的 Wasm 模块分发文档](/zh/docs/tasks/extensibility/wasm-module-distribution/)。

{{< image width="75%"
    link="./architecture-istio-agent-downloading-wasm-module.svg"
    alt="远程获取 Wasm 模块流程"
    caption="远程获取 Wasm 模块流程"
    >}}

## Istio Wasm SIG 和未来工作

尽管我们在 Wasm 可扩展性方面取得了很多进展，但该项目仍有许多方面需要完成。
为了整合各方的努力并更好地应对未来的挑战，我们成立了一个
[Istio WebAssembly SIG](https://discuss.istio.io/t/introducing-wasm-sig/9930)，
旨在提供一种标准和可靠的方式，使 Istio 能够使用 Wasm 扩展。以下是我们正在处理的一些事项：

* **一流的扩展 API**：目前，Wasm 扩展需要通过 Istio 的 `EnvoyFilter` API 注入。一流的扩展 API 将使在 Istio 中使用 Wasm 更加容易，并且我们预计这将在 Istio 1.10 中引入。
* **分发模块的相互操作性**：基于 Solo.io 的 [WebAssembly OCI 图像规范](https://www.solo.io/blog/announcing-the-webassembly-wasm-oci-image-spec/)，标准的 Wasm 模块格式将使构建、拉取、发布和执行变得容易。
* **基于容器存储接口（CSI）的模块分发**：使用 istio-agent 分发模块易于采用，但可能不够高效，因为每个代理都会保留 Wasm 模块的副本。作为更有效的解决方案，使用 [Ephemeral CSI](https://kubernetes-csi.github.io/docs/ephemeral-local-volumes.html)，将提供一个 DaemonSet 来配置 Pod 的存储。类似于 CNI 插件，CSI 驱动程序将从 xDS 流中获取 Wasm 模块，并在 Pod 启动时将其挂载到 `rootfs` 内部。

如果您想加入我们，该小组将每隔一周的北京时间星期三上午 6 点（太平洋时间星期二下午 2 点）举行会议。您可以在 [Istio 工作组日历](https://github.com/istio/community/blob/master/WORKING-GROUPS.md#working-group-meetings)上找到会议。

我们期待看到您如何使用 Wasm 来扩展 Istio！
