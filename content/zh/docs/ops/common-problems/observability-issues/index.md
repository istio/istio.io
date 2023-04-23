---
title: 可观测性问题
description: 处理 Telemetry 收集问题。
force_inline_toc: true
weight: 30
aliases:
    - /zh/docs/ops/troubleshooting/grafana
    - /zh/docs/ops/troubleshooting/missing-traces
owner: istio/wg-policies-and-telemetry-maintainers
test: n/a
---

## 在 Mac 上运行 Istio 时，Zipkin 不生效{#no-traces-appearing-in-Zipkin-when-running-Istio-locally-on-mac}

Istio 已经完成安装并且都在正常工作，但是 Zipkin 中没有显示任何 trace 信息。

这可能是由已知的 [Docker 问题](https://github.com/docker/for-mac/issues/1260)引起的，
容器内的时间可能与主机上的时间有很大偏差。如果是这种情况，当您在 Zipkin 中选择了一个长时间范围时，
您可能会发现数据比预期早了一些时间。

您还可以通过对比 Docker 容器内和容器外的日期来确认该问题：

{{< text bash >}}
$ docker run --entrypoint date gcr.io/istio-testing/ubuntu-16-04-slave:latest
Sun Jun 11 11:44:18 UTC 2017
{{< /text >}}

{{< text bash >}}
$ date -u
Thu Jun 15 02:25:42 UTC 2017
{{< /text >}}

要解决此问题，您首先要重启 Docker 然后重新安装 Istio。

## 缺少 Grafana 输出{#missing-Grafana-output}

如果从本地 Web 客户端连接到 Istio 端时，无法获取 Grafana 的数据，
则应该验证客户端和服务器的日期和时间是否匹配。

Web 客户端（例如：Chrome）的时间会影响 Grafana 的输出。此问题的简单解决方案是验证
Kubernetes 集群内的时间同步服务是否正确运行，以及 Web 客户端计算机是否也与目标服务器的时间相同。
一些常见的时间同步系统有 NTP 和 Chrony。在有防火墙的实验室中问题比较严重。
这种情况可能是 NTP 没有正确配置，指向基于实验室的 NTP 服务。

## 验证 Istio CNI Pod 正在运行（如果使用）{#verify-Istio-CNI-pods-are-running}

Istio CNI 插件在 Kubernetes Pod 生命周期中的网络配置阶段执行 Istio
网格 Pod 流量重定向，从而消除了用户将 Pod 部署到 Istio 网格中的
[`NET_ADMIN` 和 `NET_RAW` 的需求](/zh/docs/ops/deployment/requirements/)。
Istio CNI 插件取代了 `Istio-init` 容器提供的功能。

1. 验证 `istio-cni-node` Pod 正在运行：

    {{< text bash >}}
    $ kubectl -n kube-system get pod -l k8s-app=istio-cni-node
    {{< /text >}}

1. 如果 `PodSecurityPolicy` 在您的集群中正在工作，确认 `istio-cni`
   Service Account 可以使用 `PodSecurityPolicy` 的
   [`NET_ADMIN` 和 `NET_RAW` 的功能](/zh/docs/ops/deployment/requirements/)。
