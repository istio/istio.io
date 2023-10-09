---
title: "IstioCon China 2023 总结"
description: 简要回顾上海 KubeCon + CloudNativeCon + Open Source Summit China 中的 Istio 主题演讲。
publishdate: 2023-09-29
attribution: "IstioCon 2023 中国站程序委员会; Translated by Wilson Wu (DaoCloud)"
keywords: [Istio Day,IstioCon,Istio,conference,KubeCon,CloudNativeCon]
---

经过两年时间只举办虚拟活动后，能够再次线下欢聚一堂真是太好了！
我们的活动已经排满了 2023 年的日历。
[Istio Day 欧洲站](/zh/blog/2023/istio-at-kubecon-eu/)于 4 月举行，
[Istio Day 北美站](https://events.linuxfoundation.org/kubecon-cloudnativecon-north-america/co-located-events/istio-day/)将于今年 11 月举行。

IstioCon 致力于打造行业领先的服务网格，
提供一个平台来探索从现实世界的 Istio 部署中获得的见解、
参与交互式实践活动，并与整个 Istio 生态系统的维护者进行交流。

除了 [IstioCon 2023 虚拟](https://events.istio.io/)活动之外，
[IstioCon 2023 中国站](https://www.lfasiallc.com/kubecon-cloudnativecon-open-source-summit-china/co-located-events/istiocon-cn/)也于 9 月 26 日在中国上海举行。
该活动是 KubeCon + CloudNativeCon + Open Source Summit China 的一部分，
由 Istio 维护者和 CNCF 安排和主办。
我们非常自豪能够在上海举办如此盛大的 IstioCon 活动，
并很高兴将中国 Istio 社区的成员聚集在一起。
此次活动展示了 Istio 在亚太生态系统中深受开发者和用户的欢迎。

{{< image link="./group-pic.jpg"
    caption="IstioCon 2023 中国站"
    >}}

IstioCon 中国站在程序委员会成员宋净超和徐中虎的开幕主题演讲中拉开帷幕。
此次活动内容丰富，从新功能到最终用户演讲，
主要关注新的 Istio Ambient 网格。

{{< image width="75%"
    link="./opening-keynote.jpg"
    caption="欢迎来到 IstioCon 2023 中国站"
    >}}

欢迎致辞之后，来自 Google 的 Justin Pettit 发表了主题演讲，
主题为“Istio Ambient Mesh 作为托管基础设施”，
强调了 Ambient 模式在 Istio 社区中的重要性和优先级，
特别是对于像 Google Cloud 这样的我们的顶级支持者。

{{< image width="75%"
    link="./sponsored-keynote-google.jpg"
    caption="IstioCon 2023 中国站，Google Cloud 赞助的主题演讲"
    >}}

主题演讲结束后，英特尔的张怀龙和阿里巴巴的曾宇星讨论了
Ambient 和 Sidecar 共存的配置：对于想要尝试新
Ambient 模式的现有用户来说，这是一个非常相关的主题。

{{< image width="75%"
    link="./ambient-l4.jpg"
    caption="IstioCon 2023 中国站，深入研究 Istio 网络流程和配置以实现 Ambient 和 Sidecar 的共存"
    >}}

华为基于 eBPF 的新 Istio 数据平面打算在内核中实现
L4 和 L7 的能力，避免内核态和用户态切换，降低数据平面的延迟。
通过谢颂杨和徐中虎的一段有趣的谈话解释了这一点。
来自英特尔的李纯和丁少君还将 eBPF 与 Istio 集成，
他们的演讲“在 Istio Ambient 模式中利用 eBPF 进行流量重定向”引发了更有趣的讨论。
DaoCloud 也出席了此次活动，刘齐均分享了 Merbridge 在 eBPF 方面的创新，
韩小鹏则介绍了用于本地化 Istio 开发的 MirageDebug。

{{< image width="75%"
    link="./users-engaging.jpg"
    alt="与参与者互动"
    >}}

Tetrate 的宋净超关于不同 GitOps 和可观测性工具的完美结合演讲也很受欢迎。
来自华为的张超盟介绍了 cert-manager 如何帮助增强 Istio
证书管理系统的安全性和灵活性，来自阿里云的王夕宁和史泽寰分享了使用
VK（Virtual Kubelet）实现 Serverless Mesh 的想法。

Shivanshu Raj Shrivastava 通过“使用 Wasm 扩展和定制 Istio”
的演讲对 WebAssembly 进行了完美的介绍，来自印度尼西亚
GoTo Financial 的 Zufar Dhiyaulhaq 分享了使用 Coraza Proxy Wasm 扩展 Envoy
并快速实现自定义 Web 应用防火墙的实践。Tetrate 的赵化冰与
Boss 直聘的覃士林分享了 Aeraki Mesh 的 Dubbo 服务治理实践。
然而多租户一直是 Istio 的热门话题，来自 HP 的郑风详细介绍了
HP OneCloud 平台中的多租户管理。

所有会议的幻灯片都可以在
[IstioCon 2023 中国站日程安排](https://istioconchina2023.sched.com/)中找到，
所有演讲将很快在 CNCF YouTube 频道上为全世界其他地区的观众提供。

## 在展会现场 {#on-the-show-floor}

Istio 在 2023 年 KubeCon + CloudNativeCon + Open Source Summit China
的活动展馆设有专门展亭，大部分问题都围绕 Ambient 网格提出。
我们的许多会员和维护者在展位上提供了支持，并发生了很多有趣的讨论。

{{< image width="75%"
    link="./istio-support-at-the-booth.jpg"
    caption="2023 年 KubeCon + CloudNativeCon + Open Source Summit China，Istio 展亭"
    >}}

另一个亮点是 Istio 指导委员会成员以及 Istio 书籍
《云原生服务网格 Istio》以及《Istio：权威指南》的作者徐中虎和张超盟在
Istio 展位与我们的用户和贡献者进行了互动。

{{< image width="75%"
    link="./meet-the-authors.jpg"
    caption="认识作者"
    >}}

我们衷心感谢我们的钻石赞助商 Google Cloud 对 IstioCon 2023 的支持！

{{< image width="40%"
    link="./diamond-sponsor.jpg"
    caption="IstioCon 2023，我们的钻石赞助商"
    >}}

最后但并非不重要的一点是，我们要感谢 IstioCon
中国程序委员会成员的辛勤工作和支持！

{{< image width="75%"
    link="./istiocon-program-committee.jpg"
    caption="IstioCon 2023 中国站，程序委员会成员（未出现在照片中：丁少君）"
    >}}

[十一月芝加哥见！](https://events.linuxfoundation.org/kubecon-cloudnativecon-north-america/co-located-events/istio-day/)
