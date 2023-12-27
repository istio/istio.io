---
title: Istio 1.5 发布公告
linktitle: 1.5
subtitle: 更大更新
description: Istio 1.5 版本发布公告。
publishdate: 2020-03-05
release: 1.5.0
skip_list: true
aliases:
    - /zh/news/announcing-1.5.0
    - /zh/news/announcing-1.5
---

我们非常激动的宣布 Istio 1.5 正式发布！

{{< relnote >}}

通过将 Istio 控制平面的组件整合为单个二进制文件，我们让 Istio 的安装和运行都变得更加简单。
我们为整个行业的代理服务器引入了功能强大且快速的新扩展模型，并且我们将继需专注于可用性、安全性 、遥测以及流量控制。

经过一年 amazing 般的发展和学习，我们在本次发行版中打包了比 1.1 之后任何版本都多的软件包。一年前，我们决定转为每季度发布一次，我们很高兴地报告，这是我们连续第五次实现这一目标。用户也获得了比以往更快、更多的新功能！

以下是今天发布的版本中的一些功能：

## Istiod 介绍{#introducing-Istiod}

通过“拥抱单体”升级了 Istio，将控制平面整合为一个新的二进制文件——Istiod。我们极大地简化了安装、运行和升级 Istio 的流程。更少的活动组件让运维人员的调试和理解也变得更简单。对于网格用户，Istiod 不会改变他们的任何体验：所有 API 和运行时特性均与以前的组件一致。

在接下来的几天里，请留意有关 Istiod 和转向简单部署模型好处的博客文章。

## 新的可扩展性模型{#a-new-model-for-extensibility}

Istio 一直都是可扩展性最好的服务网格，其 Mixer 插件允许自定义策略和遥测，而 Envoy 扩展则允许数据平面自定义。在 Istio 1.5 中，我们发布了一个新模型，该模型使用 [WebAssembly](https://webassembly.org/)（Wasm）将 Istio 的可扩展性模型与 Envoy 统一。Wasm 将使开发人员能够安全地分发和执行 Envoy 代理中的代码，以便与遥测系统、策略系统、路由控制甚至是消息体转换（transform the body of a message）进行集成。它将更加灵活和高效，不再需要单独运行 Mixer 组件（这也简化了
部署）。

[阅读我们的 Wasm 博客](/zh/blog/2020/wasm-announce/)，同时您可以在 Google、Solo.io 以及 Envoy 社区中查找相关文章，了解这项令人激动的工作的详细信息！

## 更简单{#easier-to-use}

我们一直致力于使 Istio 更容易被接受和使用，尤其是此版本进行了一些很酷的增强。现在，使用 [`istioctl`](/zh/docs/reference/commands/istioctl) 的 Istio 命令行安装是安装的测试版，这适用于大多数用户。通过 Operator 管理安装的 Istio 仍处于 Alpha 状态，但是我们会使用新的 [`IstioOperator API`](/zh/docs/reference/config/istio.operator.v1alpha1/) 对其进行升级。

关于 `istioctl`，它有十几项改进，可以分析新项、更好的验证规则、更好的与 CI 系统集成（请查看即将推出的示例！）。
现在，它是了解正在运行 Istio 系统的状态、确保配置安全更改的必要工具。`istioctl analysis` 已从实验性阶段毕业。

我们对 Istio 安全性进行了许多增强，使其更易于使用。通过自动 mTLS 的 beat 版 launch，现在配置 mTLS 非常简单。
通过 Istio 1.4 中授权策略的 beta 版 launch，我们移除了间接访问，并将其合并到单个 CRD，使得访问控制也得到了简化。

## 更安全{#more-secure}

我们一如既往的在努力使每个 Istio 发布版都更加安全。在 1.5 中，所有安全策略（包括[自动 mTLS](/zh/docs/tasks/security/authentication/auto-mtls/)、[`AuthenticationPolicy`](/zh/docs/reference/config/security/istio.authentication.v1alpha1/)（`PeerAuthentication` 和 `RequestAuthentication`）以及授权现在都处于 Beta 版。SDS 现在是稳定的。授权现在支持 Deny 语义，以强制执行不可覆盖的强制性控件。我们已经将 Node 代理和 Istio 代理整合到一个二进制文件中，这意味着我们不再需要配置 `PodSecurityPolicy`。

不仅如此，我们也不再需要在每个 Pod 上安装证书、不必在更换证书时重启 Envoy。证书直接从 Istiod 下发到每个 pod。而且，每个 pod 的证书都是唯一证书。

想要更深入地了解 Istio 的安全性及其可防范的威胁，请留意未来几天的博客文章。

## 更好的可观测性{#better-observability}

我们将继续努力，使 Istio 成为您分布式应用的最佳选择。Telemetry v2 现在会报告原生 TCP 连接（除了 HTTP）的度量标准，并且我们通过在遥测和日志中添加响应状态代码来增强了对 gRPC 工作负载的支持。现在默认使用 Telemetry v2。

新的遥测系统将等待时间缩短了一半，90％ 的等待时间从 7 毫秒 降低至 3.3 毫秒。不仅如此，移除 Mixer 还使总的 CPU 消耗减少了 50％（0.55 vCPU，1000 个请求/每秒）。

## 加入 Istio 社区{#join-the-Istio-community}

与往常一样，很多事情都发生在[社区会议](https://github.com/istio/community#community-meeting)；每隔一个星期四的太平洋时间上午 11 点加入我们。我们希望您可以通过 [Istio Discuss](https://discuss.istio.io) 加入对话，此外，也可以加入我们的 [Slack 频道](https://istio.slack.com)。

我们很荣幸成为 GitHub [成长最快](https://octoverse.github.com/#top-and-trending-projects)的五个开源项目之一。想参与其中吗？加入我们的[工作组](https://github.com/istio/community/blob/master/WORKING-GROUPS.md)之一，帮助我们使 Istio 变得更好。
