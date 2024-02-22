---
title: "Istio 正式从 CNCF 毕业的公告"
publishdate: 2023-07-12
attribution: "Craig Box, for the Istio Steering Committee"
keywords: [Istio,CNCF]
---

我们很高兴宣布 [Istio 现已成为云原生计算基金会（CNCF）的毕业项目](https://www.cncf.io/blog/)。

我们要感谢 TOC 倡议者
[Emily Fox](https://www.cncf.io/people/technical-oversight-committee/?p=emily-fox)
和 [Nikhita Raghunath](https://www.cncf.io/people/technical-oversight-committee/?p=nikhita-raghunath)，
以及在过去六年中参与 Istio 设计、开发和部署的所有贡献者。

与以前一样，在此期间 Istio 项目的工作不会受到任何干扰。我们很高兴宣布
[Istio 1.18 版本将 Ambient Mesh 推升到 Alpha](/zh/news/releases/1.18.x/announcing-1.18/#ambient-mesh)，
随后将持续推动其达到生产就绪状态。
Sidecar 部署仍然是使用 Istio 的推荐方法，而我们的
[1.19 版本](https://github.com/istio/istio/wiki/Istio-Release-1.19)
将对 Kubernetes 1.28 中 Alpha 级别的
[全新 Sidecar 容器特性](https://github.com/kubernetes/kubernetes/pull/116429)提供支持。

我们欢迎微软加入 Istio 社区，
微软[决定将 Open Service Mesh 项目归档并协作推进 Istio](https://openservicemesh.io/blog/osm-project-update/)。
Istio 作为[活跃度排名第三的 CNCF 项目](https://all.devstats.cncf.io/d/53/projects-health-table?orgId=1)，
得到了 [20 多家供应商的支持](/zh/about/ecosystem/)以及
[数十家公司的持续贡献](https://istio.devstats.cncf.io/d/5/companies-table?orgId=1&var-period_name=Last%20year&var-metric=prs)，
在服务网格领域没有比 Istio 更好的选择。

我们邀请 Istio 社区为[即将举行的虚拟 IstioCon 2023 提交演讲话题](https://sessionize.com/istiocon-2023)，
这是与 KubeCon China 在上海同一个地点举办的
[全天候现场活动](https://www.lfasiallc.com/kubecon-cloudnativecon-open-source-summit-china/co-located-events/istiocon-call-for-proposals-cn/#preparing-to-submit-your-proposal-cn)，
您也可以参加 KubeCon NA 在芝加哥同一个地点举办的
[Istio Day](https://events.linuxfoundation.org/kubecon-cloudnativecon-north-america/co-located-events/istio-day/#call-for-proposals)。

---

当我们[宣布进入 Incubation](/zh/blog/2022/istio-accepted-into-cncf/) 时，
曾提到过这段旅程始于 2016 年 Istio 创立之时。
开源协作项目的一个伟大之处在于无论贡献者受雇于哪家公司，他们与项目本身的关联不会中断。
六年来，一些最初的贡献者基于 Istio 创立了新公司；
一些人跳槽到了其他公司继续支持 Istio；
还有一些人至今仍在 Google 或 IBM 从事 Istio 相关的工作。

CNCF 发布的公告以及
[Intel](https://www.intel.com/content/www/us/en/developer/articles/community/Intel-Service-Mesh-Optimizes-and-Protects-Istio-Service-Mesh)、
[Red Hat](https://cloud.redhat.com/blog/red-hat-congratulates-istio-on-graduating-at-the-cncf)、
[Tetrate](https://tetrate.io/blog/istio-service-mesh-graduates-cncf/)、
[Solo.io](https://www.solo.io/blog/istio-graduates-cncf)
和 [DaoCloud](https://blog.daocloud.io/8970.html)（还有更多公司）
发布的博文都展示了如今 Istio 项目参与者的许多想法和感受。

我们也联系了一些以下已离开 Istio 项目的贡献者，让他们分享自己的想法。

{{< quote caption="Sven Mawson, Istio 共同创始人兼 SambaNova Systems 首席软件架构师" >}}
从 Istio 诞生之时，我们就希望它能够与老大哥 Kubernetes 一样成为 CNCF 全景图的核心组成部分。
回首最初至今 Istio 项目所取得的一切成就，真是令人惊叹。
我对社区所取得的成就感到非常自豪，而这次毕业意味着对项目持续成功的肯定。
{{< /quote >}}

{{< quote caption="Shriram Rajagopalan，Amalgam8 联合创立者" >}}
作为 Istio 服务网格的共同创始人，看到我们走过的这段路程非常令人满意。
我们最初的愿景是为云原生和传统应用提供开箱即用的安全性、可观测性和可编程性的基础设施。
我们对大量企业广泛采用 Istio 感到自豪，
并对人们在 Istio 上部署重要生产工作负载时对 Istio 团队的信任表示感激。
从 CNCF 毕业是对我们的愿景、项目以及我们迄今为止建立的庞大社区的正式认可和肯定。
{{< /quote >}}

{{< quote caption="Jasmine Jaksic，第一任 Istio TPM" >}}
当我们六年前推出 Istio 时，我们就知道它必将引起轰动，
但我们当时没有意识到自己已推开了快速进化的科技之门。
Istio 的成长超出了我们所有人最狂野的想象，而今天 Istio 又迎来了一个里程碑。
作为一名创始成员，我曾在这个产品上几乎扮演过每一个角色，
我非常感激在 Istio 这令人难以置信的旅程中有自己的身影。
{{< /quote >}}

{{< quote caption="Martin Taillefer，最初的 Istio 工程师" >}}
当我们开始开发 Istio 时，服务网格的概念还不存在，
我们对它会是什么有着一个广泛的想法，但具体细节并不明确。
看到这项技术迅速发展，并成为社区中宝贵的资产，真是令人兴奋。
如今的这一成就是我们所有人辛勤工作的结果，这让人感到欣慰。
{{< /quote >}}

{{< quote caption="Douglas Reid，最初的 Istio 工程师和 Steamship 创始工程师" >}}
当我们为 Istio 构建初始原型时，我们希望其他人能够看到自己所创造的价值，
并以积极的方式影响组织构建、管理和监控生产服务的方式。
从 CNCF 毕业是对这些最初愿景的实现，这远远超出了任何合理的预期。
当然，这样的里程碑只有在充满热情、知识渊博且专注的大量个人贡献下才能实现。
这一成就源于多年来贡献者们的友好交流、耐心和所分享的专业知识。
愿这个项目继续发展，并帮助用户在未来很多年内都能交付安全、可靠的服务！
{{< /quote >}}

{{< quote caption="Brian Avery，前 TOC 成员，Istio 产品安全负责人和测试与发布负责人" >}}
在我作为 Istio 社区的贡献者和负责人期间，
Istio 反复展示了自己作为一个强大平台的特点，
拥有在安全性、联网和可观测性战略中所需的工具。
我对我们在产品安全和测试与发布工作组中进行的优化尤为自豪，
通过提供安全、可靠和可预测的功能和版本来优先满足用户的需求。
Istio 在 CNCF 的毕业是社区迈出的重要一步，验证了我们的所有辛勤工作。
在此衷心祝贺 Istio 社区。我很期待看到 Istio 接下来的发展。
{{< /quote >}}
