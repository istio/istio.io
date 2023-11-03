---
title: 使用 istioctl check-inject 验证 Istio Sidecar 注入
description: 了解如何使用 istioctl check-inject 来确认是否为您的 Deployment 正确启用了 Istio Sidecar 注入。
weight: 45
keywords: [istioctl, injection, kubernetes]
owner: istio/wg-user-experience-maintainers
test: no
---

`istioctl experimental check-inject` 是一个诊断工具，可帮助您验证特定
Webhook 是否会在 Pod 中执行 Istio Sidecar 注入。这个工具可用于检查 Sidecar
注入的配置是否正确地应用于一个活跃的集群。

## 快速入门  {#quick-start}

要检查针对特定 Pod 为什么 Istio Sidecar 注入已发生/未发生（或将发生/不会发生），
请运行：

{{< text syntax=bash >}}
$ istioctl experimental check-inject -n <namespace> <pod-name>
{{< /text >}}

对于 Deployment，请运行：

{{< text syntax=bash >}}
$ istioctl experimental check-inject -n <namespace> deploy/<deployment-name>
{{< /text >}}

或者，对于标签对：

{{< text syntax=bash >}}
$ istioctl experimental check-inject -n <namespace> -l <label-key>=<label-value>
{{< /text >}}

例如，如果您在 `hello` 命名空间中有一个名为 `httpbin` 的 Deployment 和一个名为
`httpbin-1234` 且标签为 `app=httpbin` 的 Pod，则以下命令是等效的：

{{< text syntax=bash >}}
$ istioctl experimental check-inject -n hello httpbin-1234
$ istioctl experimental check-inject -n hello deploy/httpbin
$ istioctl experimental check-inject -n hello -l app=httpbin
{{< /text >}}

示例结果：

{{< text plain >}}
WEBHOOK                      REVISION  INJECTED      REASON
istio-revision-tag-default   default   ✔             Namespace label istio-injection=enabled matches
istio-sidecar-injector-1-18  1-18      ✘             No matching namespace labels (istio.io/rev=1-18) or pod labels (istio.io/rev=1-18)
{{< /text >}}

如果 `INJECTED` 字段标记为 `✔`， 则该行中的 Webhook 将执行注入，
并说明 Webhook 将进行边车注入的原因。

如果 `INJECTED` 字段标记为 `✘`，则该行中的 Webhook 将不执行注入，
并且也会显示原因。

Webhook 不执行注入或注入有错误的可能原因：

1. **没有匹配的命名空间标签或 Pod 标签**：确保在命名空间或 Pod 上设置正确的标签。

1. **没有匹配特定修订版本的命名空间标签或Pod标签**：设置正确的标签以匹配所需的 Istio 修订版本。

1. **防止注入的 Pod 标签**：删除标签或将其设置为适当的值。

1. **防止注入的命名空间标签**：将标签更改为适当的值。

1. **多个 Webhook 注入 sidecar**：确保只启用一个 Webhook 进行注入，在命名空间或
   Pod 上设置适当的标签以针对特定的 Webhook。
