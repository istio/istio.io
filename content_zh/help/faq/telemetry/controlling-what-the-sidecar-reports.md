---
title: 如何控制由 sidecar 上报的数据？
weight: 20
---

有时，禁止上报特定 URL 的访问信息也是有用的。比如，用户可能会想要排除一些健康检查的 URL。为了跳过特定 URL 的遥感报告，用户可以通过使用遥测配置中的 `match` 子句来实现。
比如：

{{< text yaml >}}
match: source.name != "health"
{{< /text >}}
