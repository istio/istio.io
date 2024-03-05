---
title: 使用 ztunnel 实现 L4 联网和 mTLS 
description: Istio Ambient 使用 ztunnel 代理实现 L4 联网和 mTLS 的用户指南。
weight: 2
owner: istio/wg-networking-maintainers
test: no
---

{{< boilerplate ambient-alpha-warning >}}

## 简介  {#introsection}

本指南深入介绍了 Istio Ambient 网格中 ztunnel 代理和 4 层网络能力的功能和用法。
要简单地尝试 Istio Ambient 网格，请按照
[Ambient 快速入门](/zh/docs/ops/ambient/getting-started/)进行操作。
本指南遵循用户旅程并通过多个示例来详细介绍 Istio Ambient 的设计和架构。
强烈建议按顺序关注下面链接中的主题。

* [简介](#introsection)
* [当前注意事项](#caveats)
* [功能概述](#functionaloverview)
* [部署应用程序](#deployapplication)
* [监控 ztunnel 代理和 L4 网络](#monitoringzt)
* [L4 鉴权策略](#l4auth)
* [Ambient 与非 Ambient 端点的互操作性](#interop)

ztunnel（Zero Trust Tunnel，零信任隧道）组件是专门为 Istio Ambient
网格构建的基于每个节点的代理。由于工作负载 Pod 不再需要在 Sidecar
中运行代理也可以参与网格，因此 Ambient 模式下的 Istio
也被非正式地称为 “无 Sidecar” 网格。

{{< tip >}}
使用 Sidecar 代理的 Pod/工作负载可以与在 Ambient 模式下运行的 Pod 共存于同一网格内。
使用 Sidecar 代理的网格 Pod 还可以与同一 Istio 网格中以 Ambient 模式运行的 Pod 进行互操作。
Ambient 网格的概念是指具有功能超集的 Istio 网格，因此可以支持使用任一类型代理的网格 Pod。
{{< /tip >}}

ztunnel 节点代理负责安全连接和验证 Ambient 网格内的工作负载。
ztunnel 代理是用 Rust 语言编写的，旨在处理 Ambient 网格中的 L3 和 L4 功能，
例如 mTLS、身份验证、L4 鉴权和遥测。ztunnel 不会终止工作负载 HTTP
流量或解析工作负载 HTTP 标头。ztunnel 确保 L3 和 L4 流量高效、安全地传输到 **Waypoint 代理**，
其中实现了 Istio 的全套 L7 功能，例如 HTTP 遥测和负载均衡。
“安全覆盖网络（Secure Overlay Networking）”概念被非正式地用于统称通过
ztunnel 代理在 Ambient 网格中实现的 L4 网络功能集。
在传输层，这是通过一种称为 HBONE 的基于 HTTP CONNECT 的流量隧道协议来实现的，
HBONE 协议在本指南的[关于 HBONE](#hbonesection) 一节中进行说明。

Istio 在 Ambient 模式下的一些用例可以仅通过 L4 安全覆盖网络功能来解决，
并且不需要 L7 功能，因此不需要部署 Waypoint 代理。
其他需要高级流量管理和 L7 网络功能的用例将需要部署 Waypoint 代理。
本指南重点介绍与使用 ztunnel 代理的 L4 安全覆盖网络相关的功能。
本指南仅在需要描述某些 L4 ztunnel 功能时才引用 L7。
高级 L7 网络功能和 Waypoint 代理的详细使用将在其他指南中专门介绍。

| 应用程序部署用例 | Istio Ambient 网格配置 |
| ------------- | ------------- |
| 通过双向 TLS、客户端应用程序流量的加密和隧道数据传输实现零信任网络、L4 鉴权、L4 遥测 | 具有 ztunnel 代理网络的基线 Ambient 网格 |
| 应用程序需要 L4 双向 TLS 以及高级 Istio 流量管理功能（包括 VirtualService、L7 遥测、L7 鉴权） | 完整的 Istio Ambient 网格配置，包括基于 ztunnel 代理和 Waypoint 代理的网络 |

## 当前注意事项  {#caveats}

当使用其中一种支持的安装方法安装 Istio Ambient 网格时，会自动安装 ztunnel 代理。
Istio Ambient 模式所需的最低 Istio 版本是 `1.18.0`。
一般来说，Ambient 模式下的 Istio 支持 Sidecar 代理模式下支持的现有 Istio API。
由于 Ambient 功能当前处于 Alpha 版本级别，
因此以下是 Istio Ambient 功能当前版本（自 `1.19.0` 版本起）中的功能限制或警告列表。
预计在 Ambient 进入 Beta 版本并最终正式发布时，这些限制将被解决/移除。

1. **仅限 Kubernetes（K8s）：**目前仅支持 Istio Ambient 模式在 Kubernetes 集群上部署。
   目前不支持在虚拟机等非 Kubernetes 端点上部署。

1. **不支持 Istio 多集群：**Istio Ambient 模式当前仅支持单集群部署。

1. **K8s CNI 限制：**Ambient 模式下的 Istio 目前不适用于所有 Kubernetes CNI 实现。
   此外，对于某些插件，某些 CNI 功能（特别是 Kubernetes `NetworkPolicy` 和 Kubernetes 服务负载均衡功能）
   可能会在 Istio Ambient 模式存在的情况下被透明绕过。
   已被支持的 CNI 插件的明确集合以及任何 CNI 功能警告目前正在测试中，
   并将在 Istio Ambient 模式接近 Beta 版本时正式提供文档。

1. **仅限 TCP/IPv4：**在当前版本中，基于 IPv4 的 TCP 是
   Istio 安全覆盖隧道上唯一支持的传输协议（这包括在 TCP/IPv4 连接之上的应用程序层端点之间运行的 HTTP 等协议）。

1. **无法动态切换到 Ambient 模式：**Ambient 模式只能在使用 Ambient 配置文件或
   Ambient Helm 配置部署的新 Istio 网格控制平面上启用。
   例如，使用 Pre-Ambient 配置文件部署的现有 Istio 网格无法被动态切换至同时启用 Ambient 模式的状态。

1. **Istio `PeerAuthentication` 的限制：**截至撰写本文时，Istio Ambient 模式下的所有组件（即 Waypoint 代理）
   并不支持 `PeerAuthentication` 资源。因此，建议当前仅使用 `STRICT` mTLS 模式。
   与许多其他 Alpha 阶段的注意事项一样，随着该功能转向 Beta 状态，该问题应该会得到解决。

1. **istioctl CLI 差距：**在显示或监控 Istio Ambient 模式相关信息时，
   Istio CLI 输出显示等区域可能存在一些细微的功能差距。随着功能的成熟，这些问题将得到解决。

### 本指南使用的环境  {#environment-used-for-this-guide}

本指南中的示例在基于 `0.20.0` 版 `kind` 的
Kubernetes `1.27.3` 集群内的 Istio `1.19.0` 版本中运行。

Ambient 功能所需的最低 Istio 版本是 1.18.0，所需的最低 Kubernetes 版本是 `1.24.0`。
下面的示例需要一个具有超过 1 个工作节点的集群，以便解释跨节点流量的运行方式。
请参阅[安装用户指南](/zh/docs/ops/ambient/install/)或[入门指南](/zh/docs/ops/ambient/getting-started/)，
了解关于在 Kubernetes 集群中安装 Ambient 模式 Istio 的信息。

## 功能概述  {#functionaloverview}

ztunnel 代理的功能行为可以分为数据平面行为和与 Istio 控制平面的交互。
本节简要介绍这两个方面 - ztunnel 代理内部设计的详细描述超出了本指南的范围。

### 控制平面概述  {#control-plane-overview}

该图展示了 ztunnel 代理和 `istiod` 控制平面以及控制平面相关组件之间的流程概述。

{{< image width="100%"
link="ztunnel-architecture.png"
caption="ztunnel 架构"
>}}

ztunnel 代理使用 xDS API 与 Istio 控制平面（`istiod`）进行通信。
这使得现代分布式系统所需的快速、动态配置更新成为可能。
ztunnel 代理还使用 xDS 为其 Kubernetes 节点上调度的所有 Pod 的服务帐户获取 mTLS 证书。
单个 ztunnel 代理可以代表共享其节点的任何 Pod 实现 L4 数据平面功能，
这需要有效获取相关配置和证书。这种多租户架构与 Sidecar 模型形成鲜明对比，
在 Sidecar 模型中，每个应用程序 Pod 都有自己的代理。

另外值得注意的是，在 Ambient 模式下，xDS API 中使用一组简化的资源来进行 ztunnel 代理配置。
这会提高性能（需要传输和处理从 istiod 发送到 ztunnel 代理的信息集更小）并改进排障过程。

### 数据平面概述  {#data-plane-overview}

本节简要总结了数据平面功能的关键内容。

#### ztunnel 到 ztunnel 数据路径  {#ztunnel-to-ztunnel-datapath}

第一个场景是 ztunnel 到 ztunnel L4 网络。如下图所示。

{{< image width="100%"
link="ztunnel-datapath-1.png"
caption="ztunnel 基础：仅 L4 数据路径"
>}}

该图描绘了 Kubernetes 集群的两个节点 W1 和 W2 上运行的 Ambient Pod 工作负载。
每个节点上都有一个 ztunnel 代理实例。在此场景中，应用程序客户端
Pod C1、C2 和 C3 需要访问由 Pod S1 提供的服务，并且不需要高级 L7 功能
（例如 L7 流量路由或 L7 流量管理），因此不需要 Waypoint 代理。

该图展示了在节点 W1 上运行的 Pod C1 和 C2 与在节点 W2 上运行的 Pod S1 连接，
它们的 TCP 流量通过在每个节点的 ztunnel 代理 Pod 之间创建的单个共享 HBONE 隧道实例进行隧道传输。
双向 TLS（mTLS）用于加密以及隧道流量的相互身份验证。SPIFFE 身份用于识别连接两端的工作负载。
Istio Ambient 中使用的 `HBONE`（基于 HTTP 的覆盖网络封装：HTTP Based Overlay Network Encapsulation）概念是指一种透明、
安全地隧道传输封装在 HTTPS 数据包中的 TCP 数据包的技术。
以下小节提供了有关 HBONE 的一些简短附加说明。

请注意，该图展示本地流量（从 Pod C3 到工作节点 W2 上的目标 Pod S1）
无论是否跨越节点边界也会遍历本地 ztunnel 代理实例，
以便对流量执行相同的 L4 流量管理功能（例如 L4 鉴权和 L4 遥测）。

#### 通过 Waypoint 的 ztunnel 数据路径  {#ztunnel-datapath-via-waypoint}

下图描述了需要高级 L7 流量路由、管理或策略处理用例的数据路径。
这里 ztunnel 使用 HBONE 隧道将流量发送到 Waypoint 代理进行 L7 处理。
处理后，Waypoint 通过第二个 HBONE 隧道将流量发送到托管所选服务目标 Pod 节点上的 ztunnel。
一般来说，Waypoint 代理可能位于也可能不位于与源或目标 Pod 相同的节点上。

{{< image width="100%"
link="ztunnel-waypoint-datapath.png"
caption="通过临时 Waypoint 的 ztunnel 数据路径"
>}}

#### ztunnel 数据路径 Hair-pinning  {#ztunnel-datapath-hair-pinning}

{{< warning >}}
如前所述，随着项目进入 Beta 及更高版本，一些 Ambient 功能可能会发生变化。
此功能（Hair-pinning）是当前在 Ambient 的 Alpha 版本中可用的功能示例，
并且随着项目的发展正在审查可能的修改。
{{< /warning >}}

前面已经指出，流量总是先发送到与目的地 Pod 相同节点上的 ztunnel 代理，然后再发送到目的地 Pod。
但是，如果发送方完全位于 Istio Ambient 网格之外，因此不首先向目的地 ztunnel 发起 HBONE 隧道，该怎么办？
如果发送者是恶意的并尝试绕过目标 ztunnel 代理将流量直接发送到 Ambient Pod 目标怎么办？

这里有两种情况，如下图所示。在第一种情况下，流量流 B1 被节点 W2 在任何 HBONE 隧道外接收，
并出于某种原因直接寻址到 Ambient Pod S1 的 IP 地址（可能是因为流量源不是 Ambient Pod）。
如图所示，ztunnel 流量重定向逻辑将拦截此类流量，并通过本地 ztunnel 代理进行目的地侧代理处理和可能基于
AuthorizationPolicy 的过滤，然后发送到 Pod S1。
在第二种情况下，流量流 G1 被节点 W2 的 ztunnel 代理接收（可能通过 HBONE 隧道），
但 ztunnel 代理检查目标服务是否需要 Waypoint 处理，但发送此流量的源不是 Waypoint
或者是与此目标服务无关。在这种情况下。ztunnel 代理再次将流量 Hair-pinning 到与目标服务关联的 Waypoint 之一，
然后可以将流量从那里传递到实现目标服务的任何 Pod（可能是 Pod S1 本身，如图所示）。

{{< image width="100%"
link="ztunnel-hairpin.png"
caption="ztunnel 流量 Hair-pinning"
>}}

### 关于 HBONE 的说明  {#hbonesection}

HBONE（HTTP Based Overlay Network Encapsulation，基于 HTTP 的覆盖网络封装）是 Istio 中特定的术语。
它是指通过 [HTTP CONNECT](https://developer.mozilla.org/en-US/docs/Web/HTTP/Methods/CONNECT)
方法使用标准 HTTP 隧道来透明地传递应用程序数据包/字节流。
在 Istio 的当前实现中，它仅通过使用 HTTP CONNECT 方法透明地隧道传输 TCP 数据包，
使用 [HTTP/2](https://httpwg.org/specs/rfc7540.html)，
并通过[双向 TLS](https://www.cloudflare.com/learning/access-management/what-is-mutual-tls/)
提供加密和相互身份验证且 HBONE 隧道本身在 TCP 端口 15008 上运行。
来自 IP 层的整体 HBONE 数据包格式如下图所示。

{{< image width="100%"
link="hbone-packet.png"
caption="HBONE L3 数据包格式"
>}}

未来 Istio Ambient 还可能利用作为
[IETF MASQUE](https://ietf-wg-masque.github.io/)
工作组中一部分开发的 CONNECT-UDP 和 CONNECT-IP 等新标准支持基于
[HTTP/3（QUIC）](https://datatracker.ietf.org/doc/html/rfc9114)的传输，
并将用于传输原生 IPv4、IPv6、UDP 等所有类型的 L3 和 L4 数据包。
Istio Ambient 模式下的 HBONE 和 HTTP 隧道的此类附加用例目前还需进一步调研。

## 部署应用程序  {#deployapplication}

通常，具有 Istio 管理员权限的用户将部署 Istio 网格基础设施。
一旦 Istio 在 Ambient 模式下被成功部署，它将透明地可供命名空间中所有用户部署的应用程序使用，
这些应用程序已被注解为使用 Istio Ambient，如下例所示。

### 部署不基于 Ambient 的基础应用程序  {#basic-application-deployment-without-ambient}

首先，部署一个简单的 HTTP 客户端服务器应用程序，而不使其成为 Istio Ambient
网格的一部分。如 Istio 指南中所述，从本地 Istio 仓库或通过下载 istioctl
客户端创建的 Istio 文件夹中执行以下示例。

{{< text bash >}}
$ kubectl create ns ambient-demo
$ kubectl apply -f samples/httpbin/httpbin.yaml -n ambient-demo
$ kubectl apply -f samples/sleep/sleep.yaml -n ambient-demo
$ kubectl apply -f samples/sleep/notsleep.yaml -n ambient-demo
$ kubectl scale deployment sleep --replicas=2 -n ambient-demo
{{< /text >}}

这些清单部署了 `sleep` 和 `notsleep` Pod 的多个副本，
这些副本将被作为 httpbin 服务 Pod 的客户端
（为简单起见，上面的代码示例中的命令行输出已被删除）。

{{< text bash >}}
$ kubectl wait -n ambient-demo --for=condition=ready pod --selector=app=httpbin --timeout=90s
pod/httpbin-648cd984f8-7vg8w condition met
{{< /text >}}

{{< text bash >}}
$ kubectl get pods -n ambient-demo
NAME                       READY   STATUS    RESTARTS   AGE
httpbin-648cd984f8-7vg8w   1/1     Running   0          31m
notsleep-bb6696574-2tbzn   1/1     Running   0          31m
sleep-69cfb4968f-mhccl     1/1     Running   0          31m
sleep-69cfb4968f-rhhhp     1/1     Running   0          31m
{{< /text >}}

{{< text bash >}}
$ kubectl get svc httpbin -n ambient-demo
NAME      TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
httpbin   ClusterIP   10.110.145.219   <none>        8000/TCP   28m
{{< /text >}}

请注意，每个应用程序 Pod 中仅运行 1 个容器（“1/1”指示符），
并且 `httpbin` 是侦听 `ClusterIP` 服务端口 8000 的 http 服务。
您现在应该能够从任一客户端 Pod `curl` 该服务并确认它返回如下所示的 `httpbin` 网页。
此时，还没有使用任何形式的 `TLS`。

{{< text bash >}}
$ kubectl exec deploy/sleep -n ambient-demo  -- curl httpbin:8000 -s | grep title -m 1
    <title>httpbin.org</title>
{{< /text >}}

### 为应用程序启用 Ambient  {#enabling-ambient-for-an-application}

现在，您只需将标签 `istio.io/dataplane-mode=ambient`
添加到应用程序的命名空间即可为上一小节中部署的应用程序启用 Ambient，如下所示。
请注意，此示例重点关注一个新的命名空间，其中包含仅通过 Ambient 模式捕获的新的、
无 Sidecar 的工作负载。后续章节将说明如何在同一网格内混用 Sidecar
模式和 Ambient 模式的混合场景中解决冲突。

{{< text bash >}}
$ kubectl label namespace ambient-demo istio.io/dataplane-mode=ambient
$ kubectl  get pods -n ambient-demo
NAME                       READY   STATUS    RESTARTS   AGE
httpbin-648cd984f8-7vg8w   1/1     Running   0          78m
notsleep-bb6696574-2tbzn   1/1     Running   0          77m
sleep-69cfb4968f-mhccl     1/1     Running   0          78m
sleep-69cfb4968f-rhhhp     1/1     Running   0          78m
{{< /text >}}

请注意，为命名空间启用 Ambient 后，每个应用程序 Pod 仍然只有 1 个容器，
并且这些 Pod 的正常运行时间表明这些 Pod 没有为了启用 Ambient 模式而被重新启动
（与 `sidecar` 模式不同，当 Sidecar 代理被注入时，它会重新启动应用程序 Pod）。
这会带来更好的用户体验和运维效率，因为就应用程序 Pod 而言，
可以完全透明地无缝启用（或禁用）Ambient 模式。

再次从客户端 Pod 之一向服务发起 `curl` 请求，以验证流量在 Ambient 模式下是否继续流动。

{{< text bash >}}
$ kubectl exec deploy/sleep -n ambient-demo  -- curl httpbin:8000 -s | grep title -m 1
    <title>httpbin.org</title>
{{< /text >}}

这表明流量路径正在工作。下一节将介绍如何监控 ztunnel 代理的配置和数据平面，
以确认流量正确使用 ztunnel 代理。

## 监控 ztunnel 代理和 L4 网络  {#monitoringzt}

本节介绍一些用于监视 ztunnel 代理配置和数据路径的选项。
此信息还可以帮助进行一些高级故障排除，以及识别在出现任何问题时可在错误报告中收集和提供的有用信息。
ztunnel 内部的其他高级监控和高级故障排除超出了本指南的范围。

### 查看 ztunnel 代理状态  {#viewing-ztunnel-proxy-state}

如前所述，每个节点上的 ztunnel 代理通过 xDS API 从 istiod 组件获取配置和发现信息。
使用如下所示的 `istioctl proxy-config` 命令查看 ztunnel 代理发现的工作负载，
以及保存 ztunnel 代理从 istiod 控制平面接收到的 TLS 证书的 Secret，
以代表本地在 mTLS 信令中使用工作负载。

在第一个示例中，您会看到特定 ztunnel Pod 当前正在跟踪的所有工作负载和控制平面组件，
包括有关连接到该组件时要使用的 IP 地址和协议的信息，
以及是否存在与该工作负载关联的 Waypoint 代理。
可以对系统中的任何其他 ztunnel Pod 重复此示例，以显示其当前配置。

{{< text bash >}}
$ export ZTUNNEL=$(kubectl get pods -n istio-system -o wide | grep ztunnel -m 1 | sed 's/ .*//')
$ echo "$ZTUNNEL"
{{< /text >}}

{{< text bash >}}
$ istioctl proxy-config workloads "$ZTUNNEL".istio-system
NAME                                   NAMESPACE          IP         NODE               WAYPOINT PROTOCOL
coredns-6d4b75cb6d-ptbhb               kube-system        10.240.0.2 amb1-control-plane None     TCP
coredns-6d4b75cb6d-tv5nz               kube-system        10.240.0.3 amb1-control-plane None     TCP
httpbin-648cd984f8-2q9bn               ambient-demo       10.240.1.5 amb1-worker        None     HBONE
httpbin-648cd984f8-7dglb               ambient-demo       10.240.2.3 amb1-worker2       None     HBONE
istiod-5c7f79574c-pqzgc                istio-system       10.240.1.2 amb1-worker        None     TCP
local-path-provisioner-9cd9bd544-x7lq2 local-path-storage 10.240.0.4 amb1-control-plane None     TCP
notsleep-bb6696574-r4xjl               ambient-demo       10.240.2.5 amb1-worker2       None     HBONE
sleep-69cfb4968f-mwglt                 ambient-demo       10.240.1.4 amb1-worker        None     HBONE
sleep-69cfb4968f-qjmfs                 ambient-demo       10.240.2.4 amb1-worker2       None     HBONE
ztunnel-5jfj2                          istio-system       10.240.0.5 amb1-control-plane None     TCP
ztunnel-gkldc                          istio-system       10.240.1.3 amb1-worker        None     TCP
ztunnel-xxbgj                          istio-system       10.240.2.2 amb1-worker2       None     TCP
{{< /text >}}

在第二个示例中，您会看到此 ztunnel 代理实例从 istiod
接收到的用于 TLS 信令的 TLS 证书列表。

{{< text bash >}}
$ istioctl proxy-config secrets "$ZTUNNEL".istio-system
NAME                                                  TYPE           STATUS        VALID CERT     SERIAL NUMBER                        NOT AFTER                NOT BEFORE
spiffe://cluster.local/ns/ambient-demo/sa/httpbin     CA             Available     true           edf7f040f4b4d0b75a1c9a97a9b13545     2023-09-20T19:02:00Z     2023-09-19T19:00:00Z
spiffe://cluster.local/ns/ambient-demo/sa/httpbin     Cert Chain     Available     true           ec30e0e1b7105e3dce4425b5255287c6     2033-09-16T18:26:19Z     2023-09-19T18:26:19Z
spiffe://cluster.local/ns/ambient-demo/sa/sleep       CA             Available     true           3b9dbea3b0b63e56786a5ea170995f48     2023-09-20T19:00:44Z     2023-09-19T18:58:44Z
spiffe://cluster.local/ns/ambient-demo/sa/sleep       Cert Chain     Available     true           ec30e0e1b7105e3dce4425b5255287c6     2033-09-16T18:26:19Z     2023-09-19T18:26:19Z
spiffe://cluster.local/ns/istio-system/sa/istiod      CA             Available     true           885ee63c08ef9f1afd258973a45c8255     2023-09-20T18:26:34Z     2023-09-19T18:24:34Z
spiffe://cluster.local/ns/istio-system/sa/istiod      Cert Chain     Available     true           ec30e0e1b7105e3dce4425b5255287c6     2033-09-16T18:26:19Z     2023-09-19T18:26:19Z
spiffe://cluster.local/ns/istio-system/sa/ztunnel     CA             Available     true           221b4cdc4487b60d08e94dc30a0451c6     2023-09-20T18:26:35Z     2023-09-19T18:24:35Z
spiffe://cluster.local/ns/istio-system/sa/ztunnel     Cert Chain     Available     true           ec30e0e1b7105e3dce4425b5255287c6     2033-09-16T18:26:19Z     2023-09-19T18:26:19Z
{{< /text >}}

使用这些 CLI 命令，用户可以检查 ztunnel 代理是否已配置所有预期的工作负载和 TLS 证书，
并且缺失的信息可被用于故障排除，以解释任何潜在的观察到的网络错误。
用户还可以使用 `all` 选项通过单个 CLI 命令和 JSON
输出格式化程序来查看代理配置的所有内容，如下面例子所示，以显示完整的可用状态信息集。

{{< text bash >}}
$ istioctl proxy-config all "$ZTUNNEL".istio-system -o json | jq
{{< /text >}}

请注意，与 ztunnel 代理实例一起使用时，并非所有
`istioctl proxy-config` CLI 的选项都被支持，因为某些选项仅适用于 Sidecar 代理。

高级用户还可以通过 `curl` 命令访问 ztunnel 代理 Pod 内的端点查看
ztunnel 代理的原始配置 Dump，如以下示例所示。

{{< text bash >}}
$ kubectl exec ds/ztunnel -n istio-system  -- curl http://localhost:15000/config_dump | jq .
{{< /text >}}

### 查看 ztunnel xDS 资源的 istiod 状态  {#viewing-istiod-state-for-ztunnel-xds-resources}

有时，高级用户可能希望以专门为 ztunnel 代理定义的 xDS API 资源的格式查看 istiod
控制平面中维护的 ztunnel 代理配置资源的状态。这可以通过访问 istiod Pod
并从给定 ztunnel 代理的端口 15014 获取此信息来完成，如下面例子所示。
然后，还可以使用 JSON 漂亮的打印格式化实用程序保存和查看此输出，
以便于浏览（示例中未显示）。

{{< text bash >}}
$ kubectl exec -n istio-system deploy/istiod -- curl localhost:15014/debug/config_dump?proxyID="$ZTUNNEL".istio-system | jq
{{< /text >}}

### 验证 ztunnel 流量日志  {#verifying-ztunnel-traffic-logs}

将一些流量从客户端 `sleep` Pod 发送到 `httpbin` 服务。

{{< text bash >}}
$ kubectl -n ambient-demo exec deploy/sleep -- sh -c 'for i in $(seq 1 10); do curl -s -I http://httpbin:8000/; done'
HTTP/1.1 200 OK
Server: gunicorn/19.9.0
--snip--
{{< /text >}}

上述响应确认了客户端 Pod 收到来自服务的响应。
现在检查 ztunnel Pod 的日志以确认流量是通过 HBONE 隧道发送的。

{{< text bash >}}
$ kubectl -n istio-system logs -l app=ztunnel | grep -E "inbound|outbound"
2023-08-14T09:15:46.542651Z  INFO outbound{id=7d344076d398339f1e51a74803d6c854}: ztunnel::proxy::outbound: proxying to 10.240.2.10:80 using node local fast path
2023-08-14T09:15:46.542882Z  INFO outbound{id=7d344076d398339f1e51a74803d6c854}: ztunnel::proxy::outbound: complete dur=269.272µs
--snip--
{{< /text >}}

这些日志消息确认流量确实使用了数据路径中的 ztunnel 代理。
可以通过检查与流量源和目标 Pod 位于同一节点上的特定 ztunnel
代理实例上的日志来完成额外的细粒度监控。如果没有看到这些日志，
则可能是流量重定向无法正常工作。流量重定向逻辑的监控和故障排除的详细描述超出了本指南的范围。
请注意，如前所述，即使流量的源和目标位于同一计算节点上，Ambient 流量也始终会遍历 ztunnel Pod。

### 通过 Prometheus、Grafana、Kiali 进行监控和遥测  {#monitoring-and-telemetry-via-prometheus-grafana-kiali}

除了检查 ztunnel 日志和上述其他监控选项之外，还可以使用普通的 Istio
监控和遥测功能来监控 Istio Ambient 网格内的应用程序流量。
在 Ambient 模式下使用 Istio 不会改变此行为。由于此功能在 Istio Ambient 模式下与
Istio Sidecar 模式基本没有变化，因此本指南中不再重复这些细节。
请参阅 [Prometheus 服务和仪表板的安装信息](/zh/docs/ops/integrations/prometheus/#installation)、
[Kiali 服务和仪表板的安装信息](/zh/docs/ops/integrations/kiali/#installation)、
[标准的 Istio 指标文档](/zh/docs/reference/config/metrics/)和
[Istio 遥测文档](/zh/docs/tasks/observability/metrics/querying-metrics/)。

需要注意的一点是，如果服务仅使用 ztunnel 和 L4 网络，
则报告的 Istio 指标目前仅是 L4/TCP 指标（即 `istio_tcp_sent_bytes_total`、
`istio_tcp_received_bytes_total`、`istio_tcp_connections_opened_total`、
`istio_tcp_connections_filled_total`）。
当涉及 Waypoint 代理时，将报告全套 Istio 和 Envoy 指标。

### 验证 ztunnel 负载均衡  {#verifying-ztunnel-load-balancing}

如果目标是具有多个端点的服务，ztunnel 代理会自动执行客户端负载均衡。
无需额外配置。ztunnel 负载均衡算法是内部固定的 L4 循环算法，
根据 L4 连接状态分配流量，用户不可配置。

{{< tip >}}
如果目标是具有多个实例或 Pod 的服务，并且没有与目标服务关联的 Waypoint，
则源 ztunnel 代理直接跨越这些实例或服务后端执行 L4 负载均衡，
然后通过远程 ztunnel 代理与这些后端发送流量。如果目标服务确实具有与其关联的
Waypoint 部署（具有一个或多个 Waypoint 代理的后端实例），
则源 ztunnel 代理通过在这些 Waypoint 代理之间分配流量来执行负载均衡，
并通过远程 ztunnel 代理与关联的 Waypoint 代理实例发送流量。
{{< /tip >}}

现在，使用多副本服务 Pod 重复前面的示例，
并验证客户端流量是否在服务副本之间实现负载均衡。
等待 ambient-demo 命名空间中的所有 Pod 进入 Running 状态，然后再继续下一步。

{{< text bash >}}
$ kubectl -n ambient-demo scale deployment httpbin --replicas=2 ; kubectl wait --for condition=available  deployment/httpbin -n ambient-demo
deployment.apps/httpbin scaled
deployment.apps/httpbin condition met
{{< /text >}}

{{< text bash >}}
$ kubectl -n ambient-demo exec deploy/sleep -- sh -c 'for i in $(seq 1 10); do curl -s -I http://httpbin:8000/; done'
{{< /text >}}

{{< text bash >}}
$ kubectl -n istio-system logs -l app=ztunnel | grep -E "inbound|outbound"
--snip--

2023-08-14T09:33:24.969996Z  INFO inbound{id=ec177a563e4899869359422b5cdd1df4 peer_ip=10.240.2.16 peer_id=spiffe://cluster.local/ns/ambient-demo/sa/sleep}: ztunnel::proxy::inbound: got CONNECT request to 10.240.1.11:80
2023-08-14T09:33:25.028601Z  INFO inbound{id=1ebc3c7384ee68942bbb7c7ed866b3d9 peer_ip=10.240.2.16 peer_id=spiffe://cluster.local/ns/ambient-demo/sa/sleep}: ztunnel::proxy::inbound: got CONNECT request to 10.240.1.11:80

--snip--

2023-08-14T09:33:25.226403Z  INFO outbound{id=9d99723a61c9496532d34acec5c77126}: ztunnel::proxy::outbound: proxy to 10.240.1.11:80 using HBONE via 10.240.1.11:15008 type Direct
2023-08-14T09:33:25.273268Z  INFO outbound{id=9d99723a61c9496532d34acec5c77126}: ztunnel::proxy::outbound: complete dur=46.9099ms
2023-08-14T09:33:25.276519Z  INFO outbound{id=cc87b4de5ec2ccced642e22422ca6207}: ztunnel::proxy::outbound: proxying to 10.240.2.10:80 using node local fast path
2023-08-14T09:33:25.276716Z  INFO outbound{id=cc87b4de5ec2ccced642e22422ca6207}: ztunnel::proxy::outbound: complete dur=231.892µs

--snip--
{{< /text >}}

请注意来自 ztunnel 代理的日志，首先表明了对新目标 Pod（10.240.1.11）的
http CONNECT 请求，该请求指示在托管其他目标服务 Pod 的节点上设置到
ztunnel 的 HBONE 隧道。接下来的日志表明了客户端流量被发送到 10.240.1.11
和 10.240.2.10，这是提供服务的两个目标 Pod。另请注意，在这种情况下，
数据路径正在执行客户端负载均衡，而不是依赖于 Kubernetes 服务负载均衡。
在您的设置中，这些数字将有所不同，并将与集群中 httpbin Pod 的地址匹配。

这是一种循环负载均衡算法，并且独立于可以在 `VirtualService` 的 `TrafficPolicy`
字段中配置的任何负载均衡算法，因为如前所述，`VirtualService` API
对象的所有方面都被实例化 在 Waypoint 代理上而不是 ztunnel 代理上。

### Ambient 模式和 Sidecar 模式的 Pod 选择逻辑  {#pod-selection-logic-for-ambient-and-sidecar-modes}

具有 Sidecar 代理的 Istio 可以与同一计算集群中基于 Ambient 的节点级代理共存。
确保相同的 Pod 或命名空间不会配置为同时使用 Sidecar 代理和 Ambient 节点级代理非常重要。
但是，如果确实发生这种情况，当前此类 Pod 或命名空间将优先进行 Sidecar 注入。

请注意，理论上，可以通过将各个 Pod 与命名空间标签分开标记来将同一命名空间中的两个
Pod 设置为使用不同的模式，但不建议这样做。对于大多数常见用例，
建议对单个命名空间内的所有 Pod 使用单一模式。

确定 Pod 是否设置为使用 Ambient 模式的确切逻辑如下。

1. 在 `cni.values.excludeNamespaces` 配置中的
   `istio-cni` 插件配置排除列表用于跳过排除列表中的命名空间。
1. Pod 已使用 `ambient` 模式，如果：
- 命名空间具有 `istio.io/dataplane-mode=ambient` 标签
- Pod 上不存在 `sidecar.istio.io/status` 注解
- `ambient.istio.io/redirection` 不是 `disabled`

避免配置冲突的最简单选项是用户确保对于每个命名空间，
它要么具有 Sidecar 注入标签（`istio-injection=enabled`），
要么具有 Ambient 数据平面模式标签（`istio.io/dataplane- mode=ambient`），
但绝不能两者兼而有之。

## L4 鉴权策略  {#l4auth}

如前面所述，ztunnel 代理在仅需要 L4
流量处理以便在数据平面中实施策略并且不涉及 Waypoint 时执行鉴权策略。
实际的执行点位于连接路径中的接收端（或服务器端）ztunnel 代理。

为已部署的 `httpbin` 应用程序应用基本的 L4 鉴权策略，如下面例子所示。

{{< text bash >}}
$ kubectl apply -n ambient-demo -f - <<EOF
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
 name: allow-sleep-to-httpbin
spec:
 selector:
   matchLabels:
     app: httpbin
 action: ALLOW
 rules:
 - from:
   - source:
       principals:
       - cluster.local/ns/ambient-demo/sa/sleep
EOF
{{< /text >}}

`AuthorizationPolicy` API 的行为在 Istio Ambient 模式下与 Sidecar
模式下具有相同的功能行为。当没有配置 `AuthorizationPolicy` 时，默认操作是 `ALLOW`。
配置上述策略后，与策略中的 Selector（即 app:httpbin）匹配的 Pod 仅允许明确列入白名单的流量，
在本例中是主体（即身份）为 `cluster.local/ns/ambient-demo/sa/sleep` 的源。
现在如下所示，如果您尝试从 `sleep` Pod 对 `httpbin` 服务执行curl 操作，它仍然有效，
但从 `notsleep` Pod 发起时，相同的操作会被阻止。

请注意，此策略对来自主体（即身份）为 `cluster.local/ns/ambient-demo/sa/sleep`
的源的流量执行显式 `ALLOW` 操作，因此来自所有其他源的流量将被拒绝。

{{< text bash >}}
$ kubectl exec deploy/sleep -n ambient-demo -- curl httpbin:8000 -s | grep title -m 1
    <title>httpbin.org</title>
{{< /text >}}

{{< text bash >}}
$ kubectl exec deploy/notsleep -n ambient-demo -- curl httpbin:8000 -s | grep title -m 1
command terminated with exit code 56
{{< /text >}}

请注意，Waypoint 代理并未被部署，但此 `AuthorizationPolicy` 正在被强制执行，
这是因为此策略仅需要可由 ztunnel 代理执行的 L4 流量处理。
可以通过检查 ztunnel 日志并查找指示 RBAC 操作的日志来进一步确认这些策略操作，
如以下示例所示。

{{< text bash >}}
$ kubectl logs ds/ztunnel -n istio-system  | grep -E RBAC
-- snip --
2023-10-10T23:14:00.534962Z  INFO inbound{id=cc493da5e89877489a786fd3886bd2cf peer_ip=10.240.2.2 peer_id=spiffe://cluster.local/ns/ambient-demo/sa/notsleep}: ztunnel::proxy::inbound: RBAC rejected conn=10.240.2.2(spiffe://cluster.local/ns/ambient-demo/sa/notsleep)->10.240.1.2:80
2023-10-10T23:15:33.339867Z  INFO inbound{id=4c4de8de802befa5da58a165a25ff88a peer_ip=10.240.2.2 peer_id=spiffe://cluster.local/ns/ambient-demo/sa/notsleep}: ztunnel::proxy::inbound: RBAC rejected conn=10.240.2.2(spiffe://cluster.local/ns/ambient-demo/sa/notsleep)->10.240.1.2:80
{{< /text >}}

{{< warning >}}
如果配置的 `AuthorizationPolicy` 需要 L4 之外的任何流量处理，
并且没有为流量的目标配置 Waypoint 代理，则 ztunnel 代理将简单地丢弃所有流量作为防御措施。
因此，请检查以确保所有规则仅涉及 L4 处理，否则如果非 L4 规则不可避免，
则还配置 Waypoint 代理来处理执行策略。
{{< /warning >}}

例如，修改 `AuthorizationPolicy` 以包含对 HTTP GET 方法的检查，
如下所示。现在请注意，`sleep` 和 `notsleep` Pod 都会被阻止向目标 `httpbin` 服务发送流量。

{{< text bash >}}
$ kubectl apply -n ambient-demo -f - <<EOF
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
 name: allow-sleep-to-httpbin
spec:
 selector:
   matchLabels:
     app: httpbin
 action: ALLOW
 rules:
 - from:
   - source:
       principals:
       - cluster.local/ns/ambient-demo/sa/sleep
   to:
   - operation:
       methods: ["GET"]
EOF
{{< /text >}}

{{< text bash >}}
$ kubectl exec deploy/sleep -n ambient-demo -- curl httpbin:8000 -s | grep title -m 1
command terminated with exit code 56
{{< /text >}}

{{< text bash >}}
$ kubectl exec deploy/notsleep -n ambient-demo -- curl httpbin:8000 -s | grep title -m 1
command terminated with exit code 56
{{< /text >}}

您还可以通过查看特定 ztunnel 代理 Pod 的日志（此处示例中未显示）来进行确认，
实际执行策略的始终是托管目标 Pod 节点上的 ztunnel 代理。

在继续本指南中的其余示例之前，请先删除此 `AuthorizationPolicy`。

{{< text bash >}}
$ kubectl delete AuthorizationPolicy allow-sleep-to-httpbin  -n ambient-demo
{{< /text >}}

## Ambient 与非 Ambient 端点的互操作性  {#interop}

到目前为止的用例中，流量源和目标 Pod 都是 Ambient Pod。
本节介绍一些混合用例，其中 Ambient 端点需要与非 Ambient 端点进行通信。
与本指南前面的示例一样，本节介绍的用例不需要 Waypoint 代理。

1. [东西向非网格 Pod 到 Ambient 网格 Pod（以及使用 `PeerAuthentication` 资源）](#ewnonmesh)
1. [东西向 Istio Sidecar 代理 Pod 到 Ambient 网格 Pod](#ewside2ambient)
1. [南北入口网关到 Ambient 后端 Pod](#nsingress2ambient)

### 东西向非网格 Pod 到 Ambient 网格 Pod（以及 PeerAuthentication 资源的使用）  {#ewnonmesh}

在下面的示例中，通过在不属于 Istio 网格的单独命名空间中运行的客户端
`sleep` Pod 访问前面示例中已设置的相同 `httpbin` 服务。
此示例显示 Ambient 网格 Pod 和非网格 Pod 之间的东西向流量得到无缝支持。
请注意，如前面所述，此用例利用了 Ambient 的流量 Hair-pinning 功能。
由于非网格 Pod 直接向后端 Pod 发起流量，而不经过 HBONE 或 ztunnel，
因此在目标节点，流量将通过目标节点的 ztunnel 代理进行重定向，
以确保应用 Ambient 鉴权策略（这可以通过以下方式验证，查看目标节点上相应
ztunnel 代理 Pod 的日志；为简单起见，下面的示例代码片段中未显示日志）。

{{< text bash >}}
$ kubectl create namespace client-a
$ kubectl apply -f samples/sleep/sleep.yaml -n client-a
$ kubectl wait --for condition=available  deployment/sleep -n client-a
{{< /text >}}

等待 Pod 在 client-a 命名空间中进入 Running 状态，然后再继续。

{{< text bash >}}
$ kubectl exec deploy/sleep -n client-a  -- curl httpbin.ambient-demo.svc.cluster.local:8000 -s | grep title -m 1
    <title>httpbin.org</title>
{{< /text >}}

如下面的示例所示，现在在 Ambient 命名空间中添加 mTLS 模式并设置为
`STRICT` 的 `PeerAuthentication` 资源，确认同一客户端的流量现在被拒绝，
并出现一条指示请求被拒绝的错误。这是因为客户端使用简单的 HTTP 连接到服务器，
而不是使用 mTLS 的 HBONE 隧道。这是一种可用于防止非
Istio 源向 Istio Ambient Pod 发送流量的可能方法。

{{< text bash >}}
$ kubectl apply -n ambient-demo -f - <<EOF
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: peerauth
spec:
  mtls:
    mode: STRICT
EOF
{{< /text >}}

{{< text bash >}}
$ kubectl exec deploy/sleep -n client-a  -- curl httpbin.ambient-demo.svc.cluster.local:8000 -s | grep title -m 1
command terminated with exit code 56
{{< /text >}}

将 mTLS 模式更改为 `PERMISSIVE`，并确认 Ambient Pod
可以再次接受非 mTLS 连接，包括本例中来自非网格 Pod 的连接。

{{< text bash >}}
$ kubectl apply -n ambient-demo -f - <<EOF
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: peerauth
spec:
  mtls:
    mode: PERMISSIVE
EOF
{{< /text >}}

{{< text bash >}}
$ kubectl exec deploy/sleep -n client-a  -- curl httpbin.ambient-demo.svc.cluster.local:8000 -s | grep title -m 1
    <title>httpbin.org</title>
{{< /text >}}

### 东西向 Istio Sidecar 代理 Pod 到 Ambient 网格 Pod  {#ewside2ambient}

此用例是使用 Sidecar 代理的 Istio Pod 与同一网格内的
Ambient Pod 之间的无缝东西向流量互操作性。

使用与上一个示例相同的 httpbin 服务，但现在添加一个客户端以从另一个标记为
Sidecar 注入的命名空间访问此服务。这也会自动且透明地工作，如下面例子所示。
在这种情况下，与客户端一起运行的 Sidecar 代理会自动知道使用 HBONE 控制平面，
因为已发现目的地是 HBONE 目标。用户无需进行任何特殊配置即可启用此功能。

{{< tip >}}
为了使 Sidecar 代理在与 Ambient 目标通信时使用 HBONE/mTLS 信号选项，
需要在代理元数据中进行配置，将 `ISTIO_META_ENABLE_HBONE` 设置为 true。
使用 `ambient` 配置文件时，会在 `MeshConfig` 中自动为用户设置默认值，
因此用户在使用此配置文件时无需执行任何其他操作。
{{< /tip >}}

{{< text bash >}}
$ kubectl create ns client-b
$ kubectl label namespace client-b istio-injection=enabled
$ kubectl apply -f samples/sleep/sleep.yaml -n client-b
$ kubectl wait --for condition=available  deployment/sleep -n client-b
{{< /text >}}

等待 Pod 在 client-b 命名空间中进入 Running 状态，然后再继续。

{{< text bash >}}
$ kubectl exec deploy/sleep -n client-b  -- curl httpbin.ambient-demo.svc.cluster.local:8000 -s | grep title -m 1
    <title>httpbin.org</title>
{{< /text >}}

同样，通过查看目标节点上 ztunnel Pod（示例中未显示）的日志，
可以进一步验证流量实际上确实使用从基于 Sidecar 代理的源客户端 Pod
到基于 HBONE 和 CONNECT 的 Ambient 路径的目标服务。
另外未显示，但也可以验证与前一小节不同，在这种情况下，即使您将 `PeerAuthentication`
资源应用于标记为 Ambient 模式的命名空间，客户端和服务 Pod 之间的通信也会继续，
因为两者都使用依赖 mTLS 的 HBONE 控制面和数据面。

### 南北入口网关到 Ambient 后端 Pod  {#nsingress2ambient}

本节介绍了南北流量的用例，其中 Istio 网关通过 Kubernetes Gateway API
公开 httpbin 服务。网关本身在非 Ambient 命名空间中运行，
并且可能是一个现有网关，并公开非 Ambient Pod 提供的其他服务。
因此，此示例表明 Ambient 工作负载还可以与 Istio 网关进行互操作，
而 Istio 网关本身不需要在标记为 Ambient 操作模式的命名空间中运行。

对于此示例，您可以使用 `metallb` 在可以从集群外部访问的 IP 地址上提供负载均衡器服务。
同一示例还适用于其他形式的南北负载均衡选项。
下面的示例假设您已经在此集群中安装了 `metallb` 来提供负载均衡器服务，
其中包括 `metallb` 的 IP 地址池，以用于向外部公开服务。
请参阅 [`metallb` kind 指南](https://kind.sigs.k8s.io/docs/user/loadbalancer/)，
了解有关在 kind 集群上设置 `metallb` 的说明，或参阅适用于您环境的
[`metallb` 文档](https://metallb.universe.tf/installation/)。

此示例使用 Kubernetes Gateway API 来配置南北网关。
由于 Kubernetes 和 kind 发行版中当前未默认提供此 API，
因此您必须首先安装 API CRD，如示例中所示。

然后，将部署使用 Kubernetes Gateway API CRD 的 `Gateway` 实例，
以利用此 `metallb` 负载均衡器服务。在此示例中，
Gateway 的实例在 istio-system 命名空间中运行，表示在非 Ambient
命名空间中运行的现有网关。最后，将为 `HTTPRoute` 配置一个后端引用，
该引用指向在 ambient-demo 命名空间中的 Ambient Pod 上运行的现有 httpbin 服务。

{{< text bash >}}
$ kubectl get crd gateways.gateway.networking.k8s.io &> /dev/null || \
      { kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd/experimental?ref=v0.6.1" | kubectl apply -f -; }
{{< /text >}}

{{< tip >}}
{{< boilerplate gateway-api-future >}}
{{< boilerplate gateway-api-choose >}}
{{< /tip >}}

{{< text bash >}}
$ kubectl apply -f - << EOF
apiVersion: gateway.networking.k8s.io/v1beta1
kind: Gateway
metadata:
  name: httpbin-gateway
  namespace: istio-system
spec:
  gatewayClassName: istio
  listeners:
  - name: http
    port: 80
    protocol: HTTP
    allowedRoutes:
      namespaces:
        from: All
EOF
{{< /text >}}

{{< text bash >}}
$ kubectl apply -n ambient-demo -f - << EOF
apiVersion: gateway.networking.k8s.io/v1beta1
kind: HTTPRoute
metadata:
  name: httpbin
spec:
  parentRefs:
  - name: httpbin-gateway
    namespace: istio-system
  rules:
  - backendRefs:
    - name: httpbin
      port: 8000
EOF
{{< /text >}}

接下来找到网关正在侦听的外部服务 IP 地址，
然后从集群外部访问该 IP 地址（下面例子中的 172.18.255.200）上的 httpbin 服务，如下所示。

{{< text bash >}}
$ kubectl get service httpbin-gateway-istio -n istio-system
NAME                    TYPE           CLUSTER-IP     EXTERNAL-IP      PORT(S)                        AGE
httpbin-gateway-istio   LoadBalancer   10.110.30.25   172.18.255.200   15021:32272/TCP,80:30159/TCP   121m
{{< /text >}}

{{< text bash >}}
$ export INGRESS_HOST=$(kubectl -n istio-system get service httpbin-gateway-istio  -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
$ echo "$INGRESS_HOST"
172.18.255.200
{{< /text >}}

{{< text bash >}}
$ curl  "$INGRESS_HOST" -s | grep title -m 1
    <title>httpbin.org</title>
{{< /text >}}

这些示例说明了 Ambient Pod 和非 Ambient 端点
（可以是 Kubernetes 应用 Pod 或具有 Istio 原生网关和 Kubernetes Gateway API 实例的 Istio 网关 Pod）
之间的互操作性的多种选项。Istio Ambient Pod 和 Istio Egress 网关之间也支持互操作性，
以及 Ambient Pod 运行应用程序的客户端且服务端运行在使用 Sidecar 代理模式的网格 Pod 之外的场景。
因此，用户有多种选择可以在同一 Istio 网格中无缝集成 Ambient 和非 Ambient 工作负载，
从而允许以最适合 Istio 网格部署和操作的需求分阶段引入 Ambient 功能。
