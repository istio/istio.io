---
title: 重新定义代理的扩展性：Envoy 和 Istio 引入 WebAssembly
subtitle: 一种针对代理服务扩展的新接口，可以把 Istio 的扩展从控制平面迁移到 sidecar 代理中
description: Istio 的扩展中使用 WASM 的前景。
publishdate: 2020-03-05
attribution: "Craig Box, Mandar Jog, John Plevyak, Louis Ryan, Piotr Sikora (Google), Yuval Kohavi, Scott Weiss (Solo.io)"
keywords: [wasm,extensibility,alpha,performance,operator]
---

自 2016 年使用 [Envoy](https://www.envoyproxy.io/) 以后，Istio 项目一直想提供一个平台，在此平台上可以构建丰富的扩展，以满足用户多样化的需求。有很多要向服务网格的数据平面增加功能的理由 --- 比如：支持更新的协议，与专有安全控件集成，或是通过自定义度量来增强可观察性。

在过去的一年半中，我们在 Google 的团队一直在努力用 [WebAssembly](https://webassembly.org/) 来为 Envoy 代理添加动态扩展。今天我们很高兴与大家分享这项工作，并推出[针对代理的 WebAssembly (Wasm)](https://github.com/proxy-wasm/spec) (Proxy-Wasm)：包括一个会标准化的 ABI，SDK，以及它的第一个重点实现：新的，低延迟的 [Istio 遥测系统](/zh/docs/reference/config/telemetry)。

我们还与社区紧密合作，以确保为用户提供良好的开发者体验，帮助他们快速上手。Google 团队一直与 [Solo.io](https://solo.io) 团队紧密合作，Solo 他们已经建立了 [WebAssembly Hub](https://webassemblyhub.io/) 服务，用于构建，共享，发现和部署 Wasm 扩展。有了 WebAssembly Hub，Wasm 扩展就会像容器一样易于管理，安装和运行。

这个项目现在发布了 Alpha 版本，仍然还有很多[工作要做](#next-steps)，但是我们很高兴将其交提供给开发者，以便他们可以开始尝试由此带来的巨大可能性。

## 背景 {#background}

可扩展需求一直都是 Istio 和 Envoy 项目的基本原则，但是两个项目采用了不同的实现方式。Istio 项目的做法是启用一个通用的进程外扩展模型，叫做 [Mixer](/zh/docs/reference/config/policy-and-telemetry/mixer-overview/)，以此带来轻量级的开发者体验，而 Envoy 则专注于代理内[扩展](https://www.envoyproxy.io/docs/envoy/latest/extending/extending)。

每种方法都各有利弊。Istio 模型导致明显的资源效率低下，从而影响了尾部延迟和资源利用率。该模型在根本上来说是有局限性的 - 例如，它永远不会支持实现[自定义协议处理](https://blog.envoyproxy.io/how-to-write-envoy-filters-like-a-ninja-part-1-d166e5abec09)。

Envoy 模型强化了单体构建过程，并要求使用 C++ 编写扩展，从而限制了开发者的生态。给集群发布新的扩展需要下发新的二进制文件并滚动重启，这可能很难协调，并有可能会导致停机。这也促使了开发者向 Envoy 上游提交他们的扩展，而这些扩展仅由一小部分生产环境使用，更多仅仅是为了利用其发布机制。

随着时间的流逝，Istio 的一些对性能最敏感的功能已合进了上游的 Envoy - 例如[流量检查策略](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/security/rbac_filter)和例如[遥测上报](/zh/docs/reference/config/telemetry/metrics/)。尽管如此，我们一直想把扩展汇聚在一个技术栈上，从而减少两者之间犹豫的权衡：这使 Envoy 版本与其扩展生态系统脱钩，使开发者能够使用他们选择的语言进行工作，并使 Istio 可靠地推出新功能而不必有停机风险。

## 什么是 WebAssembly {#what-is-WebAssembly}

[WebAssembly](https://webassembly.org/)（Wasm）是一种由[多种语言](https://github.com/appcypher/awesome-wasm-langs)编写的，可移植的字节码格式，它能以以接近本机的速度执行。其最初的[设计目标](https://webassembly.org/docs/high-level-goals/)与上述挑战很相符，并且在其背后得到了相当大的行业支持。Wasm 是在所有主流浏览器中可以本地运行的第四种标准语言（继 HTML，CSS 和 JavaScript 之后），于 2019 年 12 月成为 [W3C 正式建议](https://www.w3.org/TR/wasm-core-1/)。这使我们有信心对其进行战略下注。

尽管 WebAssembly 最初是作为客户端技术而诞生，但它在服务器上用也有很多优势。运行时是内存安全的，并且以沙盒方式运行以确保安全。它有一个很大的工具生态系统，用于以文本或二进制格式编译和调试 Wasm。[W3C](https://www.w3.org/) 和 [BytecodeAlliance](https://bytecodealliance.org/) 已成为其它服务器端工作的活跃中心。比如，Wasm 社区正在 W3C 中标准化 ["WebAssembly 系统接口 Interface" (WASI)](https://hacks.mozilla.org/2019/03/standardizing-wasi-a-webassembly-system-interface/)，并通过一个示例实现，它为 Wasm “程序” 提供了一个类似 OS 的抽象。

## 把 WebAssembly 引入 Envoy {#bringing-WebAssembly-to-Envoy}

[在过去的 18 个月中](https://github.com/envoyproxy/envoy/issues/4272)，我们一直与 Envoy 社区合作把 Wasm 的扩展引入 Envoy，并将其贡献到上游。我们很高兴地宣布，此特性在 [Istio 1.5](/zh/news/releases/1.5.x/announcing-1.5/) 自带的 Envoy 中以 Alpha 版本可用了，其源代码在 [`envoy-wasm`](https://github.com/envoyproxy/envoy-wasm/) 开发分支中，并且正在努力将其合并到 Envoy 主干上。该实现使用了 Google 高性能 [V8 引擎](https://v8.dev/)中内置的 WebAssembly 运行时。

除了构建底层的运行时，我们还构建了：

- 把 Wasm 嵌入代理的通用应用程序二进制接口（ABI），这意味着编译后的扩展将可以在不同版本的 Envoy 中工作，甚至其它代理也可以，当然当然，其它代理得实现 ABI。
- 用 [C++](https://github.com/proxy-wasm/proxy-wasm-cpp-sdk),
 [Rust](https://github.com/proxy-wasm/proxy-wasm-rust-sdk) 和 [AssemblyScript](https://github.com/solo-io/proxy-runtime) 可以方便进行扩展开发的 SDK，后续还有很多语言支持
- 全面的[示例和说明](https://docs.solo.io/web-assembly-hub/latest/tutorial_code/)介绍如何在 Istio 和独立的 Envoy 中部署
- 允许使用其它 Wasm 运行时的抽象，包括把本地把扩展直接编译进 Envoy 中 “null” 运行时，这对于测试和调试非常有用

使用 Wasm 扩展 Envoy 带来了几个主要好处：

- 敏捷性：可以用 Istio 控制平面在运行时下发和重载扩展。这就可以快速的进行扩展开发→ 测试→ 发布周期，而无需重启 Envoy。
- 发布库：一旦完成合并到主树中之后，Istio 和其它程序将能够使用 Envoy 的发布库，而不是自己构建。这也方便 Envoy 社区迁移某些内置扩展到这个模型，从而减少他们的工作。
- 可靠性和隔离性：扩展部署在具有资源限制的沙箱中，这意味着它们现在可以崩溃或泄漏内存，但不会让整个 Envoy 挂掉。CPU 和内存使用率也可以受到限制。
- 安全性：沙盒具有一个明确定义的 API，用于和 Envoy 通信，因此扩展只能访问和修改链接或者请求中有限数量的属性。此外，由于 Envoy 协调整个交互，因此它可以隐藏或清除扩展中的敏感信息（例如，HTTP 头中的 “Authorization”和“Cookie”，或者客户端的 IP 地址）。
- 灵活性：[可以将超过 30 种编程语言编译为 WebAssembly](https://github.com/appcypher/awesome-wasm-langs)，可以让各种技术背景的开发人员都可以用他们选择的语言来编写 Envoy 扩展，比如：C++，Go，Rust，Java，TypeScript 等。

“看到 Envoy 上支持了 WASM，我感到非常兴奋；这是 Envoy 可扩展的未来。Envoy 的 WASM 支持与社区驱动的 hub 相结合，将在服务网格和 API 网关用例中开启出令人难以置信的网络创新。我迫不及待地想看到社区构建是如何向前发展的。” – Envoy 创造者 Matt Klein。

有关实现的技术细节，请关注即将在 [Envoy 博客](https://blog.envoyproxy.io/)上发的文章。

主机环境和扩展之间的 [Proxy-Wasm](https://github.com/proxy-wasm) 接口有意设计为代理无感知的。我们已将其内置到了 Envoy 中，但它是为其它代理供应商设计的。我们希望看为 Istio 和 Envoy 编写的扩展也可以在其它基础设施中运行。很快就会有更多相关的设计和实现了。

## Istio 中的 WebAssembly 构建 {#building-on-WebAssembly-in-Istio}

为了显著提高性能，Istio 在 1.5 的发布中，把它的几个扩展内置到了 Envoy 中。在执行此工作时，我们把这些同样的扩展可以作为 Proxy-Wasm 模块进行编译和运行，测试确保其行为没有异常。考虑到我们认为 Wasm 支持还是 Alpha 版本，我们还没有完全准备好将这个设置设为默认设置；然而，在我们的通用实现和主机环境还是给了我们不少信心，至少 ABI 和 SDK 已经开发完成了。

我们还是要小心地确保 Istio 控制平面及其 [Envoy 配置 API](/zh/docs/reference/config/networking/envoy-filter/) 已经可以支持 Wasm。我们有一些示例来展示几种常见的定制，例如定制头解码或程序中路由，这是用户的常见要求。当将这个支持发展到 Beta 版本时，将会看到 Istio 中使用 Wasm 最佳实践的文档。

最后，我们正在与许多编写了 [Mixer 适配器](/zh/docs/reference/config/policy-and-telemetry/adapters/)的供应商合作，帮助他们迁移到 Wasm — 如果这是前行的最佳方式。Mixer 将在未来的版本中转为社区项目，它将仍可用于老系统。

## 开发者体验 {#developer-experience}

没有出色的开发者体验，再强大的工具也毫无用处。Solo.io [最近宣布](https://www.solo.io/blog/an-extended-and-improved-webassembly-hub-to-helps-bring-the-power-of-webassembly-to-envoy-and-istio/)发布 [WebAssembly Hub](https://webassemblyhub.io/)，这是一套为 Envoy 和 Istio 做的，用于构建，部署，共享和发现 Envoy Proxy Wasm 扩展的工具和仓库。

WebAssembly Hub 把为开发和部署 Wasm 扩展所需的许多步骤都完全自动化了。使用 WebAssembly Hub 工具，用户可以轻松地把任何受支持语言开发的代码编译为 Wasm 扩展。可以将这些扩展上传到 Hub 仓库，并且用单个命令就将其在 Istio 中部署和删除。

在后台，Hub 处理了很多细节问题，例如：引入正确的工具链、ABI 版本验证、权限控制等等。该工作流程还通过自动化扩展部署，消除了跨 Istio 服务代理的配置更改带来的麻烦。此工具帮助用户和操作员避免由于配置错误或版本不匹配而导致的意外行为。

WebAssembly Hub 工具提供了功能强大的 CLI 和优雅且易于使用的图形用户界面。WebAssembly Hub 的一个重要目标是简化围绕构建 Wasm 模块的体验，并为开发者提供共享和发现有用扩展的协作场所。

请查看[入门指南](https://docs.solo.io/web-assembly-hub/latest/tutorial_code/)，以创建您的第一个 Proxy-Wasm 扩展。

## 下一步 {#next-steps}

除了努力发布 Beta 版，我们还致力于确保围绕 Proxy-Wasm 有一个持久的社区。ABI 需要最终确定，而将其转变为标准的工作将会在适当的标准机构内获得更广泛的反馈后完成。完成向 Envoy 主干提供上游支持的工作仍在进行中。我们还在为工具和 WebAssembly Hub 寻找合适的社区。

## 了解更多 {#learn-more}

- WebAssembly SF talk (视频) : [网络代理扩展](https://www.youtube.com/watch?v=OIUPf8m7CGA), by John Plevyak
- [Solo 博客](https://www.solo.io/blog/an-extended-and-improved-webassembly-hub-to-helps-bring-the-power-of-webassembly-to-envoy-and-istio/)
- [Proxy-Wasm ABI 说明](https://github.com/proxy-wasm/spec)
- [Proxy-Wasm C++ SDK](https://github.com/proxy-wasm/proxy-wasm-cpp-sdk/blob/master/docs/wasm_filter.md) 和其[开发者文档](https://github.com/proxy-wasm/proxy-wasm-cpp-sdk/blob/master/docs/wasm_filter.md)
- [Proxy-Wasm Rust SDK](https://github.com/proxy-wasm/proxy-wasm-rust-sdk)
- [Proxy-Wasm AssemblyScript SDK](https://github.com/solo-io/proxy-runtime)
- [指南](https://docs.solo.io/web-assembly-hub/latest/tutorial_code/)
- [Solo.io Youtube 频道](https://www.youtube.com/channel/UCuketWAG3WqYjjxtQ9Q8ApQ)上的视频
