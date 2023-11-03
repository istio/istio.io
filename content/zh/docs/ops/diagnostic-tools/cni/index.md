---
title: Istio CNI 插件故障排除
description: 描述使用 Istio 和 CNI 插件诊断问题的工具和技术。
weight: 90
keywords: [debug,cni]
owner: istio/wg-networking-maintainers
test: n/a
---

本页介绍如何解决 Istio CNI 插件的问题。在阅读本文之前，您须阅读
[CNI 安装和操作指南](/zh/docs/setup/additional-setup/cni/)。

## 日志 {#log}

Istio CNI 插件日志基于 `PodSpec` 提供了有关插件如何配置应用程序 Pod
流量重定向的信息。

该插件在容器运行时进程空间中运行，因此您可以在 `kubelet` 日志中看到 CNI 日志条目。
为了使调试更容易，CNI 插件还将其日志发送到 `istio-cni-node` DaemonSet。

CNI 插件的默认日志级别是 `info`。要获得更详细的日志输出，可以通过编辑
`values.cni.logLevel` 安装选项并重新启动 CNI DaemonSet Pod 来更改级别。

Istio CNI DaemonSet Pod 日志还提供了有关 CNI 插件安装的信息以及[竞争条件和缓解措施](/zh/docs/setup/additional-setup/cni/#race-condition-mitigation)。

## 监控 {#monitoring}

CNI DaemonSet [generates metrics](/zh/docs/reference/commands/install-cni/#metrics)，
可用于监视 CNI 的安装、准备就绪和竞争条件缓解措施。默认情况下，Prometheus 抓取注释（`prometheus.io/port`，
`prometheus.io/path`）被添加到 `istio-cni-node` DaemonSet Pod 中。
您可以通过标准 Prometheus 配置收集生成的指标。

## DaemonSet 准备就绪 {#daemonset-readiness}

CNI DaemonSet 的就绪表明 Istio CNI 插件已正确安装和配置。
如果 Istio CNI DaemonSet 尚未准备好，则表明出现了问题。查看
`istio-cni-node` 守护进程日志进行诊断。您还可以通过 `istio_cni_install_ready`
指标跟踪 CNI 安装准备情况。

## 竞争条件和缓解措施 {#race-condition-repair}

Istio CNI DaemonSet 默认启用[竞争条件和缓解措施](/zh/docs/setup/additional-setup/cni/#race-condition-mitigation)，
这将驱逐在 CNI 插件准备就绪之前启动的 Pod。要了解哪些 Pod 被驱逐，请查找如下所示的日志行：

{{< text plain >}}
2021-07-21T08:32:17.362512Z     info   Deleting broken pod: service-graph00/svc00-0v1-95b5885bf-zhbzm
{{< /text >}}

您还可以通过 `istio_cni_repair_pods_repaired_total` 指标追踪修复的 Pod。

## 诊断 Pod 启动失败 {#diagnose-pod-start-up-failure}

CNI 插件的一个常见问题是由于容器网络设置失败，Pod 无法启动。
通常，失败原因会写入 Pod 事件，并通过 Pod 描述可见：

{{< text bash >}}
$ kubectl describe pod POD_NAME -n POD_NAMESPACE
{{< /text >}}

如果 Pod 持续出现 init 错误，请检查 init 容器 `istio-validation` 日志
"连接被拒绝"错误如下:

{{< text bash >}}
$ kubectl logs POD_NAME -n POD_NAMESPACE -c istio-validation
...
2021-07-20T05:30:17.111930Z     error   Error connecting to 127.0.0.6:15002: dial tcp 127.0.0.1:0->127.0.0.6:15002: connect: connection refused
2021-07-20T05:30:18.112503Z     error   Error connecting to 127.0.0.6:15002: dial tcp 127.0.0.1:0->127.0.0.6:15002: connect: connection refused
...
2021-07-20T05:30:22.111676Z     error   validation timeout
{{< /text >}}

`istio-validation` init 容器设置一个本地虚拟服务器，该服务器监听流量重定向目标入/出端口，
并检查测试流量是否可以重定向到虚拟服务器。当 CNI 插件未正确设置 Pod 流量重定向时，
`istio-validation` init 容器阻止 Pod 启动，以防止流量绕过。
要查看是否有任何错误或意外的网络设置行为，在 `istio-cni-node` 中搜索 Pod ID。

CNI 插件出现故障的另一个症状是，在启动时，应用程序 Pod 不断被逐出。
这通常是因为插件没有正确安装，因此无法设置 Pod 流量重定向。
CNI 的[竞争条件和缓解措施](/zh/docs/setup/additional-setup/cni/#race-condition-mitigation)
认为由于竞争条件引起的问题导致 Pod 损坏，并连续逐出该 Pod。遇到此问题时，请检查 CNI DaemonSet 日志，
以获取有关无法正确安装插件的信息。
