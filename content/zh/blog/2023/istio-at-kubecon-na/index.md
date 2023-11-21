---
title: "KubeCon 2023 北美站中的 Istio"
description: 快速回顾在芝加哥麦考密克展览中心举行的 KubeCon 北美站中的 Istio。
publishdate: 2023-11-16
attribution: "Faseela K，代表 Istio Day 计划委员会; Translated by Wilson Wu (DaoCloud)"
keywords: [Istio Day,IstioCon,Istio,conference,KubeCon,CloudNativeCon]
---

The open source and cloud native community gathered from the 6th to the 9th of November in Chicago for the final KubeCon of 2023. The four-day conference, organized by the Cloud Native Computing Foundation, was "twice the fun" for Istio, as we grew from a half-day event in Europe in April to a full day co-located event. To add to the excitement, Istio Day North America marked our first event as a CNCF graduated project.
开源和云原生社区于 11 月 6 日至 9 日齐聚芝加哥，参加 2023 年最后一次 KubeCon。这次由云原生计算基金会组织的为期四天的会议对 Istio 来说是“双倍的乐趣”，因为我们 从四月份在欧洲举行的半天活动发展为全天的同一地点活动。 更令人兴奋的是，北美 Istio Day 标志着我们作为 CNCF 毕业项目的第一次活动。

With Istio Day NA over, that's a wrap for our major community events for 2023. In case you missed them, [Istio Day Europe](/blog/2023/istio-at-kubecon-eu/) was held in April, and alongside our [Virtual IstioCon 2023](https://events.istio.io/) event, [IstioCon China 2023](/blog/2023/istiocon-china/) was held on September 26 in Shanghai, China.
随着 Istio Day NA 的结束，我们 2023 年的主要社区活动就到此结束了。如果您错过了，[Istio Day Europe](/blog/2023/istio-at-kubecon-eu/) 于 4 月举行，同时 我们的[虚拟 IstioCon 2023](https://events.istio.io/) 活动，[IstioCon China 2023](/blog/2023/istiocon-china/) 于 9 月 26 日在中国上海举行。

{{< image width="75%"
    link="./welcome.jpg"
    alt="Istio Day NA 2023 welcome sign"
    >}}
{{< image width="75%"
    link="./welcome.jpg"
    alt="Istio Day 2023 年北美站欢迎标志"
    >}}

Istio Day kicked off with an opening keynote from the Program Committee chairs, Faseela K and Zack Butcher. The keynote made sure to recognize the day-to-day efforts of our contributors, maintainers, release managers, and users, with some awards for our top contributors and community helpers. Rob Salmond and Andrea Ma were recognized for their selfless efforts in the Istio community, and the top 20 contributors in the last 6 months were also called out.
Istio Day 活动以程序委员会主席 Faseela K 和 Zack Butcher 的开幕主题演讲拉开帷幕。 主题演讲确保了对我们的贡献者、维护者、发布经理和用户的日常努力的认可，并为我们的顶级贡献者和社区帮助者颁发了一些奖项。 Rob Salmond 和 Andrea Ma 因其在 Istio 社区的无私努力而获得认可，过去 6 个月的前 20 名贡献者也被评选出来。

{{< image width="75%"
    link="./top-contributors-1.jpg"
    caption="Top 20 contributors who were in attendance were asked to come onto the stage"
    >}}
{{< image width="75%"
    link="./top-contributors-1.jpg"
    caption="前 20 位贡献者中的出席者被邀请上台"
    >}}

The opening keynote also announced the availability of [the Istio Certified Associate (ICA) exam](https://www.cncf.io/blog/2023/11/06/introducing-the-istio-certified-associate-ica-certification-for-microservices-management/) for enrollment starting November 6th.
开幕主题演讲还宣布推出[Istio Certified Associate (ICA) 考试](https://www.cncf.io/blog/2023/11/06/introducing-the-istio-certified-associate-ica-certification -for-microservices-management/) 从 11 月 6 日开始注册。

{{< image width="75%"
    link="./ica.jpg"
    alt="Istio Certified Associate (ICA): enroll now!"
    >}}
{{< image width="75%"
    link="./ica.jpg"
    alt="Istio 认证工程师（ICA）：立即注册！"
    >}}

We were also proud to showcase a small video of many of our contributors, vendors and end-users congratulating us for the CNCF graduation!
我们还很自豪地展示了许多贡献者、供应商和最终用户的小视频，祝贺我们 CNCF 毕业！

<div style="text-align: center;">
<iframe width="560" height="315" src="https://www.youtube.com/embed/c5baPkXZEMU" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
</div>

The keynote was followed by [an end user talk by Kush Trivedi and Khushboo Mittal](https://www.youtube.com/watch?v=Uk0k8uhdyaA) from DevRev about their usage of Istio. We had a much-awaited session on [architecting ambient for scale](https://www.youtube.com/watch?v=S39yo6ZJ4iM) from John Howard, which stirred some interesting discussions in the community. We also had an interesting talk showcasing the collaboration between Lilt and Intel about [Scaling AI powered translation services using Istio](https://www.youtube.com/watch?v=jFJyLbHros0).
主题演讲之后是 DevRev 的 [Kush Trivedi 和 Khushboo Mittal 的最终用户演讲](https://www.youtube.com/watch?v=Uk0k8uhdyaA)，讲述他们对 Istio 的使用情况。 我们举行了一场期待已久的关于 [规模化环境架构](https://www.youtube.com/watch?v=S39yo6ZJ4iM) 的会议，由 John Howard 主持，这在社区中引发了一些有趣的讨论。 我们还进行了一场有趣的演讲，展示了 Lilt 和 Intel 之间关于 [使用 Istio 扩展人工智能驱动的翻译服务](https://www.youtube.com/watch?v=jFJyLbHros0) 的合作。

After this we stepped into another [end user talk from Intuit](https://www.youtube.com/watch?v=Xe38vEygOqk) where Karim Lakhani explained about Intuit’s modern SaaS platform deploying multiple cloud native projects including Istio. The audience was excited when Mitch Connors and Christian Hernandez did [a live demo of upgrading Istio ambient mesh with Argo](https://www.youtube.com/watch?v=o71PJAqy4P8) on a live public site, with a publicly accessible availability monitor.
此后，我们进入了另一场 [Intuit 的最终用户演讲](https://www.youtube.com/watch?v=Xe38vEygOqk)，其中 Karim Lakhani 解释了 Intuit 的现代 SaaS 平台部署了多个云原生项目（包括 Istio）。 当 Mitch Connors 和 Christian Hernandez 在一个可公开访问的实时公共网站上进行 [使用 Argo 升级 Istio 环境网格的现场演示](https://www.youtube.com/watch?v=o71PJAqy4P8) 时，观众们非常兴奋 可用性监视器。

{{< image width="75%"
    link="./istioday-session-1.jpg"
    caption="Jam-packed sessions at Istio Day"
    >}}
{{< image width="75%"
    link="./istioday-session-1.jpg"
    caption="Istio Day 的会议内容丰富"
    >}}

The event witnessed more focus on security in subsequent talks with Jackie Elliot from Microsoft taking a dig into [Istio Identity](https://www.youtube.com/watch?v=QjmUDNXyckQ), followed by a lightning talk from Kush Mansing from Speedscale showing [the impacts of running services with arbitrary code](https://www.youtube.com/watch?v=G6Y9JLnej0o) on Istio. We also had a [lightning talk from Xiangfeng Zhu](https://www.youtube.com/watch?v=lHUXvtSWdtQ), a PhD student at the University of Washington, where he showcased a tool developed to analyze and predict the performance overhead of Istio.
在随后与 Microsoft 的 Jackie Elliot 的会谈中，该活动更加关注安全性，深入研究了 [Istio Identity](https://www.youtube.com/watch?v=QjmUDNXyckQ)，随后来自 Microsoft 的 Kush Mansing 进行了闪电般的演讲 Speedscale 显示 [使用任意代码运行服务的影响](https://www.youtube.com/watch?v=G6Y9JLnej0o) 对 Istio 的影响。 我们还进行了[来自华盛顿大学博士生朱翔峰的闪电演讲](https://www.youtube.com/watch?v=lHUXvtSWdtQ)，他在演讲中展示了一种用于分析和预测性能的工具 Istio 的开销。

The [talk from the Kiali maintainers](https://www.youtube.com/watch?v=MX-Sym2EkGI) Jay Shaughnessy and Nick Fox, was very interesting, as it demonstrated many advanced ways of using Kiali for better debugging of Istio use cases. Ekansh Gupta from Zeta, and Nirupama Singh from Reskill pitched in another [end user talk explaining the best practices while upgrading Istio](https://www.youtube.com/watch?v=dl0sESwwm9c) in their production deployments.
[Kiali 维护者的演讲](https://www.youtube.com/watch?v=MX-Sym2EkGI) Jay Shaughnessy 和 Nick Fox 非常有趣，因为它演示了使用 Kiali 更好地调试的许多高级方法 Istio 用例。 来自 Zeta 的 Ekansh Gupta 和来自 Reskill 的 Nirupama Singh 发表了另一场[最终用户演讲，解释了在生产部署中升级 Istio 时的最佳实践](https://www.youtube.com/watch?v=dl0sESwwm9c)。

Istio multi-cluster is always a hot topic, and Lukonde Mwila and Ovidiu from AWS nailed it in the talk on [bridging trust between multi-cluster meshes](https://www.youtube.com/watch?v=FIVmVIJlLVw).
Istio 多集群始终是一个热门话题，AWS 的 Lukonde Mwila 和 Ovidiu 在[桥接多集群网格之间的信任](https://www.youtube.com/watch?v=FIVmVIJlLVw) 的演讲中明确了这一点。

We also had [an interactive panel discussion with the Istio TOC Members](https://www.youtube.com/watch?v=PEUiL2BPXds), where a lot of questions came in from the audience, and the good attendance for the discussion was a testament to the continued popularity of Istio. Istio Day concluded with [a brilliant workshop on getting started with ambient mesh](https://www.youtube.com/watch?v=SyjBSM-3dOY) from Christian Posta and Jim Barton from Solo.io, which is the hot topic all of the audience were looking forward to.
我们还与 Istio TOC 成员进行了互动小组讨论（https://www.youtube.com/watch?v=PEUiL2BPXds），观众提出了很多问题，讨论的出席率很高 证明了 Istio 的持续受欢迎。 Istio Day 以来自 Christian Posta 和来自 Solo.io 的 Jim Barton 的[关于环境网格入门的精彩研讨会](https://www.youtube.com/watch?v=SyjBSM-3dOY) 结束，这是热门话题 所有观众都很期待。

The slides for all the sessions can be found in the [Istio Day NA 2023 schedule](https://events.linuxfoundation.org/kubecon-cloudnativecon-north-america/co-located-events/istio-day/#thank-you-for-attending).
所有会议的幻灯片都可以在 [Istio Day NA 2023 时间表](https://events.linuxfoundation.org/kubecon-cloudnativecon-north-america/co- located-events/istio-day/#thank- 您参加）。

{{< image width="75%"
    link="./istioday-session-2.jpg"
    caption="Kush Trivedi and Khushboo Mittal from DevRev on stage"
    >}}
{{< image width="75%"
    link="./istioday-session-2.jpg"
    caption="DevRev 的 Kush Trivedi 和 Khushboo Mittal 在舞台上"
    >}}

Our presence at the conference did not end with Istio Day. The first day keynote of KubeCon + CloudNativeCon started with a project update video from Mitch Connors. It was also a proud moment for us, when two of our contributors, Lin Sun and Faseela K, took home the prestigious CNCF community ["Chop Wood Carry Water" award](https://www.cncf.io/announcements/2023/11/08/cloud-native-computing-foundation-announces-2023-community-awards-winners/), presented by Chris Aniszczyk, CTO CNCF, at the second day keynote.
我们参加会议并没有随着 Istio Day 的结束而结束。 KubeCon + CloudNativeCon 第一天的主题演讲以 Mitch Connors 的项目更新视频开始。 这对我们来说也是一个值得骄傲的时刻，我们的两位贡献者 Lin Sun 和 Faseela K 荣获了著名的 CNCF 社区 [“劈柴运水”奖](https://www.cncf.io/announcements/2023 /11/08/cloud-native-computing-foundation-announces-2023-community-awards-winners/)，由 CNCF 首席技术官 Chris Aniszczyk 在第二天的主题演讲中发表。

{{< image width="75%"
    link="./chop-wood-carry-water.jpg"
    caption="Chop Wood Carry Water winners, Faseela K and Lin Sun (second and third from left)"
    >}}
{{< image width="75%"
    link="./chop-wood-carry-water.jpg"
    caption="砍柴挑水冠军 Faseela K 和 Lin Sun（左二、三）"
    >}}

Some of our maintainers and contributors made it to the CNCF Fall 2023 Ambassadors list as well, Lin Sun, Mitch Connors, and Faseela K, to name a few.
我们的一些维护者和贡献者也进入了 CNCF 2023 年秋季大使名单，例如 Lin Sun、Mitch Connors 和 Faseela K 等。

{{< image width="75%"
    link="./cncf-ambassadors.jpg"
    caption="The CNCF Ambassador group photo. Many Istio maintainers are in this picture!"
    >}}
{{< image width="75%"
    link="./cncf-ambassadors.jpg"
    caption="CNCF大使合影。 许多 Istio 维护者都在这张照片中！"
    >}}

[The KubeCon maintainer track session for Istio](https://sched.co/1R2tA), presented by TOC members John Howard and Louis Ryan,  grabbed great attention as they talked about the current ongoing efforts and future roadmap of Istio. The technologies described in the talk, and the resulting size of the audience, underlined why Istio continues to be the most popular service mesh in the industry.
[Istio KubeCon 维护者跟踪会议](https://sched.co/1R2tA) 由 TOC 成员 John Howard 和 Louis Ryan 主持，他们谈论了 Istio 当前正在进行的工作和未来路线图，引起了极大关注。 演讲中描述的技术以及由此产生的听众规模，强调了为什么 Istio 仍然是业界最受欢迎的服务网格。

{{< image width="75%"
    link="./maintainer-track.jpg"
    alt="The Istio maintainer track session at KubeCon NA 2023"
    >}}
{{< image width="75%"
    link="./maintainer-track.jpg"
    alt="KubeCon NA 2023 上的 Istio 维护者跟踪会议"
    >}}

[The Contribfest Hands-on Development and Contribution Workshop](https://sched.co/1R2q7/) by Lin Sun, Eric Van Norman, Steven Landow, and Faseela K was also well received. It was great to see so many people interested in contributing to Istio and pushing their first pull request at the end of the workshop.
Lin Sun、Eric Van Norman、Steven Landow 和 Faseela K 的【Contribfest 实践开发与贡献研讨会】(https://sched.co/1R2q7/) 也受到好评。 很高兴看到这么多人有兴趣为 Istio 做出贡献并在研讨会结束时提出他们的第一个拉取请求。

{{< image width="75%"
    link="./contrib-fest.jpg"
    alt="The Contribfest Istio Workshop at KubeCon NA 2023"
    >}}
{{< image width="75%"
    link="./contrib-fest.jpg"
    alt="KubeCon NA 2023 上的 Contribfest Istio 研讨会"
    >}}

A much-awaited panel discussion on [Service Mesh Battle Scars: Technology, Timing and Tradeoffs](https://sched.co/1R2ts), led by the maintainers from three CNCF Service Mesh projects, had a huge crowd in attendance, and a lot of interesting discussions.
由来自三个 CNCF Service Mesh 项目的维护人员主持的备受期待的关于 [Service Mesh Battle Scars: Technology, Timing and Tradeoffs](https://sched.co/1R2ts) 的小组讨论吸引了大批观众， 很多有趣的讨论。

{{< image width="75%"
    link="./servicemesh-battle-scars-panel.jpg"
    alt="The Service Mesh Battle Scars panel at KubeCon NA 2023"
    >}}
{{< image width="75%"
    link="./servicemesh-battle-scars-panel.jpg"
    alt="KubeCon NA 2023 上的服务网格之战伤痕小组"
    >}}

Istio came up as a hot topic of discussion in several other KubeCon talks as well. Here are a few we noticed:
在其他几场 KubeCon 演讲中，Istio 也成为了讨论的热门话题。 以下是我们注意到的一些内容：

* [Take It to the Edge: Creating a Globally Distributed Ingress with Istio & K8gb](https://sched.co/1R2o5/)
* [Under the Hood: Exploring Istio's Lock Contention and Its Impact on Expedia's Compute Platform](https://sched.co/1R2uV)
* [Untangling Your Service Mesh with Feature Gates](https://sched.co/1R2v6)
* [Flavors of Certificates in Service Mesh: The Whys and Hows!](https://sched.co/1R2wC)
* [走向边缘：使用 Istio 和 K8gb 创建全球分布式入口](https://sched.co/1R2o5/)
* [幕后花絮：探索 Istio 的锁争用及其对 Expedia 计算平台的影响](https://sched.co/1R2uV)
* [通过功能门理清服务网格](https://sched.co/1R2v6)
* [服务网格中的证书风格：原因和方法！](https://sched.co/1R2wC)

Istio had a kiosk in the project pavilion, with the majority of questions asked being around the schedule for ambient mesh being production ready.
Istio 在项目展馆设有一个信息亭，询问的大多数问题都与环境网格生产准备就绪的时间表有关。

{{< image width="75%"
    link="./istio-booth-1.jpg"
    caption="Discussions at the Istio kiosk"
    >}}
{{< image width="75%"
    link="./istio-booth-1.jpg"
    caption="在 Istio 信息亭进行讨论"
    >}}

We are glad that the major question which we had at the Istio kiosk in Europe — the schedule for CNCF graduation — has been answered, and we assured everyone that we are working on ambient mesh with the same level of seriousness.
我们很高兴我们在欧洲 Istio 信息亭提出的主要问题——CNCF 毕业时间表——已经得到解答，并且我们向所有人保证，我们正在以同样的认真态度致力于环境网格。

Many of our members and maintainers offered support at our kiosk, helping us answer all the questions from our users.
我们的许多会员和维护人员在我们的信息亭提供了支持，帮助我们回答用户的所有问题。

{{< image width="75%"
    link="./istio-booth-2.jpg"
    caption="Members and maintainers at the Istio kiosk"
    >}}
{{< image width="75%"
    link="./istio-booth-2.jpg"
    caption="Istio 信息亭的成员和维护者"
    >}}

Another highlight of our kiosk was that we had new Istio T-shirts sponsored by Microsoft, Solo.io, Stackgenie and Tetrate for everyone to grab!
我们售货亭的另一个亮点是，我们有由 Microsoft、Solo.io、Stackgenie 和 Tetrate 赞助的新 Istio T 恤供大家购买！

{{< image width="75%"
    link="./istio-t-shirts.jpg"
    caption="A new crop of Istio T-shirts"
    >}}
{{< image width="75%"
    link="./istio-t-shirts.jpg"
    caption="新一代 Istio T 恤"
    >}}

We would like to express our heartfelt gratitude to our platinum sponsors Google Cloud, for supporting Istio Day North America! Last but not least, we would like to thank our Istio Day Program Committee members, for all their hard work and support!
我们衷心感谢我们的白金赞助商 Google Cloud 对北美 Istio Day 的支持！ 最后但并非最不重要的一点是，我们要感谢 Istio Day 计划委员会成员的辛勤工作和支持！

[See you in Paris in March 2024!](https://events.linuxfoundation.org/kubecon-cloudnativecon-europe/co-located-events/istio-day/)
[2024 年 3 月巴黎见！](https://events.linuxfoundation.org/kubecon-cloudnativecon-europe/co- located-events/istio-day/)

{{< image width="100%"
    link="./istio-day-paris.jpg"
    alt="Istio Day Europe 2024"
    >}}
{{< image width="100%"
    link="./istio-day-paris.jpg"
    alt="2024 年欧洲 Istio 日"
    >}}
