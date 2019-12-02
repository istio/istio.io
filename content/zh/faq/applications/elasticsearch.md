---
title: 我能在 Istio 网格中运行 Elasticsearch 吗?
description: 在 Istio 中运行 Elasticsearch 需要的配置
weight: 50
keywords: [elasticsearch]
---

在 Istio 中运行 Elasticsearch，有两个 Elasticsearch 配置参数需要被正确设置：`network.bind_host` 和 `network.publish_host`。默认情况下，这些参数值被设置成 `network.host` 参数。如果 `network.host` 被设置成 `0.0.0.0`，Elasticsearch 很可能选择 pod IP 作为发布地址并且不需要更进一步的配置。

如果默认配置没有生效，你可以将 `network.bind_host` 设置为 `0.0.0.0` 或 `localhost` (`127.0.0.1`) 并将 `network.publish_host` 设置为 pod IP，例如：

{{< text yaml >}}
...
containers:
- name: elasticsearch
  image: docker.elastic.co/elasticsearch/elasticsearch:7.2.0
  env:
    - name: network.bind_host
      value: 127.0.0.1
    - name: network.publish_host
      valueFrom:
        fieldRef:
          fieldPath: status.podIP
   ...
{{< /text >}}

了解更多信息请查看 [Elasticsearch 网络设置](https://www.elastic.co/guide/en/elasticsearch/reference/current/modules-network.html#modules-network)。
