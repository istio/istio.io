---
title: "快速、安全且简单：Istio 的 Ambient 模式在 v1.24 中正式推出"
description: 我们最新发布的 Ambient 模式（无边车的服务网格）已为所有人做好准备。
publishdate: 2024-11-07
attribution: "Lin Sun (Solo.io)，代表 Istio 指导和技术监督委员会; Translated by Wilson Wu (DaoCloud)"
keywords: [ambient,sidecars]
---

We are proud to announce that Istio’s ambient data plane mode has reached General Availability, with the ztunnel, waypoints and APIs being marked as Stable by the Istio TOC. This marks the final stage in Istio's [feature phase progression](/docs/releases/feature-stages/), signaling that ambient mode is fully ready for broad production usage.
我们很自豪地宣布，Istio 的环境数据平面模式已达到通用可用性，ztunnel、waypoint 和 API 已被 Istio TOC 标记为稳定。这标志着 Istio [功能阶段进展](/docs/releases/feature-stages/) 的最后阶段，表明环境模式已完全准备好用于广泛的生产用途。

Ambient mesh — and its reference implementation with Istio’s ambient mode — [was announced in September 2022](/blog/2022/introducing-ambient-mesh/). Since then, our community has put in 26 months of hard work and collaboration, with contributions from Solo.io, Google, Microsoft, Intel, Aviatrix, Huawei, IBM, Red Hat, and many others. Stable status in 1.24 indicates the features of ambient mode are now fully ready for broad production workloads. This is a huge milestone for Istio, bringing Istio to production readiness without sidecars, and [offering users a choice](/docs/overview/dataplane-modes/).
环境网格及其使用 Istio 环境模式的参考实现 [于 2022 年 9 月发布](/blog/2022/introducing-ambient-mesh/)。从那时起，我们的社区已经投入了 26 个月的辛勤工作和协作，Solo.io、谷歌、微软、英特尔、Aviatrix、华为、IBM、Red Hat 等许多公司都做出了贡献。1.24 中的稳定状态表明环境模式的功能现已完全准备好用于广泛的生产工作负载。这对 Istio 来说是一个巨大的里程碑，它使 Istio 无需 Sidecar 即可投入生产，并 [为用户提供了选择](/docs/overview/dataplane-modes/)。

## Why ambient mesh?
## 为什么是环境网格？

From the launch of Istio in 2017, we have observed a clear and growing demand for mesh capabilities for applications — but heard that many users found the resource overhead and operational complexity of sidecars hard to overcome. Challenges that Istio users shared with us include how sidecars can break applications after they are added, the large CPU and memory requirement for a proxy with every workload, and the inconvenience of needing to restart application pods with every new Istio release.
自 2017 年 Istio 发布以来，我们观察到应用程序对网格功能的需求明显且不断增长 — 但听说许多用户发现 Sidecar 的资源开销和操作复杂性难以克服。Istio 用户与我们分享的挑战包括 Sidecar 在添加后如何破坏应用程序、每个工作负载的代理对 CPU 和内存的需求很大，以及每次发布新的 Istio 版本时都需要重新启动应用程序 pod 的不便。

As a community, we designed ambient mesh from the ground up to tackle these problems, alleviating the previous barriers of complexity faced by users looking to implement service mesh. The new concept was named  ‘ambient mesh’ as it was designed to be transparent to your application, with no proxy infrastructure collocated with user workloads, no subtle changes to configuration required to onboard, and no application restarts required. In ambient mode it is trivial to add or remove applications from the mesh. All you need to do is [label a namespace](/docs/ambient/usage/add-workloads/), and all applications in that namespace are instantly added to the mesh. This immediately secures all traffic within that namespace with industry-standard mutual TLS encryption — no other configuration or restarts required!. Refer to the [Introducing Ambient Mesh blog](/blog/2022/introducing-ambient-mesh/) for more information on why we built Istio’s ambient mode.
作为一个社区，我们从头开始设计了环境网格来解决这些问题，减轻了用户在实施服务网格时面临的先前的复杂性障碍。这个新概念被命名为“环境网格”，因为它被设计为对您的应用程序透明，没有与用户工作负载共置的代理基础设施，不需要对配置进行细微更改，也不需要重新启动应用程序。在环境模式下，从网格中添加或删除应用程序非常简单。您需要做的就是[标记命名空间](/docs/ambient/usage/add-workloads/)，该命名空间中的所有应用程序都会立即添加到网格中。这会立即使用行业标准的相互 TLS 加密保护该命名空间内的所有流量——无需其他配置或重新启动！有关我们构建 Istio 环境模式的原因的更多信息，请参阅[介绍环境网格博客](/blog/2022/introducing-ambient-mesh/)。

## How does ambient mode make adoption easier?
## 环境模式如何使采用变得更容易？

The core innovation behind ambient mesh is that it slices Layer 4 (L4) and Layer 7 (L7) processing into two distinct layers. Istio’s ambient mode is powered by lightweight, shared L4 node proxies and optional L7 proxies, removing the need for traditional sidecar proxies from the data plane. This layered approach allows you to adopt Istio incrementally, enabling a smooth transition from no mesh, to a secure overlay (L4), to optional full L7 processing — on a per-namespace basis, as needed, across your fleet.
环境网格背后的核心创新是将第 4 层 (L4) 和第 7 层 (L7) 处理分为两个不同的层。Istio 的环境模式由轻量级、共享的 L4 节点代理和可选的 L7 代理提供支持，从数据平面上消除了对传统 Sidecar 代理的需求。这种分层方法允许您逐步采用 Istio，从而实现从无网格到安全覆盖 (L4) 再到可选的完整 L7 处理的平稳过渡 — 根据需要，按命名空间逐个进行，覆盖整个集群。

By utilizing ambient mesh, users bypass some of the previously restrictive elements of the sidecar model. Server-send-first protocols now work, most reserved ports are now available, and the ability for containers to bypass the sidecar — either maliciously or not — is eliminated.
通过利用环境网格，用户可以绕过 Sidecar 模型中之前的一些限制元素。服务器发送优先协议现在可行，大多数保留端口现在可用，并且消除了容器绕过 Sidecar（无论是恶意的还是非恶意的）的能力。

The lightweight shared L4 node proxy is called the *[ztunnel](/docs/ambient/overview/#ztunnel)* (zero-trust tunnel). ztunnel drastically reduces the overhead of running a mesh by removing the need to potentially over-provision memory and CPU within a cluster to handle expected loads. In some use cases, the savings can exceed 90% or more, while still providing zero-trust security using mutual TLS with cryptographic identity, simple L4 authorization policies, and telemetry.
轻量级共享 L4 节点代理称为 *[ztunnel](/docs/ambient/overview/#ztunnel)*（零信任隧道）。ztunnel 消除了在集群中过度配置内存和 CPU 以处理预期负载的需求，从而大幅降低了运行网格的开销。在某些用例中，节省的成本可能超过 90% 或更多，同时仍使用具有加密身份的相互 TLS、简单的 L4 授权策略和遥测提供零信任安全性。

The L7 proxies are called *[waypoints](/docs/ambient/overview/#waypoint-proxies)*. Waypoints process L7 functions such as traffic routing, rich authorization policy enforcement, and enterprise-grade resilience. Waypoints run outside of your application deployments and can scale independently based on your needs, which could be for the entire namespace or for multiple services within a namespace. Compared with sidecars, you don’t need one waypoint per application pod, and you can scale your waypoint effectively based on its scope, thus saving significant amounts of CPU and memory in most cases.
L7 代理称为 *[waypoint](/docs/ambient/overview/#waypoint-proxies)*。Waypoint 处理 L7 功能，例如流量路由、丰富的授权策略实施和企业级弹性。Waypoint 在您的应用程序部署之外运行，可以根据您的需求独立扩展，可以是整个命名空间，也可以是命名空间内的多个服务。与 Sidecar 相比，您不需要每个应用程序 pod 一个 Waypoint，并且您可以根据其范围有效地扩展 Waypoint，从而在大多数情况下节省大量 CPU 和内存。

The separation between the L4 secure overlay layer and L7 processing layer allows incremental adoption of the ambient mode data plane, in contrast to the earlier binary "all-in" injection of sidecars. Users can start with the secure L4 overlay, which offers a majority of features that people deploy Istio for (mTLS, authorization policy, and telemetry). Complex L7 handling such as retries, traffic splitting, load balancing, and observability collection can then be enabled on a case-by-case basis.
L4 安全覆盖层与 L7 处理层之间的分离允许逐步采用环境模式数据平面，这与早期的二进制“全包”注入 Sidecar 不同。用户可以从安全的 L4 覆盖开始，它提供了人们部署 Istio 所需的大多数功能（mTLS、授权策略和遥测）。然后可以根据具体情况启用复杂的 L7 处理，例如重试、流量拆分、负载平衡和可观察性收集。

## Rapid exploration and adoption of ambient mode
## 快速探索和采用环境模式

The ztunnel image on Docker Hub has reached over [1 million downloads](https://hub.docker.com/search?q=istio), with ~63,000 pulls in the last week alone.
Docker Hub 上的 ztunnel 镜像下载量已超过 [100 万次](https://hub.docker.com/search?q=istio)，仅上周就有约 63,000 次下载。

{{< image width="100%"
    link="./ztunnel-image.png"
    alt="Docker Hub downloads of Istio ztunnel!Docker Hub 下载 Istio ztunnel！"
    >}}

We asked a few of our users for their thoughts on ambient mode’s GA:
我们询问了一些用户对环境模式 GA 的看法：

{{< quote >}}
**Istio's implementation of a service mesh with their ambient mesh design has been a great addition to our Kubernetes clusters to simplify the team responsibilities and overall network architecture of the mesh. In conjunction with the Gateway API project it has given me a great way to enable developers to get their networking needs met at the same time as only delegating as much control as needed. While it's a rapidly evolving project it has been solid and dependable in production and will be our default option for implementing networking controls in a Kubernetes deployment going forth.**
**Istio 通过其环境网格设计实现的服务网格对我们的 Kubernetes 集群来说是一个很好的补充，它简化了团队职责和网格的整体网络架构。结合 Gateway API 项目，它为我提供了一种很好的方法，使开发人员能够满足他们的网络需求，同时只委托所需的控制。虽然这是一个快速发展的项目，但它在生产中一直很稳定可靠，将成为我们在 Kubernetes 部署中实现网络控制的默认选项。**

— [Daniel Loader](https://uk.linkedin.com/in/danielloader), Lead Platform Engineer at Quotech
— [Daniel Loader](https://uk.linkedin.com/in/danielloader)，Quotech 首席平台工程师

{{< /quote >}}

{{< quote >}}
**It is incredibly easy to install ambient mesh with the Helm chart wrapper. Migrating is as simple as setting up a waypoint gateway, updating labels on a namespace, and restarting. I’m looking forward to ditching sidecars and recuperating resources. Moreover, easier upgrades. No more restarting deployments!**
**使用 Helm 图表包装器安装环境网格非常简单。迁移就像设置航点网关、更新命名空间上的标签和重新启动一样简单。我期待着放弃 Sidecar 并恢复资源。此外，升级更容易。不再需要重新启动部署！**

— [Raymond Wong](https://www.linkedin.com/in/raymond-wong-43baa8a2/), Senior Architect at Forbes
— [Raymond Wong](https://www.linkedin.com/in/raymond-wong-43baa8a2/)，福布斯高级建筑师
{{< /quote >}}

{{< quote >}}
**Istio’s ambient mode has served our production system since it became Beta. We are pleased by its stability and simplicity and are looking forward to additional benefits and features coming together with the GA status. Thanks to the Istio team for the great efforts!**
**Istio 的环境模式自 Beta 版以来一直服务于我们的生产系统。我们对它的稳定性和简单性感到满意，并期待随着 GA 状态的到来，它还能带来更多优势和功能。感谢 Istio 团队的不懈努力！**

— Saarko Eilers, Infrastructure Operations Manager at EISST International Ltd
— EISST International Ltd 基础设施运营经理 Saarko Eilers
{{< /quote >}}

{{< quote >}}
**By Switching from AWS App Mesh to Istio in ambient mode, we were able to slash about 45% of the running containers just by removing sidecars and SPIRE agent DaemonSets. We gained many benefits, such as reducing compute costs or observability costs related to sidecars, eliminating many of the race conditions related to sidecars startup and shutdown, plus all the out-of-the-box benefits just by migrating, like mTLS, zonal awareness and workload load balancing.**
**通过在环境模式下从 AWS App Mesh 切换到 Istio，我们仅通过删除 Sidecar 和 SPIRE 代理 DaemonSet 就能够削减大约 45% 的正在运行的容器。我们获得了许多好处，例如降低与 Sidecar 相关的计算成本或可观察性成本，消除与 Sidecar 启动和关闭相关的许多竞争条件，以及仅通过迁移即可获得的所有开箱即用的好处，例如 mTLS、区域感知和工作负载负载平衡。**

— [Ahmad Al-Masry](https://www.linkedin.com/in/ahmad-al-masry-9ab90858/), DevSecOps Engineering Manager at Harri
— [Ahmad Al-Masry](https://www.linkedin.com/in/ahmad-al-masry-9ab90858/)，Harri 的 DevSecOps 工程经理
{{< /quote >}}

{{< quote >}}
**We chose Istio because we're excited about ambient mesh. Different from other options, with Istio, the transition from sidecar to sidecar-less is not a leap of faith. We can build up our service mesh infrastructure with Istio knowing the path to sidecar-less is a two way door.**
**我们之所以选择 Istio，是因为我们对环境网格感到兴奋。与其他选项不同，使用 Istio，从 Sidecar 到无 Sidecar 的过渡并非是一次信念飞跃。我们可以用 Istio 构建我们的服务网格基础设施，因为我们知道通往无 Sidecar 的道路是双向的。**

— [Troy Dai](https://www.linkedin.com/in/troydai/), Senior Staff Software Engineer at Coinbase
— [Troy Dai](https://www.linkedin.com/in/troydai/)，Coinbase 高级软件工程师
{{< /quote >}}

{{< quote >}}
**Extremely proud to see the fast and steady growth of ambient mode to GA, and all the amazing collaboration that took place over the past months to make this happen! We are looking forward to finding out how the new architecture is going to revolutionize the telcos world.**
**非常自豪地看到环境模式快速而稳定地发展到 GA，以及过去几个月为实现这一目标而进行的所有令人惊叹的合作！我们期待着了解新架构将如何彻底改变电信世界。**

— [Faseela K](https://www.linkedin.com/in/faseela-k-42178528/), Cloud Native Developer at Ericsson
— [Faseela K](https://www.linkedin.com/in/faseela-k-42178528/)，爱立信云原生开发人员
{{< /quote >}}

{{< quote >}}
**We are excited to see the Istio dataplane evolve with the GA release of ambient mode and are actively evaluating it for our next-generation infrastructure platform. Istio's community is dynamic and welcoming, and ambient mesh is a testament to the community embracing new ideas and pragmatically working to improve developer experience operating Istio at scale.**
**我们很高兴看到 Istio 数据平面随着环境模式的 GA 版本而发展，并正在积极评估它是否适合我们的下一代基础设施平台。Istio 的社区充满活力且热情好客，环境网格证明了社区正在接受新想法并务实地努力改善开发人员大规模操作 Istio 的体验。**

— [Tyler Schade](https://www.linkedin.com/in/tylerschade/), Distinguished Engineer at GEICO Tech
— [Tyler Schade](https://www.linkedin.com/in/tylerschade/)，GEICO Tech 杰出工程师
{{< /quote >}}

{{< quote >}}
**With Istio’s ambient mode reaching GA, we finally have a service mesh solution that isn’t tied to the pod lifecycle, addressing a major limitation of sidecar-based models. Ambient mesh provides a more lightweight, scalable architecture that simplifies operations and reduces our infrastructure costs by eliminating the resource overhead of sidecars.**
**随着 Istio 的环境模式正式发布，我们终于有了一个不依赖于 Pod 生命周期的服务网格解决方案，解决了基于 Sidecar 的模型的主要限制。环境网格提供了一种更轻量级、可扩展的架构，通过消除 Sidecar 的资源开销，简化了操作并降低了我们的基础设施成本。**

— [Bartosz Sobieraj](https://www.linkedin.com/in/bartoszsobieraj/), Platform Engineer at Spond
— [Bartosz Sobieraj](https://www.linkedin.com/in/bartoszsobieraj/)，Spond 平台工程师
{{< /quote >}}

{{< quote >}}
**Our team chose Istio for its service mesh features and strong alignment with the Gateway API to create a robust Kubernetes-based hosting solution. As we integrated applications into the mesh, we faced resource challenges with sidecar proxies, prompting us to transition to ambient mode in Beta for improved scalability and security. We started with L4 security and observability through ztunnel, gaining automatic encryption of in-cluster traffic and transparent traffic flow monitoring. By selectively enabling L7 features and decoupling the proxy from applications, we achieved seamless scaling and reduced resource utilization and latency. This approach allowed developers to focus on application development, resulting in a more resilient, secure, and scalable platform powered by ambient mode.**
**我们的团队之所以选择 Istio，是因为它的服务网格功能以及与 Gateway API 的紧密结合，从而创建了一个基于 Kubernetes 的强大托管解决方案。在将应用程序集成到网格中时，我们面临着 Sidecar 代理的资源挑战，这促使我们在 Beta 版中过渡到环境模式，以提高可扩展性和安全性。我们从通过 ztunnel 实现的 L4 安全性和可观察性开始，实现了集群内流量的自动加密和透明的流量监控。通过有选择地启用 L7 功能并将代理与应用程序分离，我们实现了无缝扩展并降低了资源利用率和延迟。这种方法使开发人员能够专注于应用程序开发，从而实现由环境模式支持的更具弹性、更安全、更可扩展的平台。**

— [Jose Marque](https://www.linkedin.com/in/jdcmarques/), Senior DevOps at Blip.pt
— [Jose Marque](https://www.linkedin.com/in/jdcmarques/)，Blip.pt 高级 DevOps 人员
{{< /quote >}}

{{< quote >}}
**We are using Istio to ensure strict mTLS L4 traffic in our mesh and we are excited for ambient mode. Compared to sidecar mode it's a massive save on resources and at the same time it makes configuring things even more simple and transparent.**
**我们正在使用 Istio 来确保网格中严格的 mTLS L4 流量，我们对环境模式感到很兴奋。与 Sidecar 模式相比，它节省了大量资源，同时使配置变得更加简单和透明。**

— [Andrea Dolfi](https://www.linkedin.com/in/andrea-dolfi-58b427128/), DevOps Engineer
— [Andrea Dolfi](https://www.linkedin.com/in/andrea-dolfi-58b427128/)，DevOps 工程师
{{< /quote >}}

## What is in scope?
## 范围是什么？

The general availability of ambient mode means the following things are now considered stable:
环境模式的普遍可用性意味着以下事项现在被认为是稳定的：

- [Installing Istio with support for ambient mode](/docs/ambient/install/), with Helm or `istioctl`.
- [Adding your workloads to the mesh](/docs/ambient/usage/add-workloads/) to gain mutual TLS with cryptographic identity, [L4 authorization policies](/docs/ambient/usage/l4-policy/), and telemetry.
- [Configuring waypoints](/docs/ambient/usage/waypoint/) to [use L7 functions](/docs/ambient/usage/l7-features/) such as traffic shifting, request routing, and rich authorization policy enforcement.
- Connecting the Istio ingress gateway to workloads in ambient mode, supporting the Kubernetes Gateway APIs and all existing Istio APIs.
- Using waypoints for controlled mesh egress
- Using `istioctl` to operate waypoints, and troubleshoot ztunnel & waypoints.
- [使用 Helm 或 `istioctl` 安装支持环境模式的 Istio](/docs/ambient/install/)。
- [将工作负载添加到网格](/docs/ambient/usage/add-workloads/)，以获得具有加密身份、[L4 授权策略](/docs/ambient/usage/l4-policy/) 和遥测的双向 TLS。
- [配置航点](/docs/ambient/usage/waypoint/) 以 [使用 L7 功能](/docs/ambient/usage/l7-features/)，例如流量转移、请求路由和丰富的授权策略实施。
- 将 Istio 入口网关连接到环境模式下的工作负载，支持 Kubernetes 网关 API 和所有现有的 Istio API。
- 使用航点进行受控网格出口
- 使用 `istioctl` 操作航点，并排除 ztunnel 和航点故障。

Refer to the [feature status page](docs/releases/feature-stages/#ambient-mode) for more information.
有关更多信息，请参阅[功能状态页面]（docs/releases/feature-stages/#ambient-mode）。

### Roadmap
### 路线图

We are not standing still! There are a number of features that we continue to work on for future releases, including some that are currently in Alpha/Beta.
我们不会止步不前！我们将继续为未来版本开发许多功能，包括目前处于 Alpha/Beta 阶段的一些功能。

In our upcoming releases, we expect to move quickly on the following extensions to ambient mode:
在我们即将发布的版本中，我们希望快速实现以下环境模式的扩展：

- Full support for sidecar and ambient mode interoperability
- Multi-cluster installations
- Multi-network support
- VM support
- 全面支持 Sidecar 和环境模式互操作性
- 多集群安装
- 多网络支持
- VM 支持

## What about sidecars?
## 那么边车呢？

Sidecars are not going away, and remain first-class citizens in Istio. You can continue to use sidecars, and they will remain fully supported. While we believe most use cases will be best served with a mesh in ambient mode, the Istio project remains committed to ongoing sidecar mode support.
Sidecar 不会消失，它仍然是 Istio 的一等公民。您可以继续使用 Sidecar，它们仍将得到全面支持。虽然我们认为大多数用例最适合使用环境模式下的网格，但 Istio 项目仍致力于持续支持 Sidecar 模式。

## Try ambient mode today
## 今天尝试氛围模式

With the 1.24 release of Istio and the GA release of ambient mode, it is now easier than ever to try out Istio on your own workloads.
随着 Istio 1.24 版本的发布和环境模式的 GA 版本的发布，现在可以比以往更轻松地在您自己的工作负载上试用 Istio。

- Follow the [getting started guide](/docs/ambient/getting-started/) to explore ambient mode.
- Read our [user guides](/docs/ambient/usage/) to learn how to incrementally adopt ambient for mutual TLS & L4 authorization policy, traffic management, rich L7 authorization policy, and more.
- Explore the [new Kiali 2.0 dashboard](https://medium.com/kialiproject/kiali-2-0-for-istio-2087810f337e) to visualize your mesh.
- 按照 [入门指南](/docs/ambient/getting-started/) 探索环境模式。
- 阅读我们的 [用户指南](/docs/ambient/usage/) 了解如何逐步采用环境模式来实现相互 TLS 和 L4 授权策略、流量管理、丰富的 L7 授权策略等。
- 探索 [新的 Kiali 2.0 仪表板](https://medium.com/kialiproject/kiali-2-0-for-istio-2087810f337e) 以可视化您的网格。

You can engage with the developers in the #ambient channel on [the Istio Slack](https://slack.istio.io), or use the discussion forum on [GitHub](https://github.com/istio/istio/discussions) for any questions you may have.
您可以在 [Istio Slack](https://slack.istio.io) 上的 #ambient 频道与开发人员交流，或者使用 [GitHub](https://github.com/istio/istio/discussions) 上的讨论论坛来解答您的任何问题。
