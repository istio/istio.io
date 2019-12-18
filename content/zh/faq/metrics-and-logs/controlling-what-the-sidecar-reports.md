---
title: 如何控制 sidecar 上报数据？
weight: 20
---

有时候对上报的 URL 中剔除一些是非常有用的。例如，你可能希望把健康检测的 URL 剔除。可以配置使用 `match` 语法来跳过匹配到的 URL 上报，比如：

{{< text yaml >}}
match: source.name != "health"
{{< /text >}}
