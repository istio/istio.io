---
title: "Ambient Mesh 安全深入探讨"
description: "深入研究最近发布的 Istio 无边车数据平面 Ambient Mesh 的安全隐患。"
publishdate: 2022-09-07T09:00:00-06:00
attribution: "Ethan Jackson (Google), Yuval Kohavi (Solo.io), Justin Pettit (Google), Christian Posta (Solo.io)"
keywords: [ambient]
---

We recently announced Istio ambient mesh which is a sidecar-less data plane for Istio. As [stated in the announcement blog](/blog/2022/introducing-ambient-mesh/), the top concerns we address with ambient mesh are simplified operations, broader application compatibility, reduced infrastructure costs and improved performance. When designing the ambient data plane, we wanted to carefully balance the concerns around operations, cost, and performance while not sacrificing security or functionality. As the components of ambient run outside of the application pods, the security boundaries have changed -- we believe for the better. In this blog, we go into some detail about these changes and how they compare to a sidecar deployment.
我们最近发布了 Istio Ambient Mesh，它是一种 Istio 的无边车数据平面。
正如在[公告博客](/zh/blog/2022/introducing-ambient-mesh/)中的所述，
我们对 Ambient Mesh 的首要关注是简化操作、更广泛的应用程序兼容性、
降低基础设施成本以及提高性能。在设计 Ambient 数据平面时，
我们希望在不牺牲安全性或功能的情况下仔细思考对于操作、
成本和性能的平衡。随着 Ambient 的组件在应用程序 Pod 之外运行，
安全边界发生了变化 ——我们相信会变得更好。在此博客中，
我们将详细介绍这些更改以及它们与 Sidecar 部署模式的比较。

{{< image
    link="./ambient-layers.png"
    caption="Ambient Mesh 数据平面的分层"
    >}}

To recap, Istio ambient mesh introduces a layered mesh data plane with a secure overlay responsible for transport security and routing, that has the option to add L7 capabilities for namespaces that need them.
回顾一下，Istio Ambient Mesh 引入了一个分层的网格数据平面，
它带有一个负责传输安全和路由的安全覆盖层，它可以选择为需要它们的命名空间添加 L7 功能。
To understand more, please see the [announcement blog](/blog/2022/introducing-ambient-mesh/) and the [getting started blog](/blog/2022/get-started-ambient).
要了解更多信息，
请参阅[公告博客](/zh/blog/2022/introducing-ambient-mesh/)和[入门博客](/zh/blog/2022/get-started-ambient)。
The secure overlay consists of a node-shared component, the ztunnel, that is responsible for L4 telemetry and mTLS which is deployed as a DaemonSet.
安全覆盖由一个节点共享组件 ztunnel 组成，
它负责 L4 遥测以及部署为 DaemonSet 的 mTLS。
The L7 layer of the mesh is provided by waypoint proxies, full L7 Envoy proxies that are deployed per identity/workload type.
网格的 L7 层由路点代理提供，这是按身份/工作负载类型部署的完整 L7 Envoy 代理。
Some of the core implications of this design include:
此设计的一些核心含义包括：

* Separation of application from data plane
* 应用程序与数据平面的分离
* Components of the secure overlay layer resemble that of a CNI
* 安全覆盖层组件与 CNI 组件类似
* Simplicity of operations is better for security
* 简化操作更有利于安全
* Avoiding multi-tenant L7 proxies
* 避免多租户 L7 代理
* Sidecars are still a first-class supported deployment
* Sidecar 模式仍然是首推部署模式

## Separation of application and data plane
## 应用和数据平面分离 {#separation-of-application-and-data-plane}

Although the primary goal of ambient mesh is simplifying operations of the service mesh, it does serve to improve security as well. Complexity breeds vulnerabilities and enterprise applications (and their transitive dependencies, libraries, and frameworks) are exceedingly complex and prone to vulnerabilities. From handling complex business logic to leveraging OSS libraries or buggy internal shared libraries, a user's application code is a prime target for attackers (internal or external). If an application is compromised, credentials, secrets, and keys are exposed to an attacker including those mounted or stored in memory. When looking at the sidecar model, an application compromise includes takeover of the sidecar and any associated identity/key material. In the Istio ambient mode, no data plane components run in the same pod as the application and therefore an application compromise does not lead to the access of secrets.
尽管 Ambient Mesh 的主要目标是简化服务网格的操作，
但它确实也有助于提高安全性。复杂性升高将滋生漏洞，企业应用程序（及其可传递依赖项、
库和框架）极其复杂且容易出现漏洞。从处理复杂的业务逻辑到利用 OSS
库或有缺陷的内部共享库，用户的应用程序代码是攻击者（内部或外部）的主要目标。
如果应用程序遭到破坏，凭证、机密和密钥就会暴露给攻击者，
还包括那些安装或存储在内存中的内容。在查看 Sidecar 模型时，
应用程序妥协包括接管 Sidecar 和任何相关的身份/密钥材料。
在 Istio Ambient 模式下，没有数据平面组件与应用程序在同一个 Pod 中运行，
因此应用程序的妥协不会导致机密内容被访问。

What about Envoy Proxy as a potential target for vulnerabilities? Envoy is an extremely hardened piece of infrastructure under intense scrutiny and [run at scale in critical environments](https://www.infoq.com/news/2018/12/envoycon-service-mesh/) (e.g., [used in production to front Google's network](https://cloud.google.com/load-balancing/docs/https)). However, since Envoy is software, it is not immune to vulnerabilities.  When those vulnerabilities do arise, Envoy has a robust CVE process for identifying them, fixing them quickly, and rolling them out to customers before they have the chance for wide impact.
当 Envoy 代理被作为漏洞的潜在目标怎么样？Envoy 是一个非常稳固的基础设施，
并受到严格审查，[在关键环境中大规模运行](https://www.infoq.com/news/2018/12/envoycon-service-mesh/)（例如，
[在谷歌用于生产环境中的网络前端](https://cloud.google.com/load-balancing/docs/https)）。
但是，由于 Envoy 也是软件，因此它无法避免漏洞。当这些漏洞确实出现时，
Envoy 有一个强大的 CVE 流程来识别它们，快速修复它们，
并在它们有机会产生广泛影响之前将它们推广给客户。

Circling back to the earlier comment that "complexity breeds vulnerabilities", the most complex parts of Envoy Proxy is in its L7 processing, and indeed historically the majority of Envoy’s vulnerabilities have been in its L7 processing stack. But what if you just use Istio for mTLS? Why take the risk of deploying a full-blown L7 proxy which has a higher chance of CVE when you don't use that functionality? Separating L4 and L7 mesh capabilities comes into play here. While in sidecar deployments you adopt all of the proxy, even if you use only a fraction of the functionality, in ambient mode we can limit the exposure by providing a secure overlay and only layering in L7 as needed. Additionally, the L7 components run completely separate from the applications and do not give an attack avenue.
回到之前关于“复杂性滋生漏洞”的评论，Envoy 代理最复杂的部分是在其 L7 处理中，
事实上，从历史上看，Envoy 的大部分漏洞都在其 L7 处理堆栈中。
但是，如果您只是将 Istio 用于 mTLS 又当如何？当您不使用相关功能时，
为什么要冒险部署具有更高 CVE 机会的成熟 L7 代理？分离 L4 和 L7
网格功能在这里发挥作用。在 Sidecar 部署模式中，即使您只使用一小部分功能，
您也要采用所有代理，但在 Ambient 模式下，我们可以通过提供安全覆盖和仅根据需要在
L7 中分层来限制暴露。此外，L7 组件与应用程序完全分开运行，不会提供攻击途径。

## Pushing L4 down into the CNI
## 将 L4 支持推进到 CNI {#pushing-l4-down-into-the-cni}

The L4 components of the ambient data plane run as a DaemonSet, or one per node. This means it is shared infrastructure for any of the pods running on a particular node. This component is particularly sensitive and should be treated at the same level as any other shared component on the node such as any CNI agents, kube-proxy, kubelet, or even the Linux kernel. Traffic from workloads is redirected to the ztunnel which then identifies the workload and selects the right certificates to represent that workload in a mTLS connection.
Ambient 数据平面的 L4 组件作为 DaemonSet 运行，或者按照每个节点来运行。
这意味着它是在特定节点上与其他 Pod 共享基础设施的方式运行的。由于该组件特别敏感，
应与节点上的任何其他共享组件（例如任何 CNI 代理、kube-proxy、kubelet 甚至
Linux 内核）处于同一级别。来自工作负载的流量被重定向到 ztunnel，ztunnel
然后识别工作负载并选择正确的证书来表示 mTLS 连接中的该工作负载。

The ztunnel uses a distinct credential for every pod which is only issued if the pod is currently running on the node. This ensures that the blast radius for a compromised ztunnel is that only credentials for pods currently scheduled on that node could be stolen. This is a similar property to other well implemented shared node infrastructure including other secure CNI implementations. The ztunnel does not use cluster-wide or per-node credentials which, if stolen, could immediately compromise all application traffic in the cluster unless a complex secondary authorization mechanism is also implemented.
ztunnel 为每个 Pod 提供不同的凭证，只有当 Pod 当前在节点上运行时才会颁发。
这确保了受损 ztunnel 的爆炸半径是只有当前安排在该节点上的 Pod 的凭据可以被盗。
这是与其他实现良好的共享节点基础设施（包括其他安全 CNI 实现）类似的属性。
ztunnel 不使用集群范围或每个节点的凭据，如果这些凭据被盗，
可能会立即危及集群中的所有应用程序流量，除非还实施了复杂的辅助授权机制。

If we compare this to the sidecar model, we notice that the ztunnel is shared and compromise could result in exfiltration of the identities of the applications running on the node. However, the likelihood of a CVE in this component is lower than that of an Istio sidecar since the attack surface is greatly reduced (only L4 handling); the ztunnel does not do any L7 processing. In addition, a CVE in a sidecar (with a larger attack surface with L7) is not truly contained to only that particular workload which is compromised. Any serious CVE in a sidecar is likely repeatable to any of the workloads in the mesh as well.
如果我们将其与 Sidecar 模型进行比较，我们会注意到 ztunnel 是共享的，
妥协可能会导致节点上运行的应用程序的身份泄露。但是，此组件中出现
CVE 的可能性低于 Istio Sidecar，因为攻击面大大减少（仅 L4 处理）；
ztunnel 不做任何 L7 处理。 此外，Sidecar 中的 CVE（具有更大的 L7
攻击面）并没有真正包含在被破坏的特定工作负载中。sidecar 中任何严重的
CVE 也可能对网格中的任何工作负载重复。

## Simplicity of operations is better for security
## 简化操作更有利于安全 {#simplicity-of-operations-is-better-for-security}

Ultimately, Istio is a critical piece of infrastructure that must be maintained. Istio is trusted to implement some of the tenets of zero-trust network security on behalf of applications and rolling out patches on a schedule or on demand is paramount. Platform teams often have predictable patching or maintenance cycles which is quite different from that of applications. Applications likely get updated when new capabilities and functionality are required and usually part of a project. This approach to application changes, upgrades, framework and library patches, is highly unpredictable, allows a lot of time to pass, and does not lend itself to safe security practices. Therefore, keeping these security features part of the platform and separate from the applications is likely to lead to a better security posture.
最终，Istio 仍然是必须维护的基础设施的关键部分。Istio
被信任代表应用程序实施零信任网络安全的一些原则，并且按计划或按需推出补丁是最重要的。
平台团队通常有可预测的补丁或维护周期，这与应用程序的周期大不相同。
当需要新的能力和功能并且通常是项目的一部分时，应用程序可能会得到更新。
这种应用程序更改、升级、框架和库补丁的方法是高度不可预测的，
允许大量时间过去，并且不适合安全的安全实践。因此，
将这些安全功能保留在平台的一部分并与应用程序分开可能会带来更好的安全态势。

As we've identified in the announcement blog, operating sidecars can be more complex because of the invasive nature of them (injecting the sidecar/changing the deployment descriptors, restarting the applications, race conditions between containers, etc). Upgrades to workloads with sidecars require a bit more planning and rolling restarts that may need to be coordinated to not bring down the application. With ambient mesh, upgrades to the ztunnel can coincide with any normal node patching or upgrades, while the waypoint proxies are part of the network and can be upgraded completely transparently to the applications as needed.
正如我们在公告博客中指出的那样，操作 Sidecar 可能会更加复杂，
因为它们具有侵入性（注入 Sidecar/更改部署描述符、重新启动应用程序、
容器之间的竞争条件等）。使用 Sidecar 升级到工作负载需要更多的计划和滚动重启，
这可能需要协调才能不导致应用程序崩溃。使用环境网格，对 ztunnel 
的升级可以与任何正常的节点修补或升级同时进行，而路点代理是网络的一部分，
可以根据需要完全透明地升级到应用程序。

## Avoiding multi-tenant L7 proxies
## 避免多租户 L7 代理 {#avoiding-multi-tenant-l7-proxies}

Supporting L7 protocols such as HTTP 1/2/3, gRPC, parsing headers, implementing retries, customizations with Wasm and/or Lua in the data plane is significantly more complex than supporting L4. There is a lot more code to implement these behaviors (including user-custom code for things like Lua and Wasm) and this complexity can lead to the potential for vulnerabilities. Because of this, CVEs have a higher chance of being discovered in these areas of L7 functionality.
支持 L7 协议，如 HTTP 1/2/3、gRPC、解析标头、实现重试、
在数据平面中使用 Wasm 和/或 Lua 进行自定义比支持 L4 复杂得多。
有更多的代码来实现这些行为（包括 Lua 和 Wasm 之类的用户自定义代码），
这种复杂性可能会导致潜在的漏洞。因此，CVE 更有可能在 L7 功能的这些区域被发现。

{{< image
    link="./ambient-l7-data-plane.png"
    caption="每个命名空间/身份都有自己的 L7 代理；没有多租户代理"
    >}}

In ambient mesh, we do not share L7 processing in a proxy across multiple identities. Each identity (service account in Kubernetes) has its own dedicated L7 proxy (waypoint proxy) which is very similar to the model we use with sidecars. Trying to co-locate multiple identities and their distinct complex policies and customizations adds a lot of variability to a shared resource which leads to unfair cost attribution at best and total proxy compromise at worst.
在 Ambient Mesh 中，我们不会在代理中跨多个身份共享 L7 处理。
每个身份（Kubernetes 中的服务帐户）都有自己专用的 L7
代理（路点代理），这与我们使用边车的模型非常相似。
尝试将多个身份及其独特的复杂策略和定制放在一起会给共享资源增加很多可变性，
这在最好的情况下会导致不公平的成本归因，在最坏的情况下会导致总代理妥协。

## Sidecars are still a first-class supported deployment
## Sidecar 模式仍然是首推部署模式 {#sidecars-are-still-a-first-class-supported-deployment}

We understand that some folks are comfortable with the sidecar model and their known security boundaries and wish to stay on that model. With Istio, sidecars are a first-class citizen to the mesh and platform owners have the choice to continue using them. If a platform owner wants to support both sidecar and ambient, they can. A workload with the ambient data plane can natively communicate with workloads that have a sidecar deployed. As folks better understand the security posture of ambient mesh, we are confident that ambient will be the preferred mode of Istio service mesh with sidecars used for specific optimizations.
我们知道有些人对 sidecar 模型和他们已知的安全边界感到满意，
并希望继续使用该模型。借助 Istio，sidecars 是网格的一等公民，
平台所有者可以选择继续使用它们。如果平台所有者想要同时支持边车和环境，
他们可以。具有环境数据平面的工作负载可以在本地与部署了边车的工作负载进行通信。
随着人们更好地了解环境网格的安全态势，我们相信环境将成为 Istio
服务网格的首选模式，并带有用于特定优化的边车。
