---
title: Analyzer Message Format
---

`istioctl analyze` 命令规定以下格式：

{{< text plain >}}
<level> [<code>] (<affected-resource>) <message-details>
{{< /text >}}

`<affected-resource>` 字段的详细格式如下：

{{< text plain >}}
<resource-kind> <resource-name>.<resource-namespace>
{{< /text >}}

例如:

{{< text plain >}}
Error [IST0101] (VirtualService httpbin.default) Referenced gateway not found: "httpbin-gateway-bogus"
{{< /text >}}

包含详细描述的 `<message-details>` 字段也许可以帮你进一步解决问题, 对于集群范围的资源，例如 `namespace`，将省略其后缀。
