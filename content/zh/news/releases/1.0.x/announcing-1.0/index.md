---
title: Istio 1.0 发布公告
linktitle: "1.0"
subtitle: service mesh 生产就绪
description: Istio 1.0 已经生产就绪。
publishdate: 2018-07-31
release: 1.0.0
aliases:
    - /zh/about/notes/1.0
    - /zh/blog/2018/announcing-1.0
    - /zh/news/2018/announcing-1.0
    - /zh/news/announcing-1.0.0
    - /zh/news/announcing-1.0
---

今天，我们激动的宣布，Istio 1.0 正式发布！自我们最初发布 0.1 版以来已经一年多了。从那时起，一个由贡献者和用户组成的蓬勃发展的社区，使得 Istio 有了长足的发展。现在，许多公司已成功将 Istio 投入生产，并从 Istio 对部署的洞察力和控制力中获得了真正的价值。我们帮助了很多大型企业和快速发展的初创企业，例如：[eBay](https://www.ebay.com/)、[Auto Trader UK](https://www.autotrader.co.uk/)、[Descartes Labs](http://www.descarteslabs.com/)、[HP FitStation](https://www.fitstation.com/)、[JUSPAY](https://juspay.in)、[Namely](https://www.namely.com/)、[PubNub](https://www.pubnub.com/) 和 [Trulia](https://www.trulia.com/) 已经使用 Istio 从头开始连接、管理和保护其服务。将此版本发布为 1.0 表示我们已经建立了一套核心功能，可供用户在生产中使用。

{{< relnote >}}

## 生态系统{#ecosystem}

去年，我们发现 Istio 的生态系统有了大幅增长。
[Envoy](https://www.envoyproxy.io/) 继续保持惊人的增长，并增加了许多对服务网格生产质量至关重要的功能。
诸如 [Datadog](https://www.datadoghq.com/)、[SolarWinds](https://www.solarwinds.com/)、[Sysdig](https://sysdig.com/blog/monitor-istio/)、[Google Stackdriver](https://cloud.google.com/stackdriver/) 和 [Amazon CloudWatch](https://aws.amazon.com/cloudwatch/) 之类的可观测性提供商已经编写了将 Istio 与他们的产品集成的插件。
[Tigera](https://www.tigera.io/resources/using-network-policy-concert-istio-2/)、[Aporeto](https://www.aporeto.com/)、[Cilium](https://cilium.io/) 和 [Styra](https://styra.com/) 为我们的策略执行和网络功能构建了扩展。
[Red Hat](https://www.redhat.com/en) 构建了 [Kiali](https://www.kiali.io)，以围绕网格管理和可观测性提供不错的用户体验。
[Cloud Foundry](https://www.cloudfoundry.org/) 基于 Istio 的下一代流量路由栈，
最近宣布的 [Knative](https://github.com/knative/docs) serverless 项目也在做同样的事情，并且 [Apigee](https://apigee.com/) 宣布他们计划在其 API 管理中使用它。
这些只是社区去年添加集成中的一部分。

## 特性{#features}

自 0.8 版以来，我们添加了一些重要的新功能，更重要的是将许多现有功能标记为 Beta，表明它们已可以投入生产。以下是一些要点：

- 现在可以将多个 Kubernetes 集群[添加到单个网格](/zh/docs/setup/install/multicluster/)中，并实现跨集群通信和一致的策略实施。多群集支持现在为 Beta。

- 现在，可以对通过网状网络的流量进行细粒度控制的网络 API 已成为 Beta。使用网关对进入和退出问题进行显式建模，使运维人员可以[控制网络拓扑](/zh/blog/2018/v1alpha3-routing/)并满足边缘的访问安全性要求。

- 双向 TLS 现在[以增量方式推出]，无需更新服务的所有客户端。这是一项关键功能，现有生产部署可以无障碍的就地采用。

- Mixer 开始支持[开发进程外适配器](https://github.com/istio/istio/wiki/Out-Of-Process-gRPC-Adapter-Dev-Guide)。这将成为在未来发行版中扩展 Mixer 的默认方法，并使构建适配器更加简单。

- 现在，由 Envoy 完全控制本地控制访问服务的[授权策略](/zh/docs/concepts/security/#authorization)，以提高其性能和可靠性。

- 现在建议使用 [Helm chart 安装](/zh/docs/setup/install/helm/)方法，该方法提供了丰富的自定义选项，可以按您的意愿采用 Istio。

- 我们已经在性能上做出了很多努力，包括连续回归测试，大规模环境模拟和目标修复。我们对结果感到非常满意，并将在未来几周内详细分享更多信息。

## 接下来呢？{#what-is-next}

尽管这是该项目的重要里程碑，但还有很多工作要做。通过与使用者合作，我们获得了很多有关下一步重点的反馈。我们听到了围绕以下功能的一致诉求：混合云、安装模块化、更丰富的网络功能和大规模部署的可伸缩性。我们已经在 1.0 版本中考虑了其中一些反馈，并且在接下来的几个月中我们将继续积极地解决这项工作。

## 开始之前{#getting-started}

如果您是 Istio 的新手，并希望将其用于您的部署，我们很乐意听取您的意见。
可以看看[我们的文档](/zh/docs/)或者移步我们的[聊天室](https://discuss.istio.io)。
如果您想更深入地[为项目做贡献](/zh/about/community)，请参加一个我们的社区会议，并打个招呼。

## 感谢{#thanks}

Istio 团队非常感谢为该项目做出贡献的每个人。没有您的帮助，就没有 Istio 的今天。这一年真的太神奇了，我们非常期待接下来的一年，我们共同构成的社区又可以取得什么样的成就。

## 发行说明{#release-notes}

### 网络{#networking}

- **使用虚拟服务的 SNI 路由**。[`VirtualService`](/zh/docs/reference/config/networking/virtual-service/) 新引入的 `TLS` 部分，可用于基于 SNI 值的路由 TLS 流量。可以将名为 TLS/HTTPS 的服务端口与虚拟服务 TLS 路由结合使用。没有附带虚拟服务的 TLS/HTTPS 端口将被视为不透明的 TCP。

- **恢复流式 gRPC**。Istio 0.8 导致长时间运行的流式 gRPC 连接的定期终止。此问题已在 1.0 中修复。

- **移除旧的（v1alpha1）网络 API**。对旧的 `v1alpha1` 流量管理模型的支持已被删除。

- **弃用 Istio Ingress**。默认情况下，旧的 Istio Ingress 已被弃用并禁用。我们鼓励用户改用 [gateway](/zh/docs/concepts/traffic-management/#gateways)。

### 策略和遥测{#policy-and-telemetry}

- **更新的属性**。用于描述流量来源和目的地的一组[属性](/zh/docs/reference/config/policy-and-telemetry/attribute-vocabulary/)已被彻底修改，变得更加精确和全面。

- **策略检查缓存**。Mixer 现在具有了用于策略检查的大型 2 级缓存，补充了 sidecar 代理中存在的 1 级缓存。这进一步减少了外部强制策略检查的平均延迟。

- **遥测缓冲**。Mixer 现在可以在将调用报告分配给适配器之前先缓冲调用报告，这为适配器提供了机会以更大的块处理遥测数据，从而减少了 Mixer 及其适配器的总体计算开销。

- **进程外适配器**。Mixer 现在包括对进程外适配器的初始支持。这将是与 Mixer 集成的推荐方法。[进程外适配器开发指南](https://github.com/istio/istio/wiki/Mixer-Out-Of-Process-Adapter-Dev-Guide)和[进程外适配器遍历](https://github.com/istio/istio/wiki/Mixer-Out-Of-Process-Adapter-Walkthrough)提供了有关如何构建进程外适配器的初始文档。

- **客户端遥测**。现在，除了服务器端遥测之外，还可以从交互的客户端收集遥测。

#### 适配器{#adapters}

- **SignalFX**。新的 `signalfx` 适配器。

- **Stackdriver**。[`stackdriver`](/zh/docs/reference/config/policy-and-telemetry/adapters/stackdriver/) 适配器在此发行版中得到大幅增强，添加了新功能并提高性能。

### 安全{#security}

- **授权**。我们已经重新实现了[授权功能] 的 RPC 级授权策略，此功能现在的实现，不再需要使用 Mixer 和 Mixer 适配器。

- **改进双向 TLS 身份认证控制**。现在，可以更轻松地控制服务之间的[双向 TLS 身份认证](/zh/docs/concepts/security/#authentication)。我们提供 `PERMISSIVE` 模式，以便您可以为您的服务[递增地启用双向 TLS](/zh/docs/tasks/security/authentication/mtls-migration/)。我们移除了服务注释，采用[独特的方法来启用双向 TLS](/zh/docs/tasks/security/authentication/authn-policy/)，并结合了客户端[目标规则](/zh/docs/concepts/traffic-management/#destination-rules)。

- **JWT 授权**。现在支持 [JWT 身份验证](/zh/docs/concepts/security/#authentication)，可以使用[身份验证策略](/zh/docs/concepts/security/#authentication-policies)对其进行配置。

### `istioctl`

- 添加 [`istioctl authn tls-check`](/zh/docs/reference/commands/istioctl/#istioctl-authn-tls-check) 命令。

- 添加 [`istioctl proxy-status`](/zh/docs/reference/commands/istioctl/#istioctl-proxy-status) 命令。

- 添加 `istioctl experimental convert-ingress` 命令。

- 移除 `istioctl experimental convert-networking-config` 命令。

- 改进和 bug 修复：

    - 使 `kubeconfig` handle 与 `kubectl` 对齐。

    - `istioctl get all` 返回所有类型的网络和身份验证配置。

    - 在 `istioctl get` 中添加了 `--all-namespaces` 标志，用于检索所有命名空间中的资源。

### 1.0 已知问题{#known-issues-with-1-0}

- Amazon EKS 服务未实现 sidecar 自动注入。在 Amazon EKS 中使用 Istio 需要为 sidecar 使用[手动注入](/zh/docs/setup/additional-setup/sidecar-injection/#manual-sidecar-injection)并通过 [Helm 参数](/zh/docs/setup/install/helm) `--set galley.enabled=false` 关闭 galley。

- 在[多集群部署](/zh/docs/setup/install/multicluster)中，mixer-telemetry 和 mixer-policy 组件不会连接到任何远程集群的 Kubernetes API 端点。由于与远程集群上的工作负载相关的某些元数据不完整，这会导致遥测保真度的损失。

- 有的 Kubernetes 清单，可用于独立使用 Citadel 或启用 Citadel 运行状况检查。Helm 没有实现这些模式。有关更多详细信息，请参见 [Issue 6922](https://github.com/istio/istio/issues/6922)。

- 网格扩展功能，使您可以将原始 VM 添加到网格，此功能在 1.0 中已被破坏。我们预计将在几天内产生可解决此问题的补丁。
