---
title: 启用策略检查
description: 本任务讲解如何启用 Istio 策略检查功能。
weight: 1
keywords: [policies]
---

本任务讲解如何启用 Istio 策略检查功能。

## 对于初始安装

在 Istio 默认的安装配置中，策略检查是被禁用的。
要安装启用策略检查功能的 Istio，请使用 `--set global.disablePolicyChecks=false` Helm 安装选项。

或者，您也可以[使用演示配置安装 Istio](/docs/setup/kubernetes/install/kubernetes/)，这默认就启用了策略检查。

## 对于已经存在的 Istio 网格

1. 检查网格的策略检查状态。

    {{< text bash >}}
    $ kubectl -n istio-system get cm istio -o jsonpath="{@.data.mesh}" | grep disablePolicyChecks
    disablePolicyChecks: true
    {{< /text >}}

    如果启用了策略检查，则不需要进一步的操作。

1. 编辑 `istio` configmap 以启用策略检查。

    {{< text bash >}}
    $ kubectl -n istio-system get cm istio -o jsonpath="{@.data.mesh}" | sed -e "s/disablePolicyChecks: true/disablePolicyChecks: false/" > /tmp/mesh.yaml
    $ kubectl -n istio-system create cm istio -o yaml --dry-run --from-file=mesh=/tmp/mesh.yaml | kubectl replace -f -
    configmap "istio" replaced
    {{< /text >}}

1. 删除为修补 `istio` configmap 而创建的临时文件。

    {{< text bash >}}
    $ rm /tmp/mesh.yaml
    {{< /text >}}

1. 验证现在是否已经成功启用了策略检查。

    {{< text bash >}}
    $ kubectl -n istio-system get cm istio -o jsonpath="{@.data.mesh}" | grep disablePolicyChecks
    disablePolicyChecks: false
    {{< /text >}}
