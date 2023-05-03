---
title: Istio 中安全管控出口流量，第三部分
subtitle: 管控出口流量的备选方案比较，包括性能因素
description: 管控出口流量的备选方案比较，包括性能因素。
publishdate: 2019-07-22
attribution: Vadim Eisenberg (IBM)
keywords: [traffic-management,egress,security,gateway,tls]
target_release: 1.2
---

欢迎来看在 Istio 对出口流量进行安全管控系列文章的第 3 部分。
在 [这个系列文章的第一部分](/zh/blog/2019/egress-traffic-control-in-istio-part-1/)，我提出了出口流量相关攻击和我们针对出口流量进行安全管控收集的要求点。
在 [这个系列文章的第二部分](/zh/blog/2019/egress-traffic-control-in-istio-part-2/)，我展示了 Istio 的对安全出口流量方案，并且展示了使用 Istio 如何来阻止攻击。

在这一期中，我对 Istio 出口流量安全管控方案和其它的方案进行了对比，比如使用 Kubernetes 网络策略和已有的出口代理和防火墙。最后我讲述了 Istio 中安全管控出口流量的性能因素。

## 出口流量管控的其它解决方案 {#alternative-solutions-for-egress-traffic-control}

首先，我们回想一下我们之前收集的 [出口流量管控要求](/zh/blog/2019/egress-traffic-control-in-istio-part-1/#requirements-for-egress-traffic-control)：

1. 用 [SNI](https://en.wikipedia.org/wiki/Server_Name_Indication) 或者用 [TLS 源](/zh/docs/reference/glossary/#tls-origination) 来支持 [TLS](https://en.wikipedia.org/wiki/Transport_Layer_Security)。
1. **监控** SNI 和每个出口访问的 workload 源。
1. 定义和执行 **每个集群的策略**。
1. 定义和执行 **每个源的策略**，Kubernetes 可感知。
1. **阻止篡改**。
1. 对应用程序来说流量管控是 **透明的**。

接下来，将会介绍两种出口流量管控的备选方案：Kubernetes 网络策略和出口代理与防火墙。展示了上述要求中哪些是它们满足的，更重要的是那些要求是它们不能满足的。

Kubernetes 通过 [网络策略](https://kubernetes.io/zh-cn/docs/concepts/services-networking/network-policies/) 提供了一个流量管控的原生方案，特别是对出口流量管控。使用这些网络策略，集群运维人员可以配置那个 pod 可以访问指定的外部服务。
集群运维人员可以通过 pod 标签、命名空间标签或者 IP 范围来识别 pod。集群运维人员可以使用 IP 范围来明确外部服务，但是不能使用像 `cnn.com` 这样的域名来指定外部服务。因为 **Kubernetes 网络策略对 DNS 无感知**。
网络策略可以满足第一个要求，因为它可以管控任何 TCP 流量。网络策略只能部分满足第三和第四点要求，因为集群运维人员可以针对每个集群或者每个 pod 制定策略，但是运维人员无法用域名来标示外部服务。
只有当攻击者无法从恶意容器进入 Kubernetes 节点并干扰该节点内策略的执行时，网络策略才满足第五个要求。
最近，网络策略满足了第六点要求：运维人员不需要修改代码或者容器环境。总之，我们能说 Kubernetes 网络策略提供了透明的、Kubernetes 可感知的出口流量管控，但不是 DNS 可感知的。

第二种是比 Kubernetes 早的备选方案。使用 **DNS 可感知的出口代理或者防火墙** 允许配置应用程序将流量定向到代理并使用某些代理协议，例如：[SOCKS](https://en.wikipedia.org/wiki/SOCKS)。
因为运维人员必须配置应用程序，这个解决方案不是透明的。而且运维人员使用 pod 标签或者 pod 服务账号来配置代理，因为出口代理是不知道它们的。因此 **出口网关不是 Kubernetes 可感知的** 并且不能满足第四点要求，因为如果 Kubernetes 组件指定源，出口代理不能通过源执行策略。
总结一下，出口代理能满足第一、二、三和五的要求，但是不能满足第四和六的要求，因为它们不能对应用程序透明并且不能被 Kubernetes 感知。

## Istio 出口流量管控的优势 {#advantages-of-Istio-egress-traffic-control}

Istio 出口流量管控是 **DNS 可感知的**：你可以基于 URL 或者泛域名（像 `*.ibm.com`）来定义策略。从这个点上说，Istio 的方案比不能 DNS 感知的 Kubernetes 网络策略方案要好。

Istio 出口流量管控对 TLS 流量是 **透明的**，因为 Istio 是透明的：不需要改变应用程序或者配置容器。
对于有 TLS 源的 HTTP 流量，你必须配置网格中的应用程序配置使用 HTTP，不能使用 HTTPS。

Istio 出口流量管控是 **Kubernetes 可感知的**：出口流量源的身份是基于 Kubernetes 服务账号的。Istio 出口流量管控比现有的 DNS 感知的代理或者防火墙要好，因为它们都是不透明的，也不是 Kubernetes 可感知的。

Istio 出口流量管控是 **安全的**：它基于 Istio 的强身份认证，当使用[附加安全措施](/zh/docs/tasks/traffic-management/egress/egress-gateway/#additional-security-considerations)时，Istio 的流量管控具有防篡改功能。

另外，Istio 的出口流量管控提供了以下的优势：

- 对入口、出口和集群内流量用同一种语言定义访问策略。对所有类型的流量只需要学习一种策略和配置语言。
- 集成了 Istio 策略的出口流量管控功能和可观测性适配器，开箱即用。
- 用于外部监控或者访问管控系统的 Istio 适配器只需要编写一次，就可以把他们应用在所有类型的流量上：入口，出口和集群内。
- 对出口流量使用 Istio [流量管理特性](/zh/docs/concepts/traffic-management/)：负载均衡，被动和主动的健康检查，熔断，超时，重试，故障注入等等。

我们将具有上述优点的系统称为 **Istio 可感知**。

下表总结了 Istio 和备选方案提供的出口流量管控特性：

| | Istio 出口流量管控 | Kubernetes 网络策略 | 现有出口代理或防火墙 |
| --- | --- | --- | ---|
| DNS 可感知 | {{< checkmark_icon >}} | {{< cancel_icon >}} | {{< checkmark_icon >}} |
| Kubernetes 可感知 | {{< checkmark_icon >}} | {{< checkmark_icon >}} | {{< cancel_icon >}} | {
| 透明 | {{< checkmark_icon >}} | {{< checkmark_icon >}} | {{< cancel_icon >}} |
| Istio 可感知 | {{< checkmark_icon >}} | {{< cancel_icon >}} | {{< cancel_icon >}} |

## 性能因素 {#performance-considerations}

使用 Istio 管控出口流量有一个代价：增加对外部服务调用的延时和集群 pod 的 CPU 使用率。
流量穿过了两层代理：

- 应用程序的 sidecar 代理
- 出口网关的代理

如果你使用[泛域名 TLS 出口流量](/zh/docs/tasks/traffic-management/egress/wildcard-egress-hosts/)，你必须在应用程序和外部服务之间增加[附加代理](/zh/docs/tasks/traffic-management/egress/wildcard-egress-hosts/#wildcard-configuration-for-arbitrary-domains)。因为出口网关代理和需要使用通配符配置任意域的代理之间的流量是在 pod 的本地网络，那部分流量不应该对延迟有显著影响。

请参阅为管控出口流量设置不同 Istio 配置的[性能评估](/zh/blog/2019/egress-performance/)。我鼓励你在决定是否能够承担你用例的性能开销之前，仔细评估你自己的应用程序和外部服务的不同配置。你应该权衡所需的安全级别与性能要求，并比较所有备选方案的性能开销。

让我来分享我对使用 Istio 管控出口流量后带来性能开销的想法：
访问外部服务已经有比较高的延时和增加的开销，由于集群内的 2 个或者 3 个代理很可能相比之下没有那么重要。
毕竟，采用微服务架构的应用程序可以在微服务之间有多次调用的链路。因此，在出口网关上增加 1 个或者 2 个代理不应该有很大的影响。

此外，我们继续在优化减少 Istio 的性能开销。
可能的优化措施包括：

- 扩展 Envoy，让它来处理泛域名：这可以消除上面场景中应用程序和外部服务的代理。
- 如果流量已加密，那么就只使用双边 TLS 进行身份验证而不加密 TLS 流量。

## 总结 {#summary}

希望读完这个系列的文章，可以说服你认同，对于集群安全来说管控出口流量是非常重要的。
更希望，我可以说服你认同 Istio 对安全的管控出口流量是一个非常有用的工具，并且 Istio 比其它备选方案有很多优势。
Istio 是我所知的唯一解决方案，它可以让你：

- 以安全和透明的方式管控出口流量
- 用域名明确外部服务
- 使用 Kubernetes 组件来明确流量源

以我之见，如果你在寻找你的第一个 Istio 应用场景，安全管控出口流量是一个非常好的选择。在这个场景中，Istio 甚至在你使用它所有其它功能之前就已经为你提供了一些优势：
[流量管理](/zh/docs/tasks/traffic-management/)，[安全性](/zh/docs/tasks/security/)，[策略](/zh/docs/tasks/policy-enforcement/)和[可观测性](/zh/docs/tasks/observability/)，上面的功能都可以用在在集群内的微服务之间的流量上。

所以，如果你还没有机会使用 Istio，那就在你集群上[安装 Istio](/zh/docs/setup/install/) 并且检查[出口流量管控任务](/zh/docs/tasks/traffic-management/egress/)再执行其它 [Istio 特性](/zh/docs/tasks/)的任务。我们也想收到你的反馈，请在 [discuss.istio.io](https://discuss.istio.io) 加入我们。
