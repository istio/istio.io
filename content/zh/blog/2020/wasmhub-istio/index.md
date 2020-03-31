---
title: 通过扩展和改进 WebAssemblyHub，以将 WebAssembly 的力量带给 Envoy 和 Istio
subtitle: 构建、发布、共享和部署 WebAssembly Envoy 扩展的平台
description: Solo.io 为 Istio 提供了 Wasm 的社区合作伙伴工具。
publishdate: 2020-03-25
attribution: "Idit Levine (Solo.io)"
keywords: [wasm,extensibility,alpha,performance,operator]
---

[*本文最初发表于 Solo.io 的博客*](https://www.solo.io/blog/an-extended-and-improved-webassembly-hub-to-helps-bring-the-power-of-webassembly-to-envoy-and-istio/)

随着组织采用诸如 Istio 之类的基于 Envoy 的基础架构来帮助解决微服务通信方面的问题，他们不可避免地发现自己需要自定义该基础架构的某些部分以适应其组织的规约。[WebAssembly（Wasm）](https://webassembly.org/)已经成为一种安全、可靠且动态的平台扩展环境。

在最近的 [Istio 1.5 发布公告](/zh/blog/2020/wasm-announce/)中，Istio 项目为把 WebAssembly 引入广受欢迎的 Envoy 代理奠定了基础。[Solo.io](https://solo.io) 与 Google 和 Istio 社区合作，提升为 Envoy 和 Istio 创建、共享和部署 WebAssembly 扩展的整体体验。就在不久之前，Google 和其他公司为容器奠定了基础，而 Docker 则建立了出色的用户体验，最终成为了消费级产品。同样，通过在 Istio 上构建 WebAssembly 的最佳用户体验，使得 Wasm 最终也可能成为消费级产品。

早在 2019 年 12 月，随着 WebAssembly Hub 的发布，Solo.io 开始努力为 WebAssembly 提供出色的开发人员体验。WebAssembly Hub 允许开发人员非常快速地创建基于 C++ 的新 WebAssembly 项目（我们正在扩展语言选项，请参见下文），在 Docker 中使用 Bazel 进行构建，然后将其推送到兼容 OCI 规范的镜像仓库中。operator 会从这个仓库中拉取模块，然后配置 Envoy 代理以便于能从本地磁盘缓存中加载此模块。[Gloo](https://docs.solo.io/gloo/latest/) (一个基于 Envoy 构建的 API 网关）提供此特性的 Beta 支持，您可以声明式的动态地加载模块，此外 Solo.io 团队也希望将同样轻松、安全的体验带给其他基于 Envoy 的框架 - 例如 Istio。

这个领域中的创新引起了人们的极大兴趣，Solo.io 团队一直在努力提高 WebAssembly Hub 的功能及其支持的工作流。 Solo.io 激动地宣布与 Istio 1.5 的集成，并对 WebAssembly Hub 发布了新的改进，这些改进增强了在生产上使用 Envoy 的 WebAssembly 特性的可行性，改善了开发人员的体验，并简化了在 Istio 中使用 Envoy 的 Wasm 功能的流程。

## 逐步走向生产{#evolving-toward-production}

Envoy 社区正在努力将 Wasm 支持引入上游（现在它位于一个工作中的开发分支），Istio 宣布为 Wasm 特性提供 Alpha 支持。在 [Gloo 1.0 中，我们还发布了](https://www.solo.io/blog/announcing-gloo-1-0-a-production-ready-envoy-based-api-gateway/) Wasm 的非生产级别支持。什么是Gloo？Gloo 是一种现代的 API 网关和 Ingress Controller（基于 Envoy 代理构建），支持路由和保护进入流量到遗留的单体应用、微服务/Kubernetes 和 serverless functions。开发和运维团队能够调整和控制从外部最终用户或客户端到后端应用程序服务的流量模式。Gloo 是 Kubernetes 和 Istio 原生的 ingress gateway。

尽管每个项目都有待成熟，但是作为社区，我们可以做些事情以改进生产级别的支持。

第一个领域是标准化 Envoy 的 WebAssembly 扩展的格式。Solo.io、Google 和 Istio 社区已定义了一个开放规范，用于将 WebAssembly 模块打包和分发为 OCI 镜像。该规范为分发包括 Envoy 扩展在内的任何类型的 Wasm 模块提供了强大的模型。

这项工作是对社区开放的 - [加入工作](https://github.com/solo-io/wasm-image-spec)

下一个领域是改善将 Wasm 扩展部署到基于 Envoy 框架运行的生产环境的体验。在 Kubernetes 生态系统中，使用基于 CRD 的声明式配置来管理集群配置被认为是生产中的最佳实践。新的 [WebAssembly Hub Operator](https://docs.solo.io/web-assembly-hub/latest/tutorial_code/wasme_operator/) 添加了一个声明式 CRD，该 CRD 可自动将 Wasm 过滤器部署和配置到运行于 Kubernetes 集群内部的 Envoy 代理中。该 operator 使 GitOps 工作流和集群自动化操作能够管理 Wasm 过滤器，而无需人工干预或指令性工作流。我们将在即将发布的博客文章中提供有关此 Operator 的更多信息。

最后，人们需要某种基于角色的访问控制、组织管理和基础设施，以便于 Wasm 扩展的开发人员与部署它们的团队之间进行交互，来共享、发现和使用这些扩展。WebAssembly Hub 添加了团队管理功能，例如权限、组织、用户管理、共享等。

## 改善开发人员体验{#improving-the-developer-experience}

由于开发人员希望面向更多的语言和运行时，因此开发体验必须保持尽可能简单和高效。工具应可以自动处理多语言支持和运行时ABI（Application Binary Interface，应用程序二进制接口）目标。

Wasm 的好处之一是能够用多种语言编写模块。Solo.io 与 Google 之间通力合作，为那些使用 C++ 、Rust 和 AssemblyScript 编写的 Envoy 过滤器提供了开箱即用的支持。我们将继续增加对更多语言的支持。

Wasm 扩展使用 Envoy 代理内的 Application Binary Interface（ABI）。WebAssembly Hub 在 Envoy，Istio 和 Gloo 之间提供了强大的 ABI 版本保障，可以防止不可预测的行为和错误。您只需关注编写扩展代码。

最后，像 Docker 一样，WebAssembly Hub 使用 OCI 镜像来存储和分发 Wasm 扩展。这使得推送、拉取和运行扩展就像 Docker 容器一样容易。Wasm 扩展的镜像经版本控制和加密保护，从而可以像在生产中一样安全地在本地运行扩展。这样，当您构建和推送镜像，或者他们拉取并部署镜像时，双方可以建立互信。

## 在 Istio 中使用 WebAssembly Hub {#webassembly-hub-with-Istio}

对于安装于 Kubernetes 环境中的 Istio，现在 WebAssembly Hub 可以使得 Wasm 扩展部署到 Istio （以及其他基于 Envoy 的框架，例如 [Gloo API 网关](https://docs.solo.io/gloo/latest/)）的过程完全自动化。通过此部署功能，WebAssembly Hub 使 operator 或最终用户无需在 Istio 服务网格中手动配置 Envoy 代理，即可使用其 WebAssembly 模块。

观看以下视频，了解 WebAssembly 和 Istio 入门的简便性：

* [Part 1](https://www.youtube.com/watch?v=-XPTGXEpUp8)
* [Part 2](https://youtu.be/vuJKRnjh1b8)

## 开始使用{#get-started}

我们希望 WebAssembly Hub 成为社区共享、发现和分发 Wasm 扩展的汇聚平台。通过提供出色的用户体验，我们希望使 Wasm 的开发、安装和运行变得更简易和更有价值。加入我们的 [WebAssembly Hub](https://webassemblyhub.io)，共享您的扩展和[意见](https://slack.solo.io)，然后加入[即将举行的网络研讨会](https://solo.zoom.us/webinar/register/WN_i8MiDTIpRxqX-BjnXbj9Xw)。
