---
title: 组件调试
description: 如何从底层调试 Istio 组件。
weight: 25
---

通过检查[日志](/zh/help/ops/component-logging/)或[内检](/zh/help/ops/controlz/)，可以深入了解各组件的工作情况。除此之外，下面的步骤将有助于更加深入了解相关情况。

## 使用 `istioctl`

`istioctl` 允许使用 `proxy-config` 或 `pc` 命令从其管理接口（本地）或 Pilot 来检查给定 Envoy 的 xDS 配置。

例如，要通过管理接口在 Envoy 中获取集群的配置，可运行以下命令：

{{< text bash >}}
$ istioctl proxy-config endpoint <pod-name> clusters
{{< /text >}}

要从 Pilot 查询应用程序命名空间内给定 pod 的 endpoint，可运行以下命令：

{{< text bash >}}
$ istioctl proxy-config pilot -n application <pod-name> eds
{{< /text >}}

`proxy-config` 命令还可以使用以下命令从 Pilot 检索整个网格的状态：

{{< text bash >}}
$ istioctl proxy-config pilot mesh ads
{{< /text >}}

## 使用 GDB

要使用 `gdb` 调试 Istio，则需要运行 Envoy/Mixer/Pilot 的调试镜像。同时也需要新版本的 `gdb` 和 golang 扩展（用于 Mixer/Pilot 或其他 golang 组件）。

1. `kubectl exec -it PODNAME -c [proxy | mixer | pilot]`

1. 查找进程 ID：`ps ax`

1. gdb -p PID binary

1. 对于 go： info goroutines，goroutine x bt

## 使用 Tcpdump

Tcpdump 在 sidecar pod 中不能工作 - 因为该容器不允许以 root 身份运行。但是由于同一 pod 网络命名空间是共享，因此 pod 中的其他容器也能监听所有数据包。`iptables` 也能查看到 pod 级别的相关配置。

Envoy 和应用程序之间的通信在地址 127.0.0.1 上进行，并且未进行加密。