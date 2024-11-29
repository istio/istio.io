---
title: Ambient 和 Istio 控制平面
description: 了解 Ambient 如何与 Istio 控制平面交互。
weight: 2
owner: istio/wg-networking-maintainers
test: no
---

与所有 Istio {{< gloss "data plane" >}}数据平面{{< /gloss >}}模式一样，
Ambient 使用 Istio {{< gloss "control plane" >}}控制平面{{< /gloss>}}。
在 Ambient 中，控制平面与每个 Kubernetes 节点上的 {{< gloss >}}ztunnel{{< /gloss >}} 代理进行通信。

该图显示了 ztunnel 代理和 `istiod` 控制平面及控制平面相关组件的流程概述。

{{< image width="100%"
link="ztunnel-architecture.svg"
caption="Ztunnel 架构"
>}}

ztunnel 代理使用 xDS API 与 Istio 控制平面（`istiod`）进行通信。
这使得现代分布式系统所需的快速、动态配置更新成为可能。
ztunnel 代理还为使用 xDS 在其 Kubernetes 节点上调度的所有 Pod 的 Service Account
获取 {{< gloss "mutual tls authentication" >}}mTLS{{< /gloss >}} 证书。
单个 ztunnel 代理可以代表共享其节点的任何 Pod 实现 L4 数据平面功能，
这需要有效获取相关配置和证书。这种多租户架构与 Sidecar 模式形成鲜明对比，
在 Sidecar 模式中，每个应用程序 Pod 都有自己的代理。

另外值得注意的是，在 Ambient 模式下，xDS API 中使用一组简化的资源来进行 ztunnel 代理配置。
这会提高性能（必须传输和处理从 istiod 发送到 ztunnel 代理的小得多的信息集）并改进故障排除。
