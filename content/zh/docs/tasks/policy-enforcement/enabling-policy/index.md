---
title: 启用策略检查功能 
description: 这个任务将告诉你如何开启 Istio 的策略检查功能。
weight: 1
keywords: [policies]
---

这个任务将告诉你如何开启 Istio 的策略检查功能。

## 安装阶段{#at-install-time}

在默认的 Istio 安装配置中，策略检查功能是关闭的。若要开启策略检查功能，需在安装选项中加入`--set values.global.disablePolicyChecks=false` 和 `--set values.pilot.policy.enabled=true`。

或者，也可以[按示例配置安装 Istio](/zh/docs/setup/getting-started/)，其中策略检查功能已默认开启。

## 对于已经安装的 Istio 网格{#for-an-existing-Istio-mesh}

1. 检查该网格中策略检查功能的状态。

    {{< text bash >}}
    $ kubectl -n istio-system get cm istio -o jsonpath="{@.data.mesh}" | grep disablePolicyChecks
    disablePolicyChecks: true
    {{< /text >}}

    如果策略检查功能已开启（`disablePolicyChecks`置为 false），则无需再做什么。

1. 修改 `istio` configuration，开启策略检查功能。

    在 Istio 根目录执行以下指令：

    {{< text bash >}}
    $ istioctl manifest apply --set values.global.disablePolicyChecks=false --set values.pilot.policy.enabled=true configuration "istio" replaced
    {{< /text >}}

1. 验证策略检查功能是否已启用。

    {{< text bash >}}
    $ kubectl -n istio-system get cm istio -o jsonpath="{@.data.mesh}" | grep disablePolicyChecks
    disablePolicyChecks: false
    {{< /text >}}
