---
title: MultiClusterInconsistentService
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: n/a
---

当多集群网格中两个或多个集群里具有相同名称和命名空间的 `Service` 定义不一致时，会出现此消息。

Istio 会将所有集群中具有相同名称和命名空间的服务合并为一个服务。
如果这些定义不一致，其行为是未定义的。分析器会比较以下内容：

- 服务类型。
- 端口。
- 服务是否为无头服务（`clusterIP: None`）。

## 示例 {#example}

您将收到如下消息：

{{< text plain >}}
Warning [IST0170] (Service sample/helloworld) The service helloworld in namespace "sample" is inconsistent across clusters ["cluster1" "cluster2"], which can lead to undefined behaviors. The inconsistent behaviors are: service ports are inconsistent.
{{< /text >}}

## 如何修复 {#how-to-resolve}

确保所有集群中的 `Service` 定义一致。
