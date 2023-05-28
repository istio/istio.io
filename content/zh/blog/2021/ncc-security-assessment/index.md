---
title: "公布 Istio 首次安全评估结果"
description: NCC Group 的第三方安全审查结果。
publishdate: 2021-07-13
attribution: "Neeraj Poddar (Aspen Mesh)，代表 Istio 产品安全工作组"
keywords: [istio,security,audit,ncc,assessment]
---

The Istio service mesh has gained wide production adoption across a wide variety of industries. The success of the project, and its critical usage for enforcing key security policies in infrastructure warranted an open and neutral assessment of the security risks associated with the project.
Istio 服务网格已在各行各业获得广泛的生产应用。
该项目的成功及其在基础设施中执行关键安全策略的关键用途，
保证了对与该项目相关的安全风险进行公开和中立的评估。

To achieve this goal, the Istio community contracted the [NCC Group](https://www.nccgroup.com/) last year to conduct a third-party security assessment of the project. The goal of the review was "to identify security issues related to the Istio code base, highlight high-risk configurations commonly used by administrators, and provide perspective on whether security features sufficiently address the concerns they are designed to provide".
为实现这一目标，Istio 社区于去年签约
[NCC Group](https://www.nccgroup.com/)
对项目进行第三方安全评估。
审查的目标是“确定与 Istio 代码库相关的安全问题，
突出管理员常用的高风险配置，
并提供有关安全功能是否足以解决它们在设计初衷的担忧的观点”。

NCC Group carried out the review over a period of five weeks with collaboration from subject matter experts across the Istio community. In this blog, we will examine the key findings of the report, actions taken to implement various fixes and recommendations, and our plan of action for continuous security evaluation and improvement of the Istio project. You can download and read the unabridged version of the [security assessment report](./NCC_Group_Google_GOIST2005_Report_2020-08-06_v1.1.pdf).
NCC Group 与 Istio 社区的主题专家合作，在五周内进行审查。
在这篇博客中，我们将研究报告的主要发现、
为实施各种修复和建议而采取的行动，以及我们对
Istio 项目进行持续安全评估和改进的行动计划。
您可以下载并阅读完整版的[安全评估报告（英文）](./NCC_Group_Google_GOIST2005_Report_2020-08-06_v1.1.pdf)。

## Scope and Key Findings
## 工作范围和主要发现{#scope-and-key-findings}

The assessment evaluated Istio’s architecture as a whole for security related issues with focus on key components like istiod (Pilot), Ingress/Egress gateways, and Istio’s overall Envoy usage as its data plane proxy. Additionally, Istio documentation, including security guides, were audited for correctness and clarity. The report was compiled against Istio version 1.6.5, and since then the Product Security Working Group has issued several security releases as new vulnerabilities were disclosed, along with fixes to address concerns raised in the new report.
该评估对 Istio 的架构整体安全相关问题进行了分析，
重点关注关键组件，如 istiod (Pilot)、Ingress/Egress 网关，
以及 Istio 的整体 Envoy 作为其数据平面代理的使用。
此外，还审核了包括安全指南等 Istio 文档的正确性和清晰度。
该报告是针对 Istio 1.6.5 版编写的，从那时起，
产品安全工作组随着新漏洞的披露发布了多个安全版本，
并修复了新报告中提出的问题。

An important conclusion from the report is that the auditors found no "Critical" issues within the Istio project. This finding validates the continuous and proactive security review and vulnerability management process implemented by Istio’s Product Security Working Group (PSWG). For the remaining issues surfaced by the report, the PSWG went to work on addressing them, and we are glad to report that all issues marked "High", and several marked "Medium/Low", have been resolved in the releases following the report.
该报告的一个重要结论是，审计人员在 Istio
项目中没有发现任何“严重”问题。这一发现证实了
Istio 的产品安全工作组（PSWG）实施的持续和主动的安全审查和漏洞管理流程。
对于报告中出现的其余问题，PSWG 着手解决这些问题，
我们很高兴地报告所有标记为“High”的问题和几个标记为“Medium/Low”的问题已在报告发布后的版本中得到解决。

The report also makes strategic recommendations around creating a hardening guide which is now available in our [Security Best Practices](/docs/ops/best-practices/security/) guide. This is a comprehensive document which pulls together recommendations from security experts within the Istio community, and industry leaders running Istio in production. Work is underway to create an opinionated and hardened security profile for installing Istio in secure environments, but in the interim we recommend users follow the Security Best Practices guide and configure Istio to meet their security requirements. With that, let’s look at the analysis and resolution for various issues raised in the report.
该报告还围绕创建强化指南提出了战略建议，
该指南现已在我们的[安全最佳实践](/zh/docs/ops/best-practices/security/)指南中提供。
这是一份汇集了 Istio 社区安全专家和在生产环境中运行
Istio 的行业领导者的建议的综合文档。
正在努力创建一个稳固的和强化的安全配置文件，
以便在安全环境中安装 Istio，但在此期间，
我们建议用户遵循安全最佳实践指南并配置 Istio 以满足安全要求。
至此，我们再来看一下报告中提出的各种问题分析和解决方案。

## Resolution and learnings
## 决议和学习{#resolution-and-learnings}

### Inability to secure control plane network communications
### 无法保护控制平面网络通信{inability-to-secure-control-plane-network-communications}

The report flags configuration options that were available in older versions of Istio to control how communication is secured to the control plane. Since 1.7, Istio by default secures all control plane communication and many configuration options mentioned in the report to manage control plane encryption are no longer required.
该报告标记了旧版本 Istio 中可用的配置选项，
以控制如何确保与控制平面的通信安全。
从 1.7 版开始，Istio 默认保护所有控制平面通信，
不再需要报告中提到的许多配置选项来管理控制平面加密。

The debug endpoint mentioned in the report is enabled by default (as of Istio 1.10) to allow users to debug their Istio service mesh using the `istioctl` tool. It can be disabled by setting the environment variable `ENABLE_DEBUG_ON_HTTP` to false as mentioned in the [Security Best Practices](/docs/ops/best-practices/security/#control-plane) guide. Additionally, in an upcoming version (1.11), this debug endpoint will be secured by default and a valid Kubernetes service account token will be required to gain access.
报告中提到的（从 Istio 1.10 开始）允许用户使用 istioctl
工具调试他们的 Istio 服务网格默认启用的问题。
如[安全最佳实践](/zh/docs/ops/best-practices/security/#control-plane)指南中所述，
可以通过将环境变量 `ENABLE_DEBUG_ON_HTTP` 设置为 false 来禁用它。
此外，在即将推出的版本（1.11）中，此调试端点将默认受到保护，
并且需要有效的 Kubernetes 服务帐户令牌才能获得访问权限。

### Lack of security related documentation
### 缺乏安全相关的文档{#lack-of-security-related-documentation}

The report points out gaps in the security related documentation published with Istio 1.6. Since then, we have created a detailed [Security Best Practices](/docs/ops/best-practices/security/) guide with recommendations to ensure users can deploy Istio securely to meet their requirements.  Moving forward, we will continue to augment this documentation with more hardening recommendations. We advise users to monitor the guide for updates.

### Lack of VirtualService Gateway field validation enables request hijacking

For this issue, the report uses a valid but permissive Gateway configuration that can cause requests to be routed incorrectly. Similar to the Kubernetes RBAC, Istio APIs, including Gateways, can be tuned to be permissive or restrictive depending upon your requirements.  However, the report surfaced missing links in our documentation related to best practices and guiding our users to secure their environments. To address them, we have added a section to our Security Best Practices guide with steps for running [Gateways](/docs/ops/best-practices/security/#gateways) securely. In particular, the section describing [using namespace prefixes in hosts specification](/docs/ops/best-practices/security/#avoid-overly-broad-hosts-configurations) on Gateway resources is strongly recommended to harden your configuration and prevent this type of request hijacking.

### Ingress Gateway configuration generation enables request hijacking

The report raises possible request hijacking when using the default mechanism of selecting gateway workloads by labels across namespaces in a Gateway resource. This behavior was chosen by default as it allows delegation of managing Gateway and VirtualService resources to the applications team while allowing operations teams to centrally manage the ingress gateway workloads for meeting their unique security requirements like running on dedicated nodes for instance. As highlighted in the report, if this deployment topology is not a requirement in your environment it is strongly recommended to co-locate Gateway resources with your gateway workloads and set the environment variable `PILOT_SCOPE_GATEWAY_TO_NAMESPACE` to true.

Please refer to the [gateway deployment topologies guide](/docs/setup/additional-setup/gateway/#gateway-deployment-topologies) to understand the various recommended deployment models by the Istio community. Additionally, as mentioned in the [Security Best Practices](/docs/ops/best-practices/security/#restrict-gateway-creation-privileges) guide, Gateway resource creation should be access controlled using Kubernetes RBAC or other policy enforcement mechanisms to ensure only authorized entities can create them.

### Other Medium and Low Severity Issues

There are two medium severity issues reported related to debug information exposed at various levels within the project which can be used to gain access to sensitive information or orchestrate Denial of Service (DOS) attacks. While Istio by default enables these debug interfaces for profiling or enabling tools like "istioctl", they can be disabled by setting the environment variable `ENABLE_DEBUG_ON_HTTP` to false as discussed above.

The report correctly points out that various utilities like `sudo`, `tcpdump`, etc. installed in the default images shipped by Istio can lead to privilege escalation attacks. These utilities are  provided to aid runtime debugging of packets flowing through the mesh, and users are recommended to use [hardened versions](/docs/ops/configuration/security/harden-docker-images/) of these images in production.

The report also surfaces a known architectural limitation with any sidecar proxy-based service mesh implementation which uses `iptables` for intercepting traffic. This mechanism is susceptible to [sidecar proxy bypass](/docs/ops/best-practices/security/#understand-traffic-capture-limitations), which is a valid concern for secure environments. It can be addressed by following the [defense-in-depth](/docs/ops/best-practices/security/#defense-in-depth-with-networkpolicy) recommendation of the Security Best Practices guide. We are also investigating more secure options in collaboration with the Kubernetes community.

## The tradeoff between useful and secure

You may have noticed a trend in the findings of the assessment and the recommendations made to address them. Istio provides various configuration options to create a more secure installation based on your requirement, and we have introduced a comprehensive [Security Best Practices](/docs/ops/best-practices/security) guide for our users to follow. As Istio is widely adopted in production, it is a tradeoff for us between switching to secure defaults and possible migration issues for our existing users on upgrades. The Istio Product Security Working Group evaluates each of these issues and creates a plan of action to enable secure default on a case-by-case basis after giving our users a number of releases to opt-in the secure configuration and migrate their workloads.

Lastly, there were several lessons for us during and after undergoing a neutral security assessment. The primary one was to ensure our security practices are robust to quickly respond to the findings, and more importantly making security enhancements while maintaining our standards for upgrades without disruption.

To continue this endeavor, we are always looking for feedback and participation in the Istio Product Security Working Group, so [join our public meetings](https://github.com/istio/community/blob/master/WORKING-GROUPS.md) to raise issues or learn about what we are doing to keep Istio secure!
