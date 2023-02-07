---
title: 扩展和改进 WebAssemblyHub 给 Envoy 和 Istio 赋能 WebAssembly
subtitle: 一个构建、发布、共享和部署 WebAssembly Envoy 扩展的地方
description: Solo.io 为 Istio 提供了 Wasm 的社区合作伙伴工具。
publishdate: 2020-03-25
attribution: "Idit Levine (Solo.io)"
keywords: [wasm,extensibility,alpha,performance,operator]
---

[*最初发布在 Solo.io 博客上*](https://www.solo.io/blog/an-extended-and-improved-webassembly-hub-to-helps-bring-the-power-of-webassembly-to-envoy-and-istio/)

随着组织采用诸如 Istio 之类的基于 Envoy 的基础架构来帮助解决微服务通信方面的挑战，他们不可避免地发现自己需要自定义基础架构的一些部分来匹配它们组织的约束。[WebAssembly（Wasm）](https://webassembly.org/)已经成为一种安全，安全且动态的平台扩展环境。

在最近的 [Istio 1.5 公告](/zh/blog/2020/wasm-announce/)中，Istio 项目为将 WebAssembly 带入流行的 Envoy 代理奠定了基础。[Solo.io](https://solo.io) 与谷歌和 Istio 社区合作来简化对 Envoy 和 Istio 创建，共享和部署 WebAssembly 扩展的整体体验。不久之前，谷歌和其他公司为容器奠定了基础，而 Docker 建立了良好的用户体验使其具有可消费性。同样，通过在 Istio 上为 WebAssembly 构建最佳用户体验，这一努力使 Wasm 可消费。

早在 2019 年 12 月，随着 WebAssembly Hub 的发布，Solo.io 开始努力为 WebAssembly 提供良好的开发人员体验。WebAssembly Hub 允许开发人员非常快速地启动 C++ 中的新 WebAssembly 项目（我们正在扩展此语言选择，请参见下文），在 Docker 中使用 Bazel 进行构建，并将其推送到 OCI 兼容仓库中。从那里，operators 必须拉出模块，然后自己配置 Envoy 代理才能从磁盘加载它。[基于 Envoy 构建的 API 网关 Gloo](https://docs.solo.io/gloo/latest/) 中的 Beta 支持让您可以声明式地动态地加载模块，Solo.io 团队希望为您带来同样的轻松体验以及其他基于 Envoy 的框架（例如 Istio）的安全体验。

这个领域的创新引起了人们的极大兴趣，Solo.io 团队一直在努力提高 WebAssembly Hub 的功能及其支持的工作流程。Solo.io 激动地宣布与 Istio 1.5 结合，对 WebAssembly Hub 进行了新的增强，这些改进增强了 Envoy 在 WebAssembly 上的生产能力，改善了开发人员的体验，并简化了在 Istio 中将 Wasm 与 Envoy 结合使用的过程。

## 逐步走向生产{#evolving-toward-production}

Envoy 社区正在努力将 Wasm 支持引入上游项目（现在它位于一个有效的开发分支中），Istio 宣布 Wasm 支持 Alpha 功能。在 [Gloo 1.0 中，我们还宣布了](https://www.solo.io/blog/announcing-gloo-1-0-a-production-ready-envoy-based-api-gateway/)支持 Wasm。 什么是 Gloo？Gloo 是一种现代的 API 网关和入口控制器（基于 Envoy 代理构建），支持路由和保护传入流量到传统的单体架构，微服务/Kubernetes 和无服务功能。开发和运营团队能够调整和控制从外部终端用户/客户端到后端应用程序服务的流量模式。Gloo 是 Kubernetes 和 Istio 的本地入口网关。

尽管每个项目的成熟度都很高，但是作为社区，我们可以做些事情来改善生产支持的基础。

第一个领域是标准化 Envoy 的 WebAssembly 扩展的外观。Solo.io，谷歌和 Istio 社区已定义了一个开放规范，用于将 WebAssembly 模块捆绑和分发为 OCI 镜像。该规范为分发包括 Envoy 扩展名在内的任何类型的 Wasm 模块提供了一个强大的模型。

这是向社区开放的-[加入我们的行列](https://github.com/solo-io/wasm-image-spec)

下一个领域是改善部署 Wasm 扩展到基于 Envoy 的框架运行的生产环境的体验。在 Kubernetes 生态中，使用声明性的基于 CRD 的配置来管理集群配置被认为是生产中的最佳实践。新的 [WebAssembly Hub Operator](https://docs.solo.io/web-assembly-hub/latest/tutorial_code/wasme_operator/) 添加了一个声明式的 CRD，该 CRD 可自动将 Wasm 筛选器部署和配置到在 Kubernetes 集群中运行的 Envoy 代理。Operator 使 GitOps 工作流程和集群自动化能够管理 Wasm 筛选器，而无需人工干预或命令性的工作流程。我们将在即将发布的博客文章中提供有关 Operator 的更多信息。

最后，Wasm 扩展的开发人员与部署它们的团队之间的交互需要某种基于角色访问，组织管理和设施来共享，发现和使用这些扩展。WebAssembly Hub 添加了团队管理功能，例如权限，组织，用户管理，共享等。

## 改善开发人员体验{#improving-the-developer-experience}

由于开发人员希望以更多的语言和运行时间为目标，所以体验必须保持尽可能简单和高效。多语言支持和运行时 ABI（应用程序二进制接口）目标应在工具中自动处理。

Wasm 的好处之一是能够用多种语言编写模块。Solo.io 与谷歌之间的合作为用 C++，Rust 和 AssemblyScript 编写的 Envoy 过滤器提供了开箱即用的支持。我们将继续增加对更多语言的支持。

Wasm 扩展使用部署它们的 Envoy 代理内的应用程序二进制接口（ABI）。WebAssembly Hub 在 Envoy，Istio 和 Gloo 之间提供了强大的 ABI 版本保证，可以防止不可预测的行为和错误。您只需关心编写您的扩展代码。

最后，像 Docker 一样，WebAssembly Hub 将 Wasm 扩展存储和分发为 OCI 镜像。这使得推，拉和运行 Wasm 扩展像 Docker 容器一样容易。Wasm 扩展镜像经过版本控制和加密保护，从而可以像在生产环境中一样安全地在本地运行扩展。这样，当他们下拉和部署镜像时，您就可以构建和推送镜像以及信任镜像来源。

## Istio 集成 WebAssembly Hub{#web-assembly-hub-with-Istio}

WebAssembly Hub 现在完全自动化了将 Wasm 扩展部署到安装在 Kubernetes 中的 Istio（以及其他基于 Envoy 的框架，例如 [Gloo API Gateway](https://docs.solo.io/gloo/latest/)） 的过程。借助此部署功能，WebAssembly Hub 使 operator 或终端用户无需在 Istio 服务网格中手动配置 Envoy 代理即可使用其 WebAssembly 模块。

观看以下视频，了解 WebAssembly 和 Istio 入门的简便性：

* [第 1 部分](https://www.youtube.com/watch?v=-XPTGXEpUp8)
* [第 2 部分](https://youtu.be/vuJKRnjh1b8)

## 开始使用{#get-started}

我们希望 WebAssembly Hub 将成为社区共享，发现和分发 Wasm 扩展的聚会场所。通过提供良好的用户体验，我们希望使 Wasm 的开发，安装和运行变得更轻松，更有意义。加入我们的[WebAssembly Hub](https://webassemblyhub.io)，共享您的扩展名和[想法](https://slack.solo.io)，并且加入[即将举行的网络研讨会](https://solo.zoom.us/webinar/register/WN_i8MiDTIpRxqX-BjnXbj9Xw)。
