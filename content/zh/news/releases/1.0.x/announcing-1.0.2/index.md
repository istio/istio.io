---
title: Istio 1.0.2 发布公告
linktitle: 1.0.2
subtitle: 补丁发布
description: Istio 1.0.2 补丁发布。
publishdate: 2018-09-06
release: 1.0.2
aliases:
    - /zh/about/notes/1.0.1
    - /zh/blog/2018/announcing-1.0.2
    - /zh/news/2018/announcing-1.0.2
    - /zh/news/announcing-1.0.2
---

我们很高兴的宣布 Istio 1.0.2 现已正式发布。下面是更新详情。

{{< relnote >}}

## 概况{#general}

- 修复 Envoy 的 bug：如果在双向 TLS 端口上接收正常流量，则 sidecar 会崩溃。

- 修复 Pilot 在多集群环境中向 Envoy 传播不完整更新的 bug。

- 为 Grafana 添加了更多 Helm 选项。

- 改进 Kubernetes 服务注册队列的性能。

- 修复 `istioctl proxy-status` 未显示补丁版本的 bug。

- 添加虚拟服务 SNI host 的验证。
