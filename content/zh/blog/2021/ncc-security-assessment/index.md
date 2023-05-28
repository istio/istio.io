---
title: "公布 Istio 首次安全评估结果"
description: NCC Group 的第三方安全审查结果。
publishdate: 2021-07-13
attribution: "Neeraj Poddar (Aspen Mesh)，代表 Istio 产品安全工作组"
keywords: [istio,security,audit,ncc,assessment]
---

Istio 服务网格已在各行各业获得广泛的生产应用。
该项目的成功及其在基础设施中执行关键安全策略的重要用途，
保证了可以对与该项目相关的安全风险进行公开和中立的评估。

为实现这一目标，Istio 社区于去年与 [NCC Group](https://www.nccgroup.com/)
签约，并对项目进行第三方安全评估。审查的目标是“识别与 Istio
代码库相关的安全问题，突显管理员常用的高风险配置，
并提出针对安全功能是否足以解决那些它们在设计初衷希望解决问题的观点”。

NCC Group 与 Istio 社区的主题专家合作，在五周内进行审查。在这篇博客中，
我们将研究报告的主要发现、为实施各种修复和建议而采取的行动，
以及我们对 Istio 项目进行持续安全评估和改进的行动计划。
您可以下载并阅读完整版的[安全评估报告（英文）](./NCC_Group_Google_GOIST2005_Report_2020-08-06_v1.1.pdf)。

## 工作范围和主要发现{#scope-and-key-findings}

该评估对 Istio 的架构整体安全相关问题进行了分析，重点关注关键组件，
如 istiod（Pilot）、Ingress/Egress 网关，以及 Istio 的整体 Envoy
作为其数据平面代理的使用。此外，还审核了包括安全指南等 Istio
文档的正确性和清晰度。该报告是针对 Istio 1.6.5 版编写的，从那时起，
产品安全工作组随着新漏洞的披露发布了多个安全版本，并修复了新报告中提出的问题。

该报告的一个重要结论是，审计人员在 Istio 项目中没有发现任何“严重”问题。
这一发现证实了 Istio 的产品安全工作组（PSWG）实施的持续和主动的安全审查和漏洞管理流程的有效性。
对于报告中出现的其余问题，PSWG 已着手解决，
我们很高兴地宣布所有标记为“High”的问题和几个标记为“Medium/Low”的问题已在报告发布后的版本中得到解决。

该报告还围绕创建强化指南提出了战略建议，
该指南现已在我们的[安全最佳实践](/zh/docs/ops/best-practices/security/)指南中提供。
这是一份汇集了 Istio 社区安全专家和在生产环境中运行 Istio
的行业领导者的建议的综合文档。创建一个稳固和强化的安全配置文件工作正在进行，
以便在安全环境中安装 Istio，但在此期间，
我们建议用户遵循安全最佳实践指南并配置 Istio 以满足安全要求。
至此，我们再来看一下报告中提出的各种问题分析和解决方案。

## 决议和经验{#resolution-and-learnings}

### 无法保护控制平面的网络通信{inability-to-secure-control-plane-network-communications}

该报告标记了旧版本 Istio 中可用的配置选项，以控制如何确保与控制平面的通信安全。
从 1.7 版开始，Istio 默认保护所有控制平面通信，
不再需要报告中提到的许多配置选项来管理加密控制平面。

报告中提到的（从 Istio 1.10 开始）默认启用允许用户使用 `istioctl`
工具调试他们的 Istio 服务网格的问题。
如[安全最佳实践](/zh/docs/ops/best-practices/security/#control-plane)指南中所述，
可以通过将环境变量 `ENABLE_DEBUG_ON_HTTP` 设置为 false 来禁用它。
此外，在即将推出的版本（1.11）中，此调试端点将默认受到保护，
并且需要有效的 Kubernetes 服务帐户令牌才能获得访问权限。

### 缺乏安全相关的文档{#lack-of-security-related-documentation}

该报告指出了与 Istio 1.6 一起发布的安全相关文档中的漏洞。
从那时起，我们创建了详细的[安全最佳实践](/zh/docs/ops/best-practices/security/)指南，
其中包含了推荐方式以满足用户可以安全地部署 Istio 的需求。
展望未来，我们将继续通过更多强化建议来扩充此文档。我们建议用户关注这些指南的更新。

### 缺少 VirtualService Gateway 字段验证会导致请求劫持{#lack-of-virtualservice-gateway-field-validation-enables-request-hijacking}

对于此问题，该报告使用了一个有效但宽松的网关配置，
该配置可能会导致请求被错误地路由。与 Kubernetes RBAC 类似，
Istio API（包括 Gateway）可以根据您的要求调整为宽松或受限的模式。
但是，该报告显示我们的文档中缺少与最佳实践相关的链接，
并指导我们的用户保护他们的环境。为了解决这些问题，
我们在安全最佳实践指南中添加了部分内容，其中包含安全运行
[Gateway](/zh/docs/ops/best-practices/security/#gateways) 的步骤。
特别是，该章节描述了强烈建议在 Gateway
资源上强化[在主机设置中使用命名空间前缀](/zh/docs/ops/best-practices/security/#avoid-overly-broad-hosts-configurations)的部分，
以防止这种请求劫持情况的发生。

### Ingress Gateway 配置生成导致请求劫持{#ingress-gateway-configuration-generation-enables-request-hijacking}

当使用 Gateway 资源中跨命名空间的标签选择网关工作负载的默认机制时，
该报告提出了可能产生请求劫持的情况。默认情况下选择此行为会允许将所管理的
Gateway 和 VirtualService 资源委托给应用程序团队，
同时允许运营团队集中管理入口网关工作负载以满足他们独特的安全要求，
例如在专用节点上运行。正如报告中强调的那样，如果您的环境不需要此部署拓扑，
强烈建议将 Gateway 资源与网关工作负载放在一起，并将环境变量
`PILOT_SCOPE_GATEWAY_TO_NAMESPACE` 设置为 true。

请参阅[网关部署拓扑指南](/zh/docs/setup/additional-setup/gateway/#gateway-deployment-topologies)以了解
Istio 社区推荐的各种部署模型。此外，如[安全最佳实践](/zh/docs/ops/best-practices/security/#restrict-gateway-creation-privileges)指南中所述，
Gateway 资源创建应使用 Kubernetes RBAC 或其他策略执行机制进行访问控制，
以确保只有授权实体才能创建它们。

### 其他 Medium 及 Low 严重级别问题{#other-medium-and-low-severity-issues}

报告中有两个中等严重程度的问题，这些问题与项目中暴露的不同级别调试信息有关，
这些信息可用于获取对敏感信息的访问权限或编排 Denial of Service（DOS）攻击。
虽然 Istio 默认开启这些调试接口以进行分析或启用诸如“istioctl”之类的工具，
但可以通过将环境变量 `ENABLE_DEBUG_ON_HTTP` 设置为 false 来禁用如上所述内容。

该报告正确地指出，安装在 Istio 提供的默认镜像中的各种实用程序，
如 `sudo`、`tcpdump` 等，可能会导致权限提升攻击。
提供这些实用程序是为了帮助运行时调试流经网格的数据包，
建议用户在生产中使用这些镜像的[强化版本](/zh/docs/ops/configuration/security/harden-docker-images/)。

该报告还提出了一个已知的架构限制，即任何基于 Sidecar
代理的服务网格实现都使用 `iptables` 来拦截流量。
这种机制容易受到[绕过 Sidecar 代理](/zh/docs/ops/best-practices/security/#understand-traffic-capture-limitations)的影响，这是对安全环境的有效关注。
可以通过遵循安全最佳实践指南的[深度防御](/zh/docs/ops/best-practices/security/#defense-in-depth-with-networkpolicy)建议来解决这个问题。

## 易用性和安全之间的权衡{#the-tradeoff-between-useful-and-secure}

您可能已经注意到评估结果的趋势以及为解决这些问题而提出的建议。
Istio 提供各种配置选项以根据您的要求创建更安全的安装过程，
我们还引入了全面的[安全最佳实践](/zh/docs/ops/best-practices/security)指南供我们的用户遵循。
由于 Istio 已经在生产中被广泛应用，
因此我们需要在切换到安全默认设置和现有用户升级时可能出现的迁移问题之间进行权衡。
Istio 产品安全工作组评估了报告中的每一个问题，并制定了一个行动计划，
以便在为我们的用户提供多个版本以选择加入安全配置并迁移他们的工作负载后，
根据具体情况启用安全默认设置。

最后，我们在进行中立安全评估的过程中和结束后都获得了一些教训。
首要任务是确保我们的安全实践稳健可靠，能够快速响应审查结果，
更重要的是在增强安全性的同时保持我们无中断升级的标准。

为了继续这一努力，我们一直在 Istio 产品安全工作组中寻求反馈及参与，
所以[加入我们的公开会议](https://github.com/istio/community/blob/master/WORKING-GROUPS.md)，
提出问题或了解我们为确保 Istio 安全所做的工作！
