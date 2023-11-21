---
title: "KubeCon 2023 北美站中的 Istio"
description: 快速回顾在芝加哥麦考密克展览中心举行的 KubeCon 北美站中的 Istio。
publishdate: 2023-11-16
attribution: "Faseela K，代表 Istio Day 计划委员会; Translated by Wilson Wu (DaoCloud)"
keywords: [Istio Day,IstioCon,Istio,conference,KubeCon,CloudNativeCon]
---

开源与云原生社区于 11 月 6 日至 9 日齐聚芝加哥，参加 2023 年最后一次 KubeCon。
这次由云原生计算基金会组织的为期四天的会议对 Istio 来说具有“双倍乐趣”，
因为我们已经从 4 月份在欧洲举行的半天活动发展为全天的同场活动。
更令人兴奋的是，北美 Istio Day 代表了我们作为 CNCF 毕业项目举行的第一次活动。

随着 Istio Day 北美站的结束，我们在 2023 年的主要社区活动就此告一段落。
诚邀您回顾，于 4 月举行的 [Istio Day 欧洲站](/zh/blog/2023/istio-at-kubecon-eu/)，
以及[虚拟 IstioCon 2023](https://events.istio.io/) 活动，
于 9 月 26 日在中国上海举行的 [IstioCon 2023 中国站](/zh/blog/2023/istiocon-china/)。

{{< image width="75%"
    link="./welcome.jpg"
    alt="Istio Day 2023 北美站欢迎标志"
    >}}

Istio Day 活动以程序委员会主席 Faseela K 和 Zack Butcher 的开幕主题演讲拉开帷幕。
在主题演讲中认可了我们的贡献者、维护者、发布经理和用户的日常努力，
并为我们的顶级贡献者和社区帮助者颁发了一些奖项。
Rob Salmond 和 Andrea Ma 因其在 Istio 社区的无私努力而获得认可，
过去 6 个月的前 20 名贡献者也被评选出来。

{{< image width="75%"
    link="./top-contributors-1.jpg"
    caption="前 20 位贡献者中的出席者被邀请上台"
    >}}

在开幕主题演讲中还宣布推出了
[Istio Certified Associate (ICA) 考试](https://www.cncf.io/blog/2023/11/06/introducing-the-istio-certified-associate-ica-certification-for-microservices-management/)，
并于 11 月 6 日起开放注册。

{{< image width="75%"
    link="./ica.jpg"
    alt="Istio Certified Associate (ICA)：立即注册！"
    >}}

我们还很自豪地展示了许多贡献者、供应商和最终用户祝贺我们从 CNCF 毕业的视频！

<div style="text-align: center;">
<iframe width="560" height="315" src="https://www.youtube.com/embed/c5baPkXZEMU" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
</div>

主题演讲之后是来自 DevRev 的
[Kush Trivedi 和 Khushboo Mittal 的最终用户演讲](https://www.youtube.com/watch?v=Uk0k8uhdyaA)，
讲述他们对 Istio 的使用情况。我们举行了一场期待已久的关于[规模化 Ambient 架构](https://www.youtube.com/watch?v=S39yo6ZJ4iM)的会议，
由 John Howard 主持，这在社区中引发了一些有趣的讨论。
我们还进行了一场有趣的演讲，展示了 Lilt 和 Intel
之间关于[使用 Istio 扩展人工智能驱动的翻译服务](https://www.youtube.com/watch?v=jFJyLbHros0)的合作。

此后，我们进入了另一场[来自 Intuit 的最终用户演讲](https://www.youtube.com/watch?v=Xe38vEygOqk)，
其中 Karim Lakhani 解释了 Intuit 的现代 SaaS 平台部署的多个包括 Istio 在内的云原生项目。
当 Mitch Connors 和 Christian Hernandez
在实时公共站点上使用可公开访问的可用性监控进行[使用 Argo 升级 Istio Ambient 网格的现场演示](https://www.youtube.com/watch?v=o71PJAqy4P8)时，观众们非常兴奋。

{{< image width="75%"
    link="./istioday-session-1.jpg"
    caption="Istio Day 的丰富会议内容"
    >}}

在随后与来自 Microsoft 的 Jackie Elliot 的更加关注安全性的会谈活动中，
深入研究了 [Istio 身份](https://www.youtube.com/watch?v=QjmUDNXyckQ)，
随后在来自 Speedscale 的 Kush Mansing 进行的闪电演讲中，
展示了在 Istio 中[使用肆意代码运行服务带来的影响](https://www.youtube.com/watch?v=G6Y9JLnej0o)。
我们接着进行了[来自 Xiangfeng Zhu 的闪电演讲](https://www.youtube.com/watch?v=lHUXvtSWdtQ)，
他是来自华盛顿大学的博士生，在演讲中展示了一种用于分析和预测 Istio 性能开销的工具 。

来自 Kiali 的维护者 Jay Shaughnessy 和 Nick Fox 的[演讲](https://www.youtube.com/watch?v=MX-Sym2EkGI)非常有趣，
其中演示了许多使用 Kiali 高级方法更好地对 Istio 进行调试的用例。
来自 Zeta 的 Ekansh Gupta 和来自 Reskill 的 Nirupama Singh
发表了另一场[最终用户演讲，解释了在生产部署中升级 Istio 时的最佳实践](https://www.youtube.com/watch?v=dl0sESwwm9c)。

Istio 多集群始终是一个热门话题，来自 AWS 的 Lukonde Mwila 和 Ovidiu
在[桥接多集群网格之间的信任](https://www.youtube.com/watch?v=FIVmVIJlLVw)演讲中明确了这一点。

我们还与 [Istio TOC 成员进行了互动小组讨论](https://www.youtube.com/watch?v=PEUiL2BPXds)，
观众提出了很多问题，讨论的高出席率证明了 Istio 的持续受欢迎程度。
由来自 Solo.io 的 Christian Posta 和 Jim Barton
带来的所有观众都很期待的热门话题[关于 Ambient 网格入门的精彩研讨会](https://www.youtube.com/watch?v=SyjBSM-3dOY)为本次 Istio Day 画上一个句号。

所有会议的幻灯片都可以在
[Istio Day 2023 北美站时间表](https://events.linuxfoundation.org/kubecon-cloudnativecon-north-america/co-located-events/istio-day/#thank-you-for-attending)中找到。

{{< image width="75%"
    link="./istioday-session-2.jpg"
    caption="来自 DevRev 的 Kush Trivedi 和 Khushboo Mittal 在展台上"
    >}}

我们在会议中的展示并没有随着 Istio Day 的闭幕而结束。
KubeCon + CloudNativeCon 第一天的主题演讲以 Mitch Connors 的项目更新视频开始。
对我们来说，一个值得骄傲的时刻是，我们的两位贡献者 Lin Sun 和 Faseela K
荣获了由 CNCF 首席技术官 Chris Aniszczyk 在第二天的主题演讲中颁发的 CNCF 社区著名的
["Chop Wood Carry Water" 奖](https://www.cncf.io/announcements/2023/11/08/cloud-native-computing-foundation-announces-2023-community-awards-winners/)。

{{< image width="75%"
    link="./chop-wood-carry-water.jpg"
    caption="Chop Wood Carry Water 奖获得者 Faseela K 和 Lin Sun（左二、三）"
    >}}

我们的一些维护者和贡献者也进入了 CNCF 2023 年秋季大使名单，
例如 Lin Sun、Mitch Connors 和 Faseela K 等。

{{< image width="75%"
    link="./cncf-ambassadors.jpg"
    caption="CNCF 大使合影。许多 Istio 维护者都在这张照片中！"
    >}}

[Istio KubeCon 维护者跟踪会议](https://sched.co/1R2tA) 由 TOC 成员 John Howard 和 Louis Ryan 主持，
他们谈论了 Istio 当前正在进行的工作和未来路线图，引起了极大关注。
演讲中描述的技术以及由此产生的听众规模，强调了为什么 Istio 仍然是业界最受欢迎的服务网格。

{{< image width="75%"
    link="./maintainer-track.jpg"
    alt="KubeCon 2023 北美站上的 Istio 维护者跟踪会议"
    >}}

由 Lin Sun、Eric Van Norman、Steven Landow 和 Faseela K 主持的
[Contribfest 实践开发与贡献研讨会](https://sched.co/1R2q7/)也广受好评。
很高兴看到这么多人有兴趣为 Istio 做出贡献并在研讨会结束时提出他们的第一个 PR。

{{< image width="75%"
    link="./contrib-fest.jpg"
    alt="KubeCon 2023 北美站中的 Istio Contribfest 研讨会"
    >}}

由来自三个 CNCF 服务网格项目的维护者共同主持的备受期待的关于[服务网格之战的伤痕：技术、时机和权衡](https://sched.co/1R2ts)的小组讨论吸引了大批观众，
并产生了很多有趣的讨论。

{{< image width="75%"
    link="./servicemesh-battle-scars-panel.jpg"
    alt="KubeCon 2023 北美站中的服务网格之战的伤痕小组"
    >}}

在其他几场 KubeCon 演讲中，Istio 也成为了讨论的热门话题。
以下是我们注意到的一些内容：

* [走向边缘：使用 Istio 和 K8gb 创建全球分布式入口](https://sched.co/1R2o5/)
* [幕后花絮：探索 Istio 的锁争用及其对 Expedia 计算平台的影响](https://sched.co/1R2uV)
* [通过功能门控理清服务网格](https://sched.co/1R2v6)
* [服务网格中的证书风格：原因和方法！](https://sched.co/1R2wC)

Istio 在项目展馆设有一个展亭，被询问的大多数问题都与 Ambient 网格生产准备就绪的时间表有关。

{{< image width="75%"
    link="./istio-booth-1.jpg"
    caption="在 Istio 展亭进行讨论"
    >}}

我们很高兴看到在欧洲 Istio 展亭被提出的主要问题 —— CNCF 毕业时间表已经得到解答，
并且我们向所有人保证，我们正在以同样的认真态度致力于 Ambient 网格。

许多成员和维护者在我们的展亭提供了支持，帮助我们回答用户的所有问题。

{{< image width="75%"
    link="./istio-booth-2.jpg"
    caption="Istio 展亭的成员和维护者"
    >}}

我们展亭的另一个亮点是，我们有由 Microsoft、Solo.io、
Stackgenie 和 Tetrate 赞助的新款 Istio T 恤供大家购买！

{{< image width="75%"
    link="./istio-t-shirts.jpg"
    caption="新款 Istio T 恤"
    >}}

衷心感谢我们的白金赞助商 Google Cloud 对北美 Istio Day 的支持！
最后且重要的一点是，我们要感谢 Istio Day 计划委员会成员的辛勤工作和支持！

[2024 年 3 月巴黎见！](https://events.linuxfoundation.org/kubecon-cloudnativecon-europe/co-located-events/istio-day/)

{{< image width="100%"
    link="./istio-day-paris.jpg"
    alt="Istio Day 2024 欧洲站"
    >}}
