---
title: 如何控制 sidecar 上报数据？
weight: 20
---

有时会对访问的特定 URL 排除在上报之外，这样做是有用的。例如，你可能希望把健康检测的 URL 剔除。可以配置使用 `match` 语法来跳过匹配到的 URL 上报，比如：

{{< text yaml >}}
match: source.name != "health"
{{< /text >}}
