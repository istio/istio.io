---
title: "Istio！七岁生日快乐！"
description: 庆祝 Istio 的发展势头和令人兴奋的未来。
publishdate: 2024-05-24
attribution: "Lin Sun (Solo.io)，代表 Istio 指导委员会; Translated by Wilson Wu (DaoCloud)"
keywords: [istio,birthday,momentum,future]
---

{{< image width="80%"
    link="./7th-birthday.png"
    alt="Istio！七岁生日快乐！"
    >}}

2017 年的今天，[Google 和 IBM 宣布推出 Istio 服务网格](https://techcrunch.com/2017/05/24/google-ibm-and-lyft-launch-istio-an-open-source-platform-for-managing-and-securing-microservices/)。
Istio 是一项开放技术，使开发人员能够无缝连接、管理和保护不同服务的网络 - 无论平台、来源或供应商如何。
我们简直不敢相信 Istio 今天已经七岁了！为了庆祝该项目的七岁生日，
我们想强调 Istio 的发展势头及其令人兴奋的未来。

## 用户的快速采用 {#rapid-adoption-among-users}

Istio 是世界上被采用最广泛的服务网格项目，自 2017 年成立以来一直保持着强劲的发展势头。
去年，Istio 随着在 [CNCF 的毕业](https://www.cncf.io/announcements/2023/07/12/cloud-native-computing-foundation-reaffirms-istio-maturity-with-project-graduation/)，
加入了如 Kubernetes、Prometheus 以及其他云原生生态系统中坚力量的行列。
最终用户范围从数字原生初创公司到全球最大的金融机构和电信公司，
在[案例研究](/zh/about/case-studies/)中，有来自 eBay、T-Mobile、Airbnb、
Splunk、FICO、T-Mobile、Salesforce 以及许多其他公司。

Istio 的控制平面和 Sidecar 是 Docker Hub 上下载量排名第三和第四的镜像，
每个镜像的下载量都超过 [100 亿次](https://hub.docker.com/search?q=istio)。

{{< image width="80%"
    link="./dockerhub.png"
    alt="Istio 在 Docker Hub 的下载量！"
    >}}

我们在 [Istio 的仓库](https://github.com/istio/istio/)上拥有超过 35,000 个 GitHub Star，
并且还在持续增长。感谢所有为 istio/istio 仓库添加 Star 的人。

{{< image width="80%"
    link="./github-stars.png"
    alt="istio/istio 仓库的 GitHub Star！"
    >}}

在 Istio 七岁生日之际，我们询问了一些用户的想法：

{{< quote >}}
**如今，Istio 成为 Airbnb 服务网格的支柱，管理着数十万个工作负载之间的所有流量。
自采用 Istio 五年以来，我们一直对这个决定感到满意。成为这个充满活力和支持性社区的一部分真是太棒了。生日快乐，Istio！**

— Weibo He，Airbnb 资深软件工程师
{{< /quote >}}

{{< quote >}}
**Istio 使我们能够在类似生产的隔离环境中快速部署和测试微服务以及相关服务。
这种称为隔离的方法使 eBay 的开发人员能够在开发生命周期的早期识别缺陷，
通过减少不稳定来提高实时环境的稳定性，并建立对自动化生产部署的信心。
最终，这加速了开发过程并提高了生产部署的成功率。**

— Sudheendra Murthy，eBay 首席工程师兼服务网格架构师
{{< /quote >}}

{{< quote >}}
**Istio 通过集成分布式链路追踪和 OpenTelemetry 增强了云平台的安全性，
同时简化了可观测性。这种组合提供了强大的安全功能和对系统性能的深入洞察，
从而能够更有效地监控我们的分布式服务并进行故障排查。**

— Sathish Krishnan，瑞银集团杰出工程师
{{< /quote >}}

{{< quote >}}
**在我们采用基于微服务的架构的过程中，采用 Istio 改变了我们的工程组织的游戏规则。
其面面俱到的方法使我们能够轻松管理流量路由，深入了解我们的服务与分布式链路追踪的服务交互，
以及通过 WASM 插件进行扩展。其全面的功能集使其成为我们基础设施的重要组成部分，
并允许我们的工程师将应用程序代码与基础设施管道分离。**

— Shray Kumar，Bluecore 首席软件工程师
{{< /quote >}}

{{< quote >}}
**Istio 实在是太棒了，我已经使用它 4 到 5 年了，发现它可以非常轻松地以非常低的延迟管理数以万计 Pod 的数千个网关。
如果您需要建立一个非常安全的基础设施，Istio 是一个很好的朋友。
此外，它非常适合需要大量安全性且需要符合 PCI/HIPAA/SoC2 标准的基础设施。**

— Ezequiel Arielli，SIGMA Financial AI 云平台主管
{{< /quote >}}

{{< quote >}}
**Istio 帮助我们以标准化的方式保护各种客户的所有部署中的环境。
Istio 的灵活性和可定制性确实帮助我们通过将加密、鉴权和身份验证委托给服务网格来构建更好的应用程序，
而不必在我们的应用程序代码库中实现这些。**

— Joel Millage，BCubed 软件工程师
{{< /quote >}}

{{< quote >}}
**我们在 Predibase 广泛使用 Istio 来简化多集群网格之间的通信，
这有助于部署和训练具有低延迟和故障转移的开源微调 LLM 模型。借助 Istio，
我们获得了许多开箱即用的功能，否则这些功能将需要数周时间才能实现。**

— Gyanesh Mishra，Predibase 云基础设施工程师
{{< /quote >}}

{{< quote >}}
**Istio 毫无疑问是市场上最完整、功能最齐全的服务网格平台。
这一成功是社区积极参与、帮助并指导项目方向的直接结果。祝贺 Istio 的周年纪念日！**

— Daniel Requena，iFood SRE
{{< /quote >}}

{{< quote >}}
**我们多年来一直在生产中使用 Istio，它是我们基础设施的关键组件，使我们能够安全地连接微服务，
并提供入口/出口流量管理和一流的可观测性。社区很棒，每个版本都带来许多令人兴奋的功能。**

— Frédéric Gaudet，BlablaCar 资深 SRE
{{< /quote >}}

## 贡献者和供应商的惊人多样性 {#amazing-diversity-of-contributors-and-vendors}

在过去的一年里，我们的社区在贡献公司的数量和贡献者的数量方面都出现了巨大的增长。
还记得 Istio 三岁时就有 500 名贡献者吗？在去年我们已拥有超过 1,700 名贡献者！

随着微软的开放服务网格团队加入 Istio 社区，我们将 Azure 添加到[云和企业 Kubernetes 供应商列表](/zh/about/ecosystem/)，
包括 Google Cloud、Red Hat OpenShift、VMware Tanzu、华为云、DaoCloud、
Oracle Cloud、腾讯云、Akamai Cloud 和阿里云，都提供了与 Istio 兼容的解决方案。
我们也很高兴看到 Amazon Web Services 团队由于来自希望在 AWS 上运行 Istio 的用户发布了
[Istio 的 EKS 蓝图](https://aws-ia.github.io/terraform-aws-eks-blueprints/patterns/istio/)。

专业网络软件提供商也在推动 Istio 向前发展，Solo.io、Tetrate 和 F5 Networks
都提供可在任何环境中运行的企业级 Istio 解决方案。

以下是过去一年贡献最多的公司，其中 Solo.io、Google 和 DaoCloud 占据前三名。
虽然这些公司中的大多数都是 Istio 供应商，但 Salesforce 和 Ericsson 是最终用户，并在生产环境中运行 Istio！

{{< image width="80%"
    link="./contribution.png"
    alt="去年 Istio 贡献最多的公司！"
    >}}

以下是我们社区领袖的一些想法：

{{< quote >}}
**随着各行业云原生采用的成熟，服务网格的采用在过去几年中一直在稳步上升。
自从他们去年从 CNCF 毕业以来，Istio 帮助推动了这一成熟，我们祝他们生日快乐。
随着 Istio 团队添加 Ambient 模式等新功能并简化服务网格体验，我们期待观察并支持这种持续增长。**

— Chris Aniszczyk，CNCF 首席技术官
{{< /quote >}}

{{< quote >}}
**服务网格是微服务架构的核心，是云原生的标志。
Istio 的生日不仅庆祝了可观测性和流量管理的普及和重要性，还庆祝了通过加密、
相互身份验证和许多其他简化采用、集成和部署体验的其他核心安全原则，实现默认安全通信的日益增长的需求。**

— Emily Fox，CNCF TOC 主席及红帽资深首席软件工程师
{{< /quote >}}

{{< quote >}}
**在我看来，Istio 不是一个服务网格。这是一个由用户和贡献者组成的协作社区，
他们恰好提供了世界上最受欢迎的服务网格。祝这个神奇的社区生日快乐！
这是美妙的七年，我期待着在 Istio 社区中与来自世界各地的朋友和同事一起进行更多庆祝！**

— Mitch Connors，Istio 技术监督委员会成员及微软首席工程师
{{< /quote >}}

{{< quote >}}
**在过去的两年里，成为世界上最受欢迎的服务网格团队的一员是一种荣幸和充实的经历。
很高兴看到 Istio 从 CNCF 孵化阶段成长为毕业项目，更高兴看到最新、最伟大的 1.22 版本完成时的动力和热情。
祝愿未来几年有更多成功的发布。**

— Faseela K，Istio 指导委员会成员及爱立信云原生开发者
{{< /quote >}}

{{< quote >}}
**Istio 的独特之处在于，社区由来自世界各地的开发人员、用户和供应商共同努力，
使 Istio 成为业界最好、最强大的开放服务网格。正是社区的力量使 Istio 如此成功，
现在在 CNCF 的领导下，我期待看到 Istio 成为所有云原生应用程序事实上的服务网格标准。**

— Neeraj Poddar，Istio 技术监督委员会成员及 Solo.io 工程副总裁
{{< /quote >}}

{{< quote >}}
**过去 5 年能够与 Istio 社区合作是我的荣幸。有大量的贡献者，他们的奉献、热情和辛勤工作让我在这个项目上度过了真正愉快的时光。
社区中有许多用户提供反馈，帮助 Istio 成为最好的服务网格。
我仍然对社区所做的事情感到惊讶，并期待看到我们未来将取得的成功。**

— Eric Van Norman，Istio 技术监督委员会成员及 IBM 咨询软件工程师
{{< /quote >}}

{{< quote >}}
**Istio 是 Salesforce 服务网格基础设施的支柱，目前它每天为我们所有的服务提供数万亿个请求。
我们用网格解决了很多复杂的问题。很高兴能参与到这一旅程中并为社区做出贡献。
多年来，Istio 已经发展成为一个可靠的服务网格，同时还在不断创新。我们对未来的发展充满期待！**

— Rama Chavali，Istio 网络工作组负责人及 Salesforce 软件工程架构师
{{< /quote >}}

## 持续的技术创新 {#continuous-technical-innovation}

我们坚信多元化推动创新。最让我们惊讶的是 Istio 社区的不断创新，从让升级变得更容易，
到采用 Kubernetes Gateway API，到添加新的无 Sidecar Ambient
数据平面模式，再到让 Istio 变得易于使用和尽可能透明。

Istio 的 Ambient 模式于 2022 年 9 月推出，旨在简化操作、更广泛的应用程序兼容性并降低基础设施成本。
Ambient 模式引入了轻量级、共享的 Layer 4（L4）节点代理和可选的Layer 7（L7）代理，
从而消除了数据平面对传统 Sidecar 代理的需要。Ambient 模式背后的核心创新在于它将 L4 和 L7 处理分为两个不同的层。
这种分层方法允许您逐步采用 Istio，实现从无网格到安全覆盖（L4），
再到可选的完整 L7 处理的平滑过渡 - 根据需要，在整个队列中基于每个命名空间。

作为 [Istio 1.22 版本](/zh/news/releases/1.22.x/announcing-1.22/)的一部分，
[Ambient 模式已达到 Beta](/zh/blog/2024/ambient-reaches-beta/)，
您可以在采取预防措施的前提下在生产环境中运行无 Sidecar 的 Istio。

以下是我们的贡献者和用户的一些想法和祝福：

{{< quote >}}
**在 Istio 生产可用之前，Auto Trader 就一直在生产环境中使用 Istio！
它显着提高了我们的运营能力，标准化了我们保护、配置和监控服务的方式。
升级已经从令人畏惧的任务演变为几乎不是什么大事，
而 Ambient 的推出证明了我们对简化的持续承诺 - 让新用户比以往任何时候都更容易以最小的努力获得真正的价值。**

— Karl Stoney，AutoTrader UK 技术架构师
{{< /quote >}}

{{< quote >}}
**Istio 是 Akamai 云的云原生技术栈的核心组件，为产品和服务提供安全的服务网格，
每个集群可提供数百万 RPS 和数百 GB 的吞吐量。我们期待该项目的未来路线图，
并很高兴能够在今年晚些时候评估新功能，例如 Ambient 网格。**

— Alex Chircop，Akamai 首席产品架构师
{{< /quote >}}

{{< quote >}}
**Istio 的网络和安全功能已成为我们基础设施运营的基本组成部分。
Istio Ambient 模式的引入显着简化了管理，并将我们的 Kubernetes 集群节点大小减少了约 20%。
我们成功地将生产系统迁移到使用 Ambient 数据平面。**

— Saarko Eilers，EISST International Ltd 基础设施运营经理
{{< /quote >}}

{{< quote >}}
**祝 Istio 生日快乐！多年来，我很荣幸成为这个伟大社区的一员，
特别是当我们继续利用 Ambient 模式构建世界上最好的服务网格时。**

— John Howard，最高产的 Istio 贡献者、Istio 技术监督委员会成员、Solo.io 高级架构师
{{< /quote >}}

{{< quote >}}
**很高兴看到像 Istio 这样的成熟项目继续发展和繁荣。成为 CNCF 的毕业项目吸引了一批新的开发人员，
为其持续成功做出了贡献。同时，Ambient 网格和 Gateway API 支持有望迎来服务网格被采用的新时代。
我很高兴看到即将发生的事情！**

— Justin Pettit，Istio 指导委员会成员及 Google 高级工程师
{{< /quote >}}

{{< quote >}}
**祝令人难以置信的 Istio 项目生日快乐，它不仅彻底改变了我们处理服务网格技术的方式，
而且还培养了一个充满活力和包容性的社区！见证 Istio 从 CNCF 孵化项目到毕业项目的演变是非常了不起的。
最近发布的 Istio 1.22 强调了其持续发展和对卓越的承诺，提供了增强的功能和改进的性能。期待该项目的下一步。**

— Iris Ding，Istio 指导委员会成员及英特尔软件工程师
{{< /quote >}}

{{< quote >}}
**从一开始就成为 Istio 项目的一部分是一种荣幸，多年来看到它和社区的成熟和发展。
就我个人而言，过去八年里，Istio 一直是我职业生涯的核心！我坚信 Istio 的最佳状态尚未到来，
在未来几年中，我们将看到 Istio 的持续增长、成熟和采用。为美好的社区共同实现这一里程碑干杯。**

— Zack Butcher，Istio 指导委员会成员及 Tetrate 创始人兼首席工程师
{{< /quote >}}

## 了解有关 Istio 的更多信息 {#learn-more-about-istio}

如果您是 Istio 新手，这里有一些资源可以帮助您了解更多信息：

- 查看[项目网站](https://istio.io)和 [GitHub 仓库](https://github.com/istio/istio/)。
- 阅读[文档](/zh/docs/)。
- 加入社区 [Slack](https://slack.istio.io/)。
- 在 [Twitter](https://twitter.com/IstioMesh) 和 [LinkedIn](https://www.linkedin.com/company/istio) 上关注该项目。
- 参加[用户社区会议](https://github.com/istio/community/blob/master/README.md#community-meeting)。
- 加入[工作组会议](https://github.com/istio/community/blob/master/WORKING-GROUPS.md#working-group-meetings)。
- 通过提交[会员请求](https://github.com/istio/community/blob/master/ROLES.md#member)，
  在 PR 被合并后成为 Istio 贡献者和开发人员。

如果您已经是 Istio 社区的一员，请祝 Istio 项目七岁生日快乐，
并在社交媒体上分享您对该项目的想法。感谢您的帮助和支持！
