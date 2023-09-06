---
title: Announcing Istio 1.19.0
linktitle: 1.19.0
subtitle: 大版本更新
description: Istio 1.19 发布公告。
publishdate: 2023-09-05
release: 1.19.0
aliases:
    - /news/announcing-1.19
    - /news/announcing-1.19.0
---

We are pleased to announce the release of Istio 1.19. This is the third Istio release of 2023. We would like to thank the entire Istio community for helping get the 1.19.0 release published. We would like to thank the Release Managers for this release, `Kalya Subramanian` from Microsoft, `Xiaopeng Han` from DaoCloud, and `Aryan Gupta` from Google. The release managers would specially like to thank the Test & Release WG lead Eric Van Norman (IBM) for his help and guidance throughout the release cycle. We would also like to thank the maintainers of the Istio work groups and the broader Istio community for helping us throughout the release process with timely feedback, reviews, community testing and for all your support to help ensure a timely release.
我们很高兴地宣布 Istio 1.19 发布。这是 2023 年的第三个 Istio 版本，
我们要感谢整个 Istio 社区对 1.19.0 版本发布所作出的帮助。
我们要感谢此版本的几位发布经理：来自 Microsoft 的 `Kalya Subramanian`、
来自 DaoCloud 的 `Xiaopeng Han` 和来自 Google 的 `Aryan Gupta`。
这些发布经理们要特别感谢测试和发布工作组负责人 Eric Van Norman (IBM) 在整个发布周期中提供的帮助和指导。
我们还要感谢 Istio 工作组的维护者以及广大 Istio 社区，在发布过程中提供及时反馈、
审核和社区测试，以及在确保及时发布方面给予的全力支持。


{{< relnote >}}

{{< tip >}}
Istio 1.19.0 is officially supported on Kubernetes versions `1.25` to `1.28`.
Istio 1.19.0 已得到 Kubernetes `1.25` 到 `1.28` 的官方正式支持。
{{< /tip >}}

## 新特性 {#what-is-new}

### Gateway API

The Kubernetes [Gateway API](http://gateway-api.org/) is an initiative to bring a rich set of service networking APIs (similar to those of Istio VirtualService and Gateway) to Kubernetes.
Kubernetes [Gateway API](http://gateway-api.org/) 是一项旨在为 Kubernetes 带来丰富的服务网络 API（类似于 Istio VirtualService 和 Gateway）的举措。

In this release, in tandem with the Gateway API v0.8.0 release, [service mesh support](https://gateway-api.sigs.k8s.io/blog/2023/0829-mesh-support/) is officially added! This effort was a widespread community effort across the broader Kubernetes ecosystem and has multiple conformant implementations (including Istio).
在此版本中，配合 Gateway API v0.8.0 版本，正式添加了[服务网格支持](https://gateway-api.sigs.k8s.io/blog/2023/0829-mesh-support/)！ 这项工作是跨更广泛的 Kubernetes 生态系统的广泛社区努力，并且有多个一致的实现（包括 Istio）。

Check out the [mesh documentation](/docs/tasks/traffic-management/ingress/gateway-api/#mesh-traffic) to get started. As with any experimental feature, feedback is highly appreciated.
查看 [mesh 文档](/docs/tasks/traffic-management/ingress/gateway-api/#mesh-traffic) 以开始使用。 与任何实验性功能一样，我们非常感谢反馈。

In addition to mesh traffic, usage of the API for ingress traffic [is in beta](/docs/tasks/traffic-management/ingress/gateway-api/#configuring-a-gateway) and rapidly approaching GA.
除了网状流量之外，入口流量的 API 的使用[处于测试阶段](/docs/tasks/traffic-management/ingress/gateway-api/#configuring-a-gateway) 并迅速接近 GA。

### Ambient Mesh

During this release cycle, the team has been hard at work improving the [ambient mesh](/docs/ops/ambient/), a new Istio deployment model alternative to the previous sidecar model. If you haven't heard of ambient yet, check out the [introduction blog post](/blog/2022/introducing-ambient-mesh/).
在此发布周期中，团队一直在努力改进 [ambient mesh](/docs/ops/ambient/)，这是替代之前 sidecar 模型的新 Istio 部署模型。 如果您还没有听说过环境，请查看[介绍博客文章](/blog/2022/introducing-ambient-mesh/)。

In this release, support for `ServiceEntry`, `WorkloadEntry`, `PeerAuthentication`, and DNS proxying has been added. In addition, a number of bug fixes and reliability improvements have been made.
在此版本中，添加了对“ServiceEntry”、“WorkloadEntry”、“PeerAuthentication”和 DNS 代理的支持。 此外，还修复了许多错误并提高了可靠性。

Note that ambient mesh remains at the alpha feature phase in this release. Your feedback is critical to driving ambient to Beta, so please try it out and let us know what you think!
请注意，在此版本中，环境网格仍处于 alpha 功能阶段。 您的反馈对于推动环境进入 Beta 版至关重要，因此请尝试一下并告诉我们您的想法！

### Additional Improvements
### 其他改进

To further simplify the `Virtual Machine` and `Multicluster` experiences, the address field is now optional in the `WorkloadEntry` resources.
为了进一步简化“虚拟机”和“多集群”体验，“WorkloadEntry”资源中的地址字段现在是可选的。

We also added enhancements to security configurations. For example, you can configure `OPTIONAL_MUTUAL` for your Istio ingress gateway's TLS settings, which allows optional use and validation of a client certificate. Furthermore, you can also configure your preferred cipher suites used for non Istio mTLS traffic via `MeshConfig`.
我们还增强了安全配置。 例如，您可以为 Istio 入口网关的 TLS 设置配置“OPTIONAL_MUTUAL”，这允许选择性使用和验证客户端证书。 此外，您还可以通过“MeshConfig”配置用于非 Istio mTLS 流量的首选密码套件。

## 升级至 1.19 {#upgrading-to-1.19}

We would like to hear from you regarding your experience upgrading to Istio 1.19. You can provide feedback at [Discuss Istio](https://discuss.istio.io/), or join the #release-1.19 channel in our [Slack workspace](https://slack.istio.io/).
我们期待倾听您关于升级到 Istio 1.19 的体验。
您可以加入 [Discuss Istio](https://discuss.istio.io/) 的会话中提供反馈，
或加入我们的 [Slack 工作空间](https://slack.istio.io/)中的 #release-1.19 频道。

Would you like to contribute directly to Istio? Find and join one of our [Working Groups](https://github.com/istio/community/blob/master/WORKING-GROUPS.md) and help us improve.
您想直接为 Istio 做贡献吗？
找到并加入我们的某个[工作组](https://github.com/istio/community/blob/master/WORKING-GROUPS.md)，
帮助我们改进。
