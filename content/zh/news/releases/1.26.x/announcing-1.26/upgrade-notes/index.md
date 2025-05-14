---
title: Istio 1.26 升级说明
description: 升级到 Istio 1.26.0 时要考虑的重要变更。
weight: 20
---

当您从 Istio 1.25.x 升级到 Istio 1.26.x 时，您需要考虑本页所述的变更。
这些说明详述了故意打破 Istio 1.25.x 向后兼容性的一些变更。
这些说明还提到了在引入新特性的同时保持向后兼容性的一些变更。
这里仅包含出乎 Istio 1.25.x 用户意料的新特性变更。

## 即将删除遥测提供商 {#upcoming-removal-of-telemetry-providers}

Lightstep 和 OpenCensus 的遥测提供程序已被弃用（分别自 1.22 和 1.25 起），
因为它们都已被 OpenTelemetry 提供程序取代。它们将在 Istio 1.27 中被移除。
如果您使用其中任何一种提供程序，请立即更改为使用 OpenTelemetry 提供程序。

## ztunnel Helm Chart 变化 {#ztunnel-helm-chart-changes}

在 Istio 1.25 中，ztunnel Helm Chart 中的资源名称更改为 `.Resource.Name`。
这经常导致问题，因为名称需要与 Istiod Helm Chart 保持同步。

在此版本中，我们已将默认的 `ztunnel` 名称恢复为静态名称。
与之前一样，可以使用 `--set resourceName=my-custom-name` 覆盖此名称。
