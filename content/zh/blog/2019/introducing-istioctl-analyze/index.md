---
title: istioctl analyze 介绍
description: 通过分析 Istio 配置来发现潜在问题和一般问题。
publishdate: 2019-11-14
subtitle:
attribution: David Ebbo (Google)
keywords: [debugging,istioctl,configuration]
target_release: 1.4
---

Istio 1.4 引入了一个实验性的新工具，可以帮助分析和调试正在运行 Istio 的集群。

[`istioctl analyze`](/zh/docs/reference/commands/istioctl/#istioctl-experimental-analyze) 是一个诊断工具，来发现 Istio 配置的潜在问题，也会给出一些改进配置的意见。
它可以针对一个正在运行的集群或者是一堆本地配置文件。
还可以是这两种方式的组合，让您在对集群应用更改之前发现问题。

开始之前，先看看这里的[文档](/zh/docs/ops/diagnostic-tools/istioctl-analyze/)。

## 专为新手用户设计 {#designed-to-be-approachable-for-novice-users}

我们遵循的其中一个关键设计目标就是要非常容易使用，就是不需要传复杂参数而让命令又很有用。

实际中，下面是这个工具要应对的一些场景：

- *“集群有问题，但是不知该从何入手”*
- *“运行起来没问题，但是不知道是否还有优化空间”*

从这个意义上讲，它与某些更高级的诊断工具有很大的不同，后者适合以下场景（以 `istioctl proxy-config` 为例）：

- *“列出指定 pod 的 Envoy 配置，来看看有没有问题”*

这对高级调试非常有用，但是这需要非常多的经验，你才能知道需要运行这条命令，以及在哪个 pod 上运行。

因此，用一句话来说明 `analyze` 就是：尽管运行！它非常安全，不用考虑，可能会有帮助，最坏的情况就是浪费你一分钟！

## 这个工具在不断改进中 {#improving-this-tool-over-time}

在 Istio 1.4 中，`analyze` 有一组可以检测很多常见文档的好分析器。但这只是开始，我们计划在后期每个版本中不断增加和优化分析器。

事实上，我们欢迎 Istio 用户提建议。特别是遇到您认为可以用配置分析器检测的情况时，而 `analyze` 没有正确标出来，请告诉我们。最好的方式就是[在 GitHub 上建 issue](https://github.com/istio/istio/issues)。
