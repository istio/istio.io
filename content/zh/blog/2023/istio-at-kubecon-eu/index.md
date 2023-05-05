---
title: "KubeCon 2023 欧洲站中的 Istio"
description: 快速回顾在阿姆斯特丹 RAI 的 KubeCon 欧洲站中的 Istio。
publishdate: 2023-04-27
attribution: "Faseela K，来自 Istio Day 计划委员会"
keywords: [Istio Day,IstioCon,Istio,conference,KubeCon,CloudNativeCon]
---

4 月 18 日至 21 日，云原生及开源社区欢聚在举办于阿姆斯特丹的 2023 年第一场 KubeCon 中。
这是一场由云原生计算基金会组织且专为 Istio 举办的为期四天的盛会，
也是在这片土地上，我们从当年 ServiceMeshCon 的一个参与者演变为如今第一个官方项目活动 (Istio Day Europe) 的组织者。

{{< image width="40%"
    link="./istio-day-welcome.jpg"
    caption="欢迎来到 Istio Day 2023 年欧洲站"
    >}}

在两位技术程序委员会 (Program Committee) 主席 Mitch Connors 和 Faseela K 的精彩开场主题演讲后，Istio Day 正式开始。
本次活动涵盖了从新功能到最终用户话题等丰富的内容，展厅内始终人头攒动。
[开场主题演讲](https://youtu.be/h9EgMrJ0ahs)以突击测试的形式利用 Istio 的一些有趣内容达到了破冰效果，
并对我们的贡献者、维护者、发布经理以及用户的日常工作表示了认可。

{{< image width="75%"
    link="./opening-keynote.jpg"
    caption="Istio Day 2023 欧洲站开场主题"
    >}}

随后来自 TOC 的成员 Lin Sun 和 Louis Ryan 讲述了 2023 年[路线图更新议题](https://youtu.be/GQccKyVe0R8)。
接着由 Christian Posta 和 John Howard 带来了期待已久的、曾在社区中引起一些有趣讨论的
[Ambient Mesh 安全态势](https://youtu.be/QnfrbbY_Hy4)议题。
在此之后，出场的是第一次来自荷兰本地公司 [Wehkamp 公司 John Keates 的最终用户访谈](https://youtu.be/Gb_I2RJr8kQ)，
紧跟着来自彭博社的讲师 Alexa Griffith 和 Zhenni Fu 演讲了[如何使用 Istio 保护他们的高特权财务信息](https://youtu.be/f6jMix46ZD8)。
Istio Day 见证了人们更加注重安全性，这一点在 Zack Butcher
讲到[使用 Istio 实现控制合规性](https://youtu.be/gIntE4Nn5r4)话题时达到了高潮。
Mitch Connors、Zhonghu Xu 和 Matt Turner 分别就[更快速的 Istio 开发环境](https://youtu.be/Onsukvmmm50)、
[Istio 资源隔离指南](https://youtu.be/TmlfQjChmNU)和[混合云部署安全](https://youtu.be/xejbMNbOwXk)话题进行了闪电演讲。

{{< image width="75%"
    link="./istioday-hall.jpg"
    caption="Istio Day 2023 欧洲站热点议题"
    >}}

我们有许多生态体系成员在本次活动中发布了与 Istio 相关的消息。
Microsoft 宣布 [Istio 作为 Azure Kubernetes 服务的托管加载项](https://learn.microsoft.com/zh-cn/azure/aks/istio-about)，
[D2iQ Kubernetes 平台](https://www.prnewswire.com/news-releases/d2iq-takes-multi-cloud-multi-cluster-fleet-management-to-the-next-level-with-kubernetes-platform-enhancements-301799358.html)正式发布了对 Istio 的支持。

Tetrate 针对 Amazon EKS 发布了基于 Istio 的服务连通性、安全性和弹性自动化解决方案：
[Tetrate Service Express](https://tetrate.io/blog/introducing-tetrate-service-express/)。
Solo.io 发布了基于 Istio 应用联网功能的 [Gloo Fabric](https://www.solo.io/blog/introducing-solo-gloo-fabric/)，可扩展到跨云环境的基于虚拟机、容器和 Serverless 应用程序。

Istio 相关的议题并没有随着 Istio Day 的结束而告终。
第二天的主题演讲以 Lin Sun 的 [项目更新视频](https://twitter.com/linsun_unc/status/1648952723604221953) 开始。
我们的指导委员会成员 Craig Box 在主题演讲中被 [认可为 CNCF 导师](https://twitter.com/IstioMesh/status/1648722572366708739)，
这对我们来说也是一个值得骄傲的时刻。

TOC 成员 Neeraj Poddar 介绍的 Istio 维护者路线引起了极大的关注，
他谈到了 Istio 目前正在进行的工作和未来的路线图。
这次演讲及其观众规模印证了为什么 Istio 是业内最受欢迎的服务网格。

{{< image width="75%"
    link="./use-istio-in-production.jpg"
    caption="KubeCon 2023 欧洲站，问题：你们中有多少人将 Istio 应用于生产环境中？"
    >}}

以下在 KubeCon 中的议题也都是基于 Istio 的，几乎所有议题都有大量的人参加：

* [Istio 的未来 - Sidecar、无 Sidecar 还是两者兼而有之？](https://sched.co/1HySB)
* [在生产环境中使用 ArgoCD 运行多租户 Istio](https://sched.co/1Hyd1)
* [使用任意编程语言创建 Istio 过滤器](https://sched.co/1HybK)
* [使用 Kubernetes 和服务网格的自动化云原生事件响应](https://sched.co/1HyZ9)
* [使用无代理 gRPC 和 Istio 为有状态应用程序自动缩放弹性 Kubernetes 基础设施](https://sched.co/1HyXz)
* [开发 Istio 的心智模型：从 Kubernetes 到 Sidecar 再到 Ambient](https://sched.co/1HyZj)
* [服务网格的未来 - Sidecar、无 Sidecar 还是无代理模式？ - 小组讨论会](https://sched.co/1Hydb)
* [十大 Istio 安全风险和缓解策略](https://sched.co/1HyPQ)

Istio 在 KubeCon 展厅中有一个全天候展台，
很大一部分问题都是关于我们在 CNCF 毕业状态相关的。
我们很高兴了解到用户热切期待我们毕业的消息，我们承诺正在为此积极努力！

{{< image width="75%"
    link="./istio-booth.jpg"
    caption="KubeCon 2023 欧洲站 Istio 展台"
    >}}

我们的许多 TOC 成员和维护者也在展位上提供了支持，
围绕 Istio Ambient Mesh 也进行了很多有趣的讨论。

{{< image width="75%"
    link="./toc-members-at-kiosk.jpg"
    caption="KubeCon 欧洲站，Istio 展台的更多支持"
    >}}

另一个亮点是 Istio TOC 成员、指导委员会成员兼作者 Lin Sun 和 Christian Posta 为
“Istio Ambient Explained”一书进行了签名。

{{< image width="75%"
    link="./ambient-mesh-book-authors.jpg"
    caption="KubeCon 欧洲站，Ambient Mesh 书籍作者签名"
    >}}

最后，但同样重要的是，我们要衷心感谢我们的白金赞助商 [Tetrate](http://tetrate.io/)，
感谢他们支持 Istio Day！

2023 年对于 Istio 来说将是非常重要的，未来几个月计划举办更多活动！
请持续关注 IstioCon 2023 的相关更新，以及 Istio 在中国和北美 KubeCon 中的精彩内容。
