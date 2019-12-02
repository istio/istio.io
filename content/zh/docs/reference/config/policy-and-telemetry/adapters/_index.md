---
title: 适配器
description: Mixer 适配器能够让 Istio 连接各种基础设施后端以完成类似指标和日志这样的功能。
weight: 40
aliases:
    - /zh/docs/reference/config/mixer/adapters/index.html
    - /zh/docs/reference/config/adapters/
---

{{< idea >}}
 要实现一个新的 Mixer 适配器，请参考[适配器开发者指南](https://github.com/istio/istio/wiki/Mixer-Compiled-In-Adapter-Dev-Guide)。
{{< /idea >}}

## 模板

下表显示了由每个支持的适配器实现的[模板](/zh/docs/reference/config/policy-and-telemetry/templates)。

{{< adapter_table >}}