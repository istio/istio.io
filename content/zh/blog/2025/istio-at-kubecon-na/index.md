---

title: "Istio 在 KubeCon + CloudNativeCon 北美 2025：充满动力、社区和里程碑的一周"
description: "来自亚特兰大 Istio Day 和 KubeCon 北美 2025 的亮点。"
publishdate: 2025-11-25
attribution: "Faseela K，代表 Istio 社区委员会; Translated by Wilson Wu (DaoCloud)"
keywords: ["Istio", "KubeCon", "service mesh", "Ambient Mesh", "Gateway API"]

---

{{< image width="75%" link="./kubecon-opening.jpg" caption="Istio 在 KubeCon 北美 2025" >}}

KubeCon + CloudNativeCon 北美 2025 于 **11 月 10 日至 13 日** 点亮了亚特兰大，
汇聚了云原生生态系统中最大的开源从业者、平台工程师和维护者群体之一。
对于 Istio 社区而言，这一周的特点是座无虚席的会议室、长时间的走廊交谈，
以及在服务网格、Gateway API、安全性和 AI 驱动平台方面取得的真正共同进步感。

在主会议开始之前，社区于 **11 月 10 日举办了 Istio Day**，
这是一个同场活动，充满了深度的技术会议、迁移故事和面向未来的讨论，为本周剩下的时间定下了基调。

## KubeCon 北美期间的 Istio Day {#istio-day-at-kubecon-na}

Istio Day 汇聚了从业者、贡献者和采用者，共同度过了一个下午的学习、
分享和公开对话，探讨服务网格以及 Istio 的下一步发展方向。

{{< image width="75%" link="./istioday-opening.jpg" caption="Istio Day：北美" >}}

Istio Day 以来自 Solo.io 的 John Howard 和来自 Microsoft 的 Keith Mattix
的[欢迎致辞 + 开幕词](https://www.youtube.com/watch?v=f5BxnlFgToQ)拉开帷幕，
为专注于现实世界网格演进和 Istio 社区日益增长的活力的下午定下了基调。

这一天很快进入了应用 AI 领域，John Howard 在[你的服务网格准备好迎接 AI 了吗？](https://www.youtube.com/watch?v=4ynwGx1QH5I)
中探讨了流量管理、安全性和可观测性如何塑造生产级 AI 工作负载。

{{< image width="75%" link="./istioday-talk.jpg" caption="Istio Day：你的服务网格准备好迎接 AI 了吗" >}}

随着 Jackie Maertens 和 Steven Jin Xuan 带来的
[Istio Ambient 走向多集群](https://www.youtube.com/watch?v=7dT2O8Bnvyo)，
势头得以延续，他们演示了 Ambient 网格在分布式集群中的行为——重点介绍了多集群部署中的身份、连接性和运维简化。

来自 Red Hat 的 Francisco Herrera Lira
在闪电演讲[验证您的 Istio 设置？测试已经写好了](https://www.youtube.com/watch?v=ViUMfYzc8o0)中带来了一股活力，
展示了内置验证工具如何在常见配置问题进入生产环境之前捕获它们。

在[优化 Istio 自动扩缩：从以资源为中心到连接感知](https://www.youtube.com/watch?v=wHvS_h7FBv4)中，
Punakshi Chaand 和 Pankaj Sikka 分享了 Intuit
如何通过根据连接模式而不是原始资源指标调整自动缩放行为来提高可靠性。

接下来，来自 GEICO Tech 的 Tyler Schade 和 Michael Bolot
的[在 Istio 的服务网格中运行数据库](https://www.youtube.com/watch?v=3Jy9VKWgHww)挑战了长期以来的假设，
提供了在网格中保护和运行有状态工作负载的实用经验。

随着 Solo.io 的 Lin Sun 和 Harri 的 Ahmad Al-Masry
介绍了[零停机迁移可能吗？从 Ingress 和 Sidecar 迁移到 Gateway API](https://www.youtube.com/watch?v=J0SEOc6M35E)，
现代化流量入口占据了舞台，重点介绍了避免架构转变期间中断的渐进式迁移策略。

最后的会议，[Credit Karma 的 Istio 迁移：50k+ Pod，最小影响，经验教训](https://www.youtube.com/watch?v=OjT4NmO5MvM)，
见证了 Sumit Vij 和 Mark Gergely 概述了他们如何通过谨慎的自动化和发布纪律执行迄今为止最大的 Istio 迁移之一。

这一天以[John Howard 和 Keith Mattix 的致辞](https://www.youtube.com/watch?v=KU30VVnoAf0)结束，
庆祝演讲者、贡献者以及不断推动 Istio 可能性边界的社区。

## KubeCon 主会议上的 Istio {#istio-at-the-main-kubecon-conference}

除了 Istio Day 之外，本项目在 KubeCon 上也非常引人注目，维护者、
最终用户和贡献者分享了技术深度剖析、生产故事和前沿研究。

这次 KubeCon 对 Istio 社区来说意义非凡，因为 Istio 不仅出现在展台和分组会议中，
还贯穿了多个 KubeCon 主题演讲，各公司展示了 Istio 如何在通过规模化支持其平台方面发挥关键作用。

{{< image width="75%" link="./istio-at-keynotes.png" caption="KubeCon 主题演讲中的 Istio" >}}

当 Istio 社区在 [Istio 项目更新](https://www.youtube.com/watch?v=vdCMLZ-4vUo)中重新集结时，
本周的势头达到了顶峰，项目负责人分享了最新版本、路线图进展，
以及 Istio 如何满足 AI 工作负载、多集群网格和运维规模方面的新兴需求。

在 [Istio：无 Sidecar 的 Istio 启航](https://www.youtube.com/watch?v=SwB7W8g9r6I)中，
与会者探讨了无 Sidecar 的 Ambient 网格架构如何迅速从实验走向应用，
为更简单的部署和更精简的数据平面开辟了新的可能性。

议题[构建下一代 AI 代理的应用经验](https://www.youtube.com/watch?v=qa5vSE86z-s&pp=0gcJCRUKAYcqIYzv)带领观众深入幕后，
了解网格技术如何适应 AI 驱动的流量模式 - 不仅将网格应用于服务，
还应用于模型服务、推理和数据流。

在 **Istio DaemonSet 工作负载的自动调整大小（海报议题）**上，
从业者聚集在一起比较优化控制平面资源、针对大规模进行调整以及在不牺牲性能的情况下降低成本的策略。

流量管理演变的叙述在 [Gateway API：基本要求](https://www.youtube.com/watch?v=RWFDjA6ZeWc)及其更快的兄弟篇[出发前须知！Gateway API 极速入门](https://www.youtube.com/watch?v=Cd0hGGydUGo)中占据了显著位置。
这些议题提出了通往现代 Ingress 和网格控制的基础和入门路径。

与此同时，[网格的回归：Gateway API 寻求统一的史诗探索](https://www.youtube.com/watch?v=tgs6Wq5UlBs)扩展了这一对话：
流量、API、网格和路由如何汇聚成一个架构，从而简化复杂性而不是成倍增加。

关于长期反思，[构建 Kgateway 8 年来的 5 个关键教训](https://www.youtube.com/watch?v=G3Iu2ezSkVE)传达了多年系统设计、
重构和迭代改进中来之不易的智慧。

在 [GAMMA 实战：Careem 如何无停机迁移到 Istio](https://www.youtube.com/watch?v=igJXmbwMYAc&pp=0gcJCRUKAYcqIYzv) 中，
真实的迁移故事 - 一个在过渡期间保持正常运行的主要生产发布——为寻求大规模安全网格采用的团队提供了路线图。

安全和发布风险在[驯服分布式 Web 应用程序中的发布风险：位置感知的渐进式部署方法](https://www.youtube.com/watch?v=-fhXEJD-ycs)中占据了中心舞台，
其中列出了区域发布、流量引导和最小化用户影响的策略。

最后，运维和第二天现实在 [Kubernetes 中使用 gRPC 的端到端安全性](https://www.youtube.com/watch?v=fhjiLyntYBg)和[使用代理轻松待命](https://www.youtube.com/watch?v=oDli4CBkky8)中得到了解决，
提醒大家网格不仅仅是关于架构，更是关于团队如何安全、可靠和自信地运行软件。

## 社区空间：ContribFest、维护者专区和项目展馆 {#community-spaces-contribfest-maintainer-track-the-project-pavilion}

在项目展馆，Istio 展台总是熙熙攘攘，
吸引了询问有关 Ambient 网格、AI 工作负载和部署最佳实践的用户。

{{< image width="75%" link="./istio-kiosk.png" caption="Istio 项目展馆" >}}

维护者专区将贡献者聚集在一起，共同探讨路线图主题、问题分类和来年重点投资领域。

{{< image width="75%" link="./istio-contributors.jpg" caption="Istio 维护者" >}}

在 ContribFest 上，新贡献者加入维护者行列，
共同解决适合初学者的问题，讨论贡献途径，并准备好他们的第一个 PR。

{{< image width="75%" link="./istio-contribfest.png" caption="Istio ContribFest 协作" >}}

## Istio 维护者在 CNCF 社区奖项中获得表彰 {#istio-maintainers-recognized-at-the-cncf-community-awards}

今年的 [CNCF 社区奖项](https://www.cncf.io/announcements/2025/11/12/cncf-honors-innovators-and-defenders-with-2025-community-awards-at-kubecon-cloudnativecon-north-america/)是该项目值得骄傲的时刻。
两位 Istio 维护者获得了当之无愧的认可：

* John Howard — 顶级提交者奖
* Daniel Hawton — “劈柴挑水”奖

{{< image width="75%" link="./cncf-awards.png" caption="CNCF 社区奖项中的 Istio" >}}

除了这些奖项，Istio 在会议领导层中也有显著代表。
Faseela K，KubeCon 北美联合主席之一兼 Istio 维护者，
参加了关于 [Cloud Native for Good](https://youtu.be/1iFYEWx2zC8?si=JUa-8fwtYe5IefE7)
的主题演讲小组讨论。

在闭幕致辞中，还宣布另一位长期 Istio 维护者 Lin Sun 将担任即将到来的 KubeCon 联合主席，
突显了该项目在 CNCF 内部强大的领导力。

{{< image width="75%" link="./kubecon-co-chairs.jpg" caption="主题演讲舞台上的 Istio 领导层" >}}

## 我们在亚特兰大听到了什么 {#what-we-heard-in-atlanta}

在会议、展台和走廊中，出现了一些主题：

* Ambient 网格正从探索转向实际应用。
* AI 工作负载正在推动网格流量模式和运维实践的创新。
* 多集群部署正变得司空见惯，人们关注身份、控制和故障转移。
* Gateway API 正在巩固其作为现代流量管理核心工具的地位。
* 在 ContribFest、实践指导和社区参与的支持下，新贡献者正在大量加入。

## 展望未来 {#looking-ahead}

KubeCon 北美 2025 展示了一个充满活力、不断发展并正在解决现代云基础设施中一些最困难挑战的社区——从
AI 流量管理到零停机迁移，从扩展全球控制平面到构建下一代无 Sidecar 网格。

当我们展望 2026 年时，来自亚特兰大的能量给了我们信心：
服务网格的未来是光明的，Istio 社区正在共同引领潮流。

{{< image width="75%" link="./kubecon-eu-2026.png" caption="阿姆斯特丹见" >}}
