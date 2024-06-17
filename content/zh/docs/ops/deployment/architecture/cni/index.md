---
title: CNI 插件
description: 描述 Istio 的 CNI 插件的工作原理。
weight: 10
owner: istio/wg-networking-maintainers
test: n/a
---

Kubernetes 具有独特且宽松的网络模型。为了在 Pod 之间配置 L2-L4 网络，
[Kubernetes 集群需要一个容器网络接口（CNI）**interface** 插件](https://kubernetes.io/zh-cn/docs/concepts/extend-kubernetes/compute-storage-net/network-plugins/)。
此插件在创建新 Pod 时运行，并为该 Pod 设置网络环境。

如果您正在使用托管的 Kubernetes 提供商，那么您通常在集群中获取的 CNI 插件的选择有限：它是托管实现的实现细节。

为了配置网格流量重定向，无论您或您的提供商选择使用哪种 CNI 进行 L2-L4 网络，
Istio 都包含一个 **chained** CNI 插件，该插件在所有配置的 CNI 接口插件之后运行。
用于定义链式和接口插件以及在它们之间共享数据的 API 是 [CNI 规范](https://www.cni.dev/) 的一部分。
Istio 适用于所有遵循 CNI 标准的 CNI 实现，包括 Sidecar 模式和 Ambient 模式。

Istio CNI 插件在 Sidecar 模式下是可选的，在 {{<gloss>}}Ambient{{< /gloss >}} 模式下是必需的。

* [了解如何在安装 Istio 时使用 CNI 插件](/zh/docs/setup/additional-setup/cni/)
