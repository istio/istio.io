---
title: 组件调试
description: 如何从底层调试 Istio 组件。
weight: 25
---

通过检查[日志](/zh/help/ops/component-logging/)或[内检](/zh/help/ops/controlz/)，可以深入了解各组件的工作情况。除此之外，下面的步骤将有助于更加深入了解相关情况。

## 使用 `istioctl`

### 获取网格的状态

你可以通过 `proxy-status` 命令获取网格的状态：

{{< text bash >}}
$ istioctl proxy-status
{{< /text >}}

如果输出列表信息中缺少一个代理的信息，表示这个代理当前没有连接到 Pilot 实例，所以也不会接收任何配置信息。另外，如果有 `stale` 的标识，可能意味着存在网络问题或者 Pilot 需要扩容。

### 代理配置

可以使用 `istioctl` 的 `proxy-config` 或 `pc` 命令来查看代理的配置信息。

例如，要通过管理接口在 Envoy 中获取集群的配置，可运行以下命令：

{{< text bash >}}
$ istioctl proxy-config cluster <pod-name> [flags]
{{< /text >}}

要查询特定 Pod 的 Envoy 实例的引导配置信息，可运行以下命令：

{{< text bash >}}
$ istioctl proxy-config bootstrap <pod-name> [flags]
{{< /text >}}

要查询特定 Pod 的 Envoy 实例的侦听器配置信息，可运行以下命令：

{{< text bash >}}
$ istioctl proxy-config listener <pod-name> [flags]
{{< /text >}}

要查询特定 Pod 的 Envoy 实例的路由配置信息，可运行以下命令：

{{< text bash >}}
$ istioctl proxy-config route <pod-name> [flags]
{{< /text >}}

要查询特定 Pod 的 Envoy 实例的 Endpoint 信息，可运行以下命令：

{{< text bash >}}
$ istioctl proxy-config endpoints <pod-name> [flags]
{{< /text >}}

点击[配置问题诊断](/zh/help/ops/traffic-management/observing/)查看更多相关信息。

## 使用 GDB

要使用 `gdb` 调试 Istio，则需要运行 Envoy/Mixer/Pilot 的调试镜像。同时也需要新版本的 `gdb` 和 golang 扩展（用于 Mixer/Pilot 或其他 golang 组件）。

1. `kubectl exec -it PODNAME -c [proxy | mixer | pilot]`

1. 查找进程 ID：`ps ax`

1. gdb -p PID binary

1. 对于 go：info goroutines，goroutine x bt

## 使用 Tcpdump

Tcpdump 在 Sidecar 中不能工作 - 因为该容器不允许以 root 身份运行。但是由于同一 Pod 内会共享网络命名空间，因此 Pod 中的其他容器也能监听所有数据包。`iptables` 也能查看到 Pod 级别的相关配置。

Envoy 和应用程序之间的通信在地址 127.0.0.1 上进行，并且未进行加密。