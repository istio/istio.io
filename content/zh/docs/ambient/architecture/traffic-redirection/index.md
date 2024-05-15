---
title: ztunnel 流量重定向
description: 了解流量如何在 Pod 和 ztunnel 节点代理之间重定向。
weight: 2
aliases:
  - /zh/docs/ops/ambient/usage/traffic-redirection
  - /zh/latest/docs/ops/ambient/usage/traffic-redirection
owner: istio/wg-networking-maintainers
test: no
---

在 Ambient 模式的上下文中，**流量重定向**指的是一项数据平面功能，
该功能拦截发送到启用 Ambient 的工作负载和从支持 Ambient 的工作负载发来的流量，
并通过处理核心数据路径的 {{< gloss >}}ztunnel{{< /gloss >}} 节点代理将其路由。
有时也使用术语**流量捕获**。

由于 ztunnel 旨在透明地加密和路由应用程序流量，
因此需要一种机制来捕获进入和离开“网格内” Pod 的所有流量。
这是一项安全关键任务：如果可以绕过 ztunnel，则可以绕过鉴权策略。

## Istio 的 in-Pod 流量重定向模型 {#istio-s-in-pod-traffic-redirection-model}

Ambient 模式 in-Pod 流量重定向的核心设计原则是 ztunnel
代理能够在工作负载 Pod 的 Linux 网络命名空间内执行数据路径捕获。
这是通过 [`istio-cni` 节点代理](/zh/docs/setup/additional-setup/cni/)和
ztunnel 节点代理之间的功能协作来实现的。该模型的一个主要优点是，
它使 Istio 的 Ambient 模式能够与任何 Kubernetes CNI 插件透明地协同工作，
并且不会影响 Kubernetes 网络功能。

下图说明了在启用 Ambient 的命名空间中启动（或添加）新工作负载 Pod 时的事件顺序。

{{< image width="100%"
    link="./pod-added-to-ambient.svg"
    alt="Pod 被添加到 Ambient 网格的流程"
    >}}

`istio-cni` 节点代理响应 CNI 事件，例如 Pod 创建和删除，
还监视底层 Kubernetes API 服务器的事件，例如添加到 Pod 或命名空间的 Ambient 标签。

`istio-cni` 节点代理还会安装一个链式 CNI 插件，
该插件在 Kubernetes 集群中的主流 CNI 插件执行后由容器运行时执行。
其唯一目的是当容器运行时在已经以 Ambient 模式注册的命名空间中创建新的
Pod 时通知 `istio-cni` 节点代理，并将新的 Pod 上下文传播到 `istio-cni`。

一旦 `istio-cni` 节点代理收到通知需要将 Pod 添加到网格中
（如果 Pod 是全新的，则来自 CNI 插件；如果 Pod 已在运行但需要添加，
则来自 Kubernetes API 服务器），将被执行以下操作序列：

- `istio-cni` 进入 Pod 的网络命名空间并建立网络重定向规则，
  以便拦截进入和离开 Pod 的数据包并透明地重定向到在[已知端口](https://github.com/istio/ztunnel/blob/master/ARCHITECTURE.md#ports)
  （15008, 15006, 15001）上侦听的节点本地 ztunnel 代理实例。

- 然后，`istio-cni` 节点代理通过 Unix 域套接字通知 ztunnel 代理，
  它应该在 Pod 的网络命名空间内建立本地代理侦听端口（在端口 15008、15006 和 15001 上），
  并为 ztunnel 提供代表 Pod 网络命名空间的低级 Linux [文件描述符](https://en.wikipedia.org/wiki/File_descriptor)。
    - 虽然通常套接字是由实际在该网络命名空间内运行的进程在 Linux 网络命名空间内创建的，
      但完全可以利用 Linux 的低级套接字 API
      来允许在一个网络命名空间中运行的进程在另一个网络命名空间中创建侦听套接字，
      假设目标网络命名空间在创建时已知。

- 节点本地 ztunnel 在内部启动一个新的代理实例和侦听端口集，专用于被新添加的 Pod。

- 一旦 in-Pod 重定向规则到位并且 ztunnel 建立了侦听端口，
  Pod 就会被添加到网格中，并且流量开始流经节点本地 ztunnel。

默认情况下，网格中进出 Pod 的流量将使用 mTLS 完全加密。

现在，数据进入和离开 Pod 网络命名空间时将被加密。
网格中的每个 Pod 都能够执行网格策略并安全地加密流量，
即使 Pod 中运行的用户应用程序对此一无所知。

下图说明了新模型中 Ambient 网格中的 Pod 之间的加密流量如何流动：

{{< image width="100%"
    link="./traffic-flows-between-pods-in-ambient.svg"
    alt="HBONE 流量在 Ambient 网格中的 Pod 之间流动"
    >}}

## Ambient 模式下流量重定向的观测与调试 {#observing-and-debugging-traffic-redirection-in-ambient-mode}

如果流量重定向在 Ambient 模式下无法正常工作，可以进行一些快速检查以帮助缩小问题范围。
我们建议从 [ztunnel 调试指南](/zh/docs/ambient/usage/troubleshoot-ztunnel/)中描述的步骤开始进行故障排除。

### 检查 ztunnel 代理日志 {#check-the-ztunnel-proxy-logs}

当应用程序 Pod 是 Ambient 网格的一部分时，
您可以检查 ztunnel 代理日志以确认网格正在重定向流量。
如下例所示，与 `inpod` 相关的 ztunnel 日志表明已启用 Pod 内重定向模式，
代理已收到有关 Ambient 应用程序 Pod 的网络命名空间（netns）信息，并已开始为其代理。

{{< text bash >}}
$ kubectl logs ds/ztunnel -n istio-system  | grep inpod
Found 3 pods, using pod/ztunnel-hl94n
inpod_enabled: true
inpod_uds: /var/run/ztunnel/ztunnel.sock
inpod_port_reuse: true
inpod_mark: 1337
2024-02-21T22:01:49.916037Z  INFO ztunnel::inpod::workloadmanager: handling new stream
2024-02-21T22:01:49.919944Z  INFO ztunnel::inpod::statemanager: pod WorkloadUid("1e054806-e667-4109-a5af-08b3e6ba0c42") received netns, starting proxy
2024-02-21T22:01:49.925997Z  INFO ztunnel::inpod::statemanager: pod received snapshot sent
2024-02-21T22:03:49.074281Z  INFO ztunnel::inpod::statemanager: pod delete request, draining proxy
2024-02-21T22:04:58.446444Z  INFO ztunnel::inpod::statemanager: pod WorkloadUid("1e054806-e667-4109-a5af-08b3e6ba0c42") received netns, starting proxy
{{< /text >}}

### 确认套接字的状态 {#confirm-the-state-of-sockets}

按照以下步骤确认端口 15001、15006 和 15008 上的套接字已打开并处于侦听状态。

{{< text bash >}}
$ kubectl debug $(kubectl get pod -l app=sleep -n ambient-demo -o jsonpath='{.items[0].metadata.name}') -it -n ambient-demo  --image nicolaka/netshoot  -- ss -ntlp
Defaulting debug container name to debugger-nhd4d.
State  Recv-Q Send-Q Local Address:Port  Peer Address:PortProcess
LISTEN 0      128        127.0.0.1:15080      0.0.0.0:*
LISTEN 0      128                *:15006            *:*
LISTEN 0      128                *:15001            *:*
LISTEN 0      128                *:15008            *:*
{{< /text >}}

### 检查 iptables 规则设置 {#check-the-iptables-rules-setup}

要查看应用程序中一个 Pod 内的 iptables 规则设置，请执行以下命令：

{{< text bash >}}
$ kubectl debug $(kubectl get pod -l app=sleep -n ambient-demo -o jsonpath='{.items[0].metadata.name}') -it --image gcr.io/istio-release/base --profile=netadmin -n ambient-demo -- iptables-save

Defaulting debug container name to debugger-m44qc.
# 由 iptables-save 生成
*mangle
:PREROUTING ACCEPT [320:53261]
:INPUT ACCEPT [23753:267657744]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [23352:134432712]
:POSTROUTING ACCEPT [23352:134432712]
:ISTIO_OUTPUT - [0:0]
:ISTIO_PRERT - [0:0]
-A PREROUTING -j ISTIO_PRERT
-A OUTPUT -j ISTIO_OUTPUT
-A ISTIO_OUTPUT -m connmark --mark 0x111/0xfff -j CONNMARK --restore-mark --nfmask 0xffffffff --ctmask 0xffffffff
-A ISTIO_PRERT -m mark --mark 0x539/0xfff -j CONNMARK --set-xmark 0x111/0xfff
-A ISTIO_PRERT -s 169.254.7.127/32 -p tcp -m tcp -j ACCEPT
-A ISTIO_PRERT ! -d 127.0.0.1/32 -i lo -p tcp -j ACCEPT
-A ISTIO_PRERT -p tcp -m tcp --dport 15008 -m mark ! --mark 0x539/0xfff -j TPROXY --on-port 15008 --on-ip 0.0.0.0 --tproxy-mark 0x111/0xfff
-A ISTIO_PRERT -p tcp -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
-A ISTIO_PRERT ! -d 127.0.0.1/32 -p tcp -m mark ! --mark 0x539/0xfff -j TPROXY --on-port 15006 --on-ip 0.0.0.0 --tproxy-mark 0x111/0xfff
COMMIT
# 已完成
# 由 iptables-save 生成
*nat
:PREROUTING ACCEPT [0:0]
:INPUT ACCEPT [0:0]
:OUTPUT ACCEPT [175:13694]
:POSTROUTING ACCEPT [205:15494]
:ISTIO_OUTPUT - [0:0]
-A OUTPUT -j ISTIO_OUTPUT
-A ISTIO_OUTPUT -d 169.254.7.127/32 -p tcp -m tcp -j ACCEPT
-A ISTIO_OUTPUT -p tcp -m mark --mark 0x111/0xfff -j ACCEPT
-A ISTIO_OUTPUT ! -d 127.0.0.1/32 -o lo -j ACCEPT
-A ISTIO_OUTPUT ! -d 127.0.0.1/32 -p tcp -m mark ! --mark 0x539/0xfff -j REDIRECT --to-ports 15001
COMMIT
{{< /text >}}

命令输出显示，额外的 Istio 特定链已被添加到应用程序 Pod
网络命名空间内的 netfilter/iptables 中的 NAT 和 Mangle 表中。
所有进入 Pod 的 TCP 流量都会被重定向到 ztunnel 代理进行入口处理。
如果流量是明文（源端口不等于 15008），会被重定向到 in-Pod ztunnel 明文侦听端口 15006。
如果流量是 HBONE（源端口等于 15008），会被重定向到 in-Pod ztunnel HBONE 侦听端口 15008。
任何离开 Pod 的 TCP 流量都会被重定向到 ztunnel 的端口 15001 进行出口处理，
然后由 ztunnel 使用 HBONE 封装发送出去。
