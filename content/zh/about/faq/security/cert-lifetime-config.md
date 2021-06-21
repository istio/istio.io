---
title: 如何配置 Istio 证书的生命期？
weight: 70
---

对于在 Kubernetes 中运行的工作负载，其 Istio 证书的生命周期默认为 24 小时。

可以通过自定义 [代理配置](/zh/docs/reference/config/istio.mesh.v1alpha1/#ProxyConfig)的 `proxyMetadata` 字段来覆盖此配置。 例如：

{{< text yaml >}}
proxyMetadata:
  SECRET_TTL: 48h
{{< /text >}}

{{< tip >}}
超过 90 天的值将不被接受。
{{< /tip >}}
