---
title: Ambient 和 Kubernetes NetworkPolicy
description: 了解 CNI 强制的 L4 Kubernetes NetworkPolicy 如何与 Istio 的 Ambient 模式交互。
weight: 20
owner: istio/wg-networking-maintainers
test: no
---

Kubernetes [NetworkPolicy](https://kubernetes.io/zh-cn/docs/concepts/services-networking/network-policies/)
允许您控制 L4 流量如何到达 Pod。

`NetworkPolicy` 通常由安装在集群中的 {{< gloss >}}CNI{{< /gloss >}} 强制执行。
Istio 不是 CNI，不强制执行或管理 `NetworkPolicy`，
并且在所有情况下都遵循它 - Ambient 不会且永远不会绕过 Kubernetes `NetworkPolicy` 的执行。

这意味着可以创建一个 Kubernetes `NetworkPolicy` 来阻止 Istio 流量，
或者以其他方式阻碍 Istio 功能，因此当一起使用 `NetworkPolicy` 和 Ambient 时，需要注意一些事项。

## Ambient 流量覆盖和 Kubernetes NetworkPolicy {#ambient-traffic-overlay-and-kubernetes-networkpolicy}

一旦您将应用程序被添加到 Ambient 网格，Ambient 的安全 L4 覆盖将通过端口 15008 在您的 Pod 之间传输流量。
一旦安全流量进入目标端口为 15008 的目标 Pod，流量将被代理回原始目标端口。

但是，`NetworkPolicy` 是在主机上强制执行的，在 Pod 之外。这意味着，
如果您已经存在 `NetworkPolicy`，例如，它将拒绝除 443 之外的每个端口上到 Ambient Pod 的入站流量，
则您必须为端口 15008 向该 `NetworkPolicy` 添加例外。
接收流量的 Sidecar 工作负载还需要允许端口 15008 上的入站流量，
以允许 Ambient 工作负载与它们通信。

例如，以下 `NetworkPolicy` 将阻止传入 {{< gloss >}}HBONE{{< /gloss >}} 到端口 15008 上的 `my-app` 的流量：

{{< text syntax=yaml snip_id=none >}}
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: my-app-allow-ingress-web
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: my-app
  ingress:
  - ports:
    - port: 8080
      protocol: TCP
{{< /text >}}

如果已将 `my-app` 添加到 Ambient 网格中，应改为：

{{< text syntax=yaml snip_id=none >}}
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: my-app-allow-ingress-web
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: my-app
  ingress:
  - ports:
    - port: 8080
      protocol: TCP
    - port: 15008
      protocol: TCP
{{< /text >}}

## Ambient、健康探测和 Kubernetes NetworkPolicy {#ambient-health-probes-and-kubernetes-networkpolicy}

Kubernetes 健康检查探测存在问题，并为 Kubernetes 流量策略创建了一个特殊案例。
它们源自在节点上作为进程运行的 kubelet，而不是集群中的其他 Pod。
它们是明文且不安全。kubelet 或 Kubernetes 节点通常都没有自己的加密身份，因此无法进行访问控制。
仅仅允许所有流量通过健康探测端口是不够的，因为恶意流量可以像 kubelet 一样轻松地使用该端口。
此外，许多应用程序使用相同的端口进行健康探测和合法应用程序流量，因此简单的基于端口的允许是不可接受的。

各种 CNI 实现以不同的方式解决这个问题，
并试图通过从正常策略执行中默默排除 kubelet 健康探测或为其配置策略例外来解决这个问题。

在 Istio Ambient 中，这个问题通过结合使用 iptables 规则和源网络地址转换（SNAT）来解决，
以便仅重写可证明来自具有固定链路本地 IP 的本地节点的数据包，
以便 Istio 策略实施可以明确忽略它们作为不安全的健康探测流量。
链路本地 IP 被选为默认 IP，因为它们通常会被忽略以进行入口-出口控制，
并且[根据 IETF 标准](https://datatracker.ietf.org/doc/html/rfc3927)无法在本地子网之外路由。

当您将 Pod 添加到 Ambient 网格时，此行为是透明启用的，默认情况下，
Ambient 使用链接本地地址 `169.254.7.127` 来识别并正确允许 kubelet 健康探测数据包。

但是，如果您的工作负载、命名空间或集群具有预先存在的入口或出口 `NetworkPolicy`，
则根据您使用的 CNI，具有此链接本地地址的数据包可能会被显式 `NetworkPolicy` 阻止，
这将导致您的应用程序 Pod 健康探测在您将 Pod 添加到 Ambient 网格时开始失败。

例如，在命名空间中应用以下 `NetworkPolicy` 将阻止所有到 `my-app` Pod 的流量（Istio 或其他），
包括 kubelet 健康探测器。根据您的 CNI，kubelet 探测器和链接本地地址可能会被此策略忽略，或被其阻止：

{{< text syntax=yaml snip_id=none >}}
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-ingress
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: my-app
  policyTypes:
  - Ingress
{{< /text >}}

一旦 Pod 注册到 Ambient 网格中，健康探测数据包将开始通过 SNAT 分配一个链接本地地址，
这意味着健康探测可能会开始被 CNI 的 `NetworkPolicy` 实现阻止。
要允许 Ambient 健康探测绕过 `NetworkPolicy`，
请通过将 Ambient 用于此流量的链接本地地址列入允许列表来明确允许从主机节点到 Pod 的流量：

{{< text syntax=yaml snip_id=none >}}
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-ingress-allow-kubelet-healthprobes
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: my-app
  ingress:
    - from:
      - ipBlock:
          cidr: 169.254.7.127/32
{{< /text >}}
