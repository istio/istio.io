---
title: Analyzer Message Format
---

The `istioctl analyze` command provides messages in the format:

{{< text plain >}}
<level> [<code>] (<affected-resource>) <message-details>
{{< /text >}}

The `<affected-resource>` field expands to:

{{< text plain >}}
<resource-kind> <resource-name>.<resource-namespace>
{{< /text >}}

For example:

{{< text plain >}}
Error [IST0101] (VirtualService httpbin.default) Referenced gateway not found: "httpbin-gateway-bogus"
{{< /text >}}

The `<message-details>` field contains a detailed description that may contain further information to help resolve the problem. The namespace suffix is omitted for cluster-scoped resources, for example `namespace`.
