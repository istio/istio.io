---
title: "2023 北美 KubeCon 上的 Istio 风采"
description: 快速回顾在芝加哥麦考密克展览中心举行的北美 KubeCon 中的 Istio 风采。
publishdate: 2023-11-16
attribution: "Faseela K，代表 Istio Day 计划委员会; Translated by Wilson Wu (DaoCloud)"
keywords: [Istio Day,IstioCon,Istio,conference,KubeCon,CloudNativeCon]
---

开源与云原生社区于 11 月 6 日至 9 日齐聚芝加哥，参加 2023 年最后一次 KubeCon。
这次为期四天的大会由云原生计算基金会举办，对 Istio 而言可谓是“双喜临门”，
第一个喜讯是从 4 月份在欧洲的半天活动发展为一个全天的同场活动。
另一个令人振奋的喜讯是，北美 Istio Day 是 Istio 作为 CNCF 项目毕业后举办的第一场活动。

随着北美 Istio Day 落幕，2023 年 Istio 社区的重大活动也就此告一段落。
若您想重温展会风采，请查阅 4 月份举办的[欧洲 Istio Day](/zh/blog/2023/istio-at-kubecon-eu/)、
[2023 虚拟 IstioCon](https://events.istio.io/) 活动以及于
9 月 26 日在中国上海举办的[2023 中国 IstioCon](/zh/blog/2023/istiocon-china/)。

{{< image width="75%"
    link="./welcome.jpg"
    alt="2023 北美 Istio Day 欢迎标牌"
    >}}

Istio Day 活动以 Program Committee（程序委员会）主席 Faseela K 和 Zack Butcher 的开幕致辞拉开帷幕。
两位主席首先肯定并认可了所有社区贡献者、维护者、发布经理以及用户们所完成的日常工作，
并为 Istio 最杰出的贡献者和社区大咖们颁发了一些奖项。
Rob Salmond 和 Andrea Ma 因其在 Istio 社区做出的无私贡献而得享赞誉，
过去 6 个月中的前 20 名贡献者也被点名表扬。

{{< image width="75%"
    link="./top-contributors-1.jpg"
    caption="排名前 20 并出席本次活动受邀上台的贡献者们"
    >}}

在开幕致辞中还宣布推出了
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

开幕致辞之后是来自 DevRev 的
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

此次活动在随后的演讲中更加关注安全性，首先是来自 Microsoft 的 Jackie Elliot
深入研究了 [Istio 身份认证](https://www.youtube.com/watch?v=QjmUDNXyckQ)，
随后在来自 Speedscale 的 Kush Mansing 进行的闪电演讲中，
展示了在 Istio 中[使用任意代码运行服务带来的影响](https://www.youtube.com/watch?v=G6Y9JLnej0o)。
我们还有来自 University of Washington 的博士生 Xiangfeng Zhu 的[闪电演讲](https://www.youtube.com/watch?v=lHUXvtSWdtQ)，
他在其中展示了一个用于分析和预测 Istio 的性能开销的工具。

来自 Kiali 的维护者 Jay Shaughnessy 和 Nick Fox 的[演讲](https://www.youtube.com/watch?v=MX-Sym2EkGI)非常有趣，
因为它展示了许多使用 Kiali 进行更好的 Istio 用例调试的高级方法。
来自 Zeta 的 Ekansh Gupta 和来自 Reskill 的 Nirupama Singh
发表了另一场[最终用户演讲，解释了在生产部署中升级 Istio 的最佳实践](https://www.youtube.com/watch?v=dl0sESwwm9c)。

Istio 多集群始终是一个热门话题，来自 AWS 的 Lukonde Mwila 和 Ovidiu
在[桥接多集群网格之间的信任](https://www.youtube.com/watch?v=FIVmVIJlLVw)演讲中明确了这一点。

我们还与 [Istio TOC 成员进行了互动小组讨论](https://www.youtube.com/watch?v=PEUiL2BPXds)，
观众提出了很多问题，讨论的高出席率证明了 Istio 的持续受欢迎程度。
由来自 Solo.io 的 Christian Posta 和 Jim Barton
带来的所有观众都很期待的热门话题[关于 Ambient 网格入门的精彩研讨会](https://www.youtube.com/watch?v=SyjBSM-3dOY)为本次 Istio Day 画上一个句号。

所有会议的幻灯片都可以在
[2023 北美 Istio Day 日程表](https://events.linuxfoundation.org/kubecon-cloudnativecon-north-america/co-located-events/istio-day/#thank-you-for-attending)中找到。

{{< image width="75%"
    link="./istioday-session-2.jpg"
    caption="来自 DevRev 的 Kush Trivedi 和 Khushboo Mittal 在展台上"
    >}}

Istio 在本次 KubeCon 上的风采并未随着 Istio Day 的闭幕而结束。
KubeCon + CloudNativeCon 第一天的主题演讲首秀是来自 Mitch Connors 的一个项目更新视频。
这也是 Istio 的一个高光时刻，我们的两位贡献者 Lin Sun 和 Faseela K
荣获了由 CNCF 首席技术官 Chris Aniszczyk 在第二天的主题演讲中颁发的 CNCF 社区著名的
["Chop Wood Carry Water" 奖](https://www.cncf.io/announcements/2023/11/08/cloud-native-computing-foundation-announces-2023-community-awards-winners/)。

{{< image width="75%"
    link="./chop-wood-carry-water.jpg"
    caption="Chop Wood Carry Water 奖获得者 Faseela K 和 Lin Sun（左二、左三）"
    >}}

我们的一些维护者和贡献者也入选了 CNCF 2023 年秋季大使名单，
例如 Lin Sun、Mitch Connors 和 Faseela K 等。

{{< image width="75%"
    link="./cncf-ambassadors.jpg"
    caption="CNCF 大使合影。许多 Istio 维护者都在这张照片中！"
    >}}

指导委员会（TOC）成员 John Howard 和 Louis Ryan 主持的 [Istio KubeCon 维护者跟踪会议](https://sched.co/1R2tA)广受关注，
会上他们谈论了 Istio 当前正在进行的工作和未来的技术路线图。
阐述了 Istio 所采用的技术、受众规模，强调了为什么 Istio 是业界持续最受欢迎的服务网格。

{{< image width="75%"
    link="./maintainer-track.jpg"
    alt="2023 北美 KubeCon 上的 Istio 维护者跟踪会议"
    >}}

由 Lin Sun、Eric Van Norman、Steven Landow 和 Faseela K 主持的
[Contribfest 实践开发与贡献研讨会](https://sched.co/1R2q7/)也广受好评。
很高兴看到这么多人有兴趣为 Istio 做出贡献并在研讨会结束时提出他们的第一个 PR。

{{< image width="75%"
    link="./contrib-fest.jpg"
    alt="2023 北美 KubeCon 上的 Contribfest Istio 研讨会"
    >}}

来自三个 CNCF 服务网格项目的维护者们牵头主持了备受期待的[服务网格战痕：技术、时机和权衡](https://sched.co/1R2ts)小组讨论，吸引了大批观众，
并进行了很多有趣的讨论。

{{< image width="75%"
    link="./servicemesh-battle-scars-panel.jpg"
    alt="2023 北美 KubeCon 中的服务网格之战伤痕小组"
    >}}

在其他几场 KubeCon 演讲中，Istio 也成为了讨论的热门话题。
以下是我们注意到的一些内容：

* [走向边缘：使用 Istio 和 K8gb 创建全球分布式入口](https://sched.co/1R2o5/)
* [幕后花絮：探索 Istio 的锁争用及其对 Expedia 计算平台的影响](https://sched.co/1R2uV)
* [通过功能门控理清服务网格](https://sched.co/1R2v6)
* [服务网格中的证书风格：原因和方法！](https://sched.co/1R2wC)

Istio 在项目展馆设有一个展台，大多数问题都围绕着 Ambient 何时准备好投入生产。

{{< image width="75%"
    link="./istio-booth-1.jpg"
    caption="在 Istio 展台讨论"
    >}}

我们很高兴看到在欧洲 Istio 展亭被提出的主要问题 —— CNCF 毕业时间表已经得到解答，
并且我们向所有人保证，我们正在以同样的认真态度致力于 Ambient 网格。

许多成员和维护者在我们的展亭提供了支持，帮助我们回答用户的所有问题。

{{< image width="75%"
    link="./istio-booth-2.jpg"
    caption="Istio 展台的成员和维护者们"
    >}}

Istio 展台的另一个亮点是由 Microsoft、Solo.io、
Stackgenie 和 Tetrate 赞助的、供大家免费领取的新款 Istio T 恤！

{{< image width="75%"
    link="./istio-t-shirts.jpg"
    caption="新款 Istio T 恤"
    >}}

衷心感谢我们的白金赞助商 Google Cloud 对北美 Istio Day 的支持！
最后且重要的一点是，我们要感谢 Istio Day 程序委员会成员，感谢他们的辛勤工作和支持！

[2024 年 3 月巴黎见！](https://events.linuxfoundation.org/kubecon-cloudnativecon-europe/co-located-events/istio-day/)

{{< image width="100%"
    link="./istio-day-paris.jpg"
    alt="2024 欧洲 Istio Day"
    >}}
