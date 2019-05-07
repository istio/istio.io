---
title: 如何控制被 sidecar 报告的数据？
weight: 20
---

有时将对特定 URL 的访问排除在报告之外是有用的。
例如，您可能希望排除一些健康检查 URL。
您可以使用遥测配置的 `match` 子句将其排除，以跳过特定于某些 URL 的遥测报告。
例如：

{{< text yaml >}}
match: source.name != "health"
{{< /text >}}
