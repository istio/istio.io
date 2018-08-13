---
title: 在 Istio 下使用 Network Policy（网络授权策略）
description: Kubernetes 中的 Network Policy 如何与 Istio 策略关联。
publishdate: 2017-08-10
subtitle:
attribution: Spike Curtis
weight: 97
---

对 Kubernetes 上的应用使用 Network Policy 来保证安全是广泛使用的工业化最佳实践之一。Istio 也支持 policy（授权策略）,我们这里会花些时间来说明 Istio 中的授权策略和 Kubernetes 中的 Network Policy 是如何相互影响，相互支持，从而保障应用的安全性的。

首先我们先来看一些基础：为什么你会想同时使用 Istio 和 Kubernetes 的呢？问题的答案在于它们善于处理不同的事情。以下是 Istio 和 Network Policy 的最大区别(这里只考虑"典型"实现，比如，Calico，但是实现的细节会根据 network providers 的不同而不同)

|                       | Istio 授权策略      | Network Policy     |
| --------------------- | ----------------- | ------------------ |
| **网络层**             | "服务层" --- 七层  | "网路层" --- 三-四层 |
| **实现**    | 用户态        | 内核态             |
| **作用范围** | Pod               | 节点               |

## 网络层

Istio 授权策略作用在应用的“服务”层。在OSI模型中，这属于第七层，但是事实上，在云原生应用中，第七层实际上包括了至少两层：服务层和内容层。服务层的典型代表是HTTP，它包裹了实际的应用数据（内容层）。Istio 的 Envoy 代理就是在这一层生效的。相比较下，Network Policy 在 OSI 模型的第三层（网络）和第四层（传输）生效。

由于 Envoy 工作在七层，它能够解析协议,包括HTTP/1.1 和 HTTP/2(gRPC 基于HTTP/2)。这样 Envoy 能够提供丰富的授权策略，例如你可以依据虚拟主机，URL,或者 HTTP header来制定策略。在未来，Istio 会支持更多的七层协议，同时也会支持通用的 TCP 和 UDP 传输。

相比较于灵活，因为所有的网络应用都使用 IP，在网络层的授权策略优势是通用。在网络层，你可以完全不用考虑七层协议例如DNS,SQL 数据库，实时流，还有一些不使用HTTP的服务。使用 Network Policy 不仅仅局限在传统的三元组：IP,协议，端口。和 Istio 一样，Network Policy 还知道用于描述 pod endpoints 的 Kubernetes 标签。

## 实现

Istio 的代理是基于 [Envoy](https://envoyproxy.github.io/envoy/) 的，它是一个在数据面的用户态进程，它通过标准的套接字和网络层交互。这样使得 Envoy 拥有很大的灵活性，并且能够部署在容器中。

Network Policy 数据面是典型的内核空间实现（例如：使用 iptables， eBPF 过滤器，甚至是特定的内核模块）内核态的好处是非常快，缺点是没有 Envoy 那么灵活。

## 执行点

Envoy proxy 的策略执行是在 pod 内实现的，它会作为与容器在相同网络命名空间下的 sidecar 。这样部署模式比较简单。有的容器有权限重新配置 pod 内的网络(CAP_NET_ADMIN)。如果这样的服务实例被攻击了，或者是有异常行为(就像在恶意的租户中一样)，Envoy 代理会被绕过。

但是这只要它们正确配置的话，并不会让攻击者能够访问其他使用 Istio 的 pods，于是在劫持了 pod 后它几个攻击目标如下：
- 攻击没有保护的 pods
- 尝试通过大量流量来让受保护的 pods 拒绝服务
- 篡改 pod 中收集的数据
- 攻击集群基础设施(服务器或者是 Kubernetes 服务)
- 攻击网格之外的服务，例如数据库，存储，或者是遗留系统。

Network Policy 通常在主机节点上执行，它是在 pods 的网络命名空间之外的。这也就是说那些被攻击或者行为不正常的 pods 必须打破根命名空间来避免强制执行。随着 Kubernetes 1.8 增加了 egress 策略，这个差异让网络策略成为来保护你的基础设施免受于攻击的关键所在。

## 例子

让我们来看几个使用来 Istio 同时也使用 Kubernetes Network Policy 的例子。这里使用 Bookinfo 实例应用。我们会覆盖 Network Policy 的以下使用场景：
- 减少应用 ingress 的被攻击面
- 在应用程序中实施细粒度隔离

### 减少应用 ingress 的被攻击面

我们的应用 ingress 控制器是我们应用与外界主要的入口点。下面是个简单的例子展示了如何定义 Istio ingress(用在 Istio 的安装中)

{{< text yaml >}}
apiVersion: v1
kind: Service
metadata:
  name: istio-ingress
  labels:
    istio: ingress
spec:
  type: LoadBalancer
  ports:
  - port: 80
    name: http
  - port: 443
    name: https
  selector:
    istio: ingress
{{< /text >}}

Istio-ingress 暴露端口80和443。让我们把入口流量限制在这两个端口上。Envoy 有 [内建的管理接口](https://www.envoyproxy.io/docs/envoy/latest/operations/admin.html#operations-admin-interface)，我们并不想由于错误配置 istio-ingress 镜像,以至于不小心把我们的管理接口暴露到外界。这是个在深度上防御的例子：一个合理配置的镜像不应该暴露接口，并且一个合理配置的 Network Policy 会防止任何人连上它。这两个只要有一个正确配置，我们就能受到保护。

{{< text yaml >}}
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: istio-ingress-lockdown
  namespace: default
spec:
  podSelector:
    matchLabels:
      istio: ingress
  ingress:
  - ports:
    - protocol: TCP
      port: 80
    - protocol: TCP
      port: 443
{{< /text >}}

### 在应用程序中实施细粒度隔离

下图展示了 Bookinfo 这个应用
{{< image width="80%" ratio="59.08%"
    link="/docs/examples/bookinfo/withistio.svg"
    caption="Bookinfo Service Graph"
    >}}

图中展示了这个程序正常情况下允许使用的所有连接。所有的其他连接，例如从 Istio Ingress 到 Rating 服务，都不是应用的一部分。我们关闭这些连接，这样它们就不能够被攻击者使用了。想象一下，例如，Ingress pod 受到攻击者的攻击，攻击者能够运行任何的代码。如果我们只允许 Product Page pods 使用 Network Policy，这样即使攻击者已经挟持了 service mesh 中的一部分，他们也无法获得应用后端的访问权限。

{{< text yaml >}}
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: product-page-ingress
  namespace: default
spec:
  podSelector:
    matchLabels:
      app: productpage
  ingress:
  - ports:
    - protocol: TCP
      port: 9080
    from:
    - podSelector:
        matchLabels:
          istio: ingress
{{< /text >}}

你可以并且应该为每一个服务写类似的策略来保证 pods 之间的安全。

## 总结

我们认为，Istio 和 Network Policy 在安全策略上有不同的优势。Istio 是感知应用协议的，具有较高的灵活性，使其成为支撑运维目标策略的理想选择，例如服务路由、重试、环路断开等等，同时也适用于应用层的安全，例如token验证。Network Policy 是通用的，高效的，并且在 pods 之间是隔离的，这使得它在网络安全方面的策略成为理想选择。进一步说，在不同的层有不同的策略的优点是，它赋予了每个网络层独立的上下文，并且独立运作而不用考虑其他网络层的事情。
这个博客是基于 Spike Curtis 的三篇博客系列完成的。他是 Tigera 的 Istio团队成员之一，完整的内容可以在这里找到：<https://www.projectcalico.org/using-network-policy-in-concert-with-istio/>

