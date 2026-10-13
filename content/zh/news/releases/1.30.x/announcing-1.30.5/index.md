---
title: 发布 Istio 1.30.5
linktitle: 1.30.5
subtitle: 补丁发布
description: Istio 1.30.5 补丁发布。
publishdate: 2026-09-21
release: 1.30.5
aliases:
    - /zh/news/announcing-1.30.5
---

此版本包含一些安全修复，以提高稳定性。
本发行说明描述了 Istio 1.30.4 和 Istio 1.30.5 之间的区别。

{{< relnote >}}

## 变更 {#changes}

- **修复** 修复了 Ambient 模式下的一个问题：CNI 节点代理自动检测到的
  iptables 后端（`legacy` 或 `nft`）可能会在代理重启期间发生变化，
  导致重复的重定向规则被写入已纳管的 Pod 中。
  ([Issue #61020](https://github.com/istio/istio/issues/61020))

- **修复** 修复了 JWKS 解析器强制所有公钥获取到 HTTP/1.1。
  用于 TLS 固定和 CIDR 阻止的自定义 `TLSClientConfig` 和 `DialContext`
  导致 Go 的 `net/http` 禁用自动 HTTP/2，因此 ALPN 从未协商过 h2。
  现在重新启用 HTTP/2（与 `http.DefaultTransport` 匹配），
  修复了通过某些 HTTP CONNECT 代理故障转移 HTTP/1.1 的 JWKS 获取。
  ([Issue #61250](https://github.com/istio/istio/issues/61250))

- **修复** 修复了 istiod 在将工作负载元数据推送到 Envoy 代理时重复序列化相同工作负载的问题。
  ([Issue #61502](https://github.com/istio/istio/issues/61502))

- **修复** 修复了当启用 `AMBIENT_SCOPED_ADDRESS_PUSHES`（默认）时，
  订阅工作负载元数据发现 (MDS) 的 Envoy 代理未收到仅地址更改的增量工作负载更新的问题。

- **修复** 修复了当网络具有多个网关条目时，为工作负载选择的网络网关会以随机顺序选取的问题，
  这会导致每次重新计算时出现不必要的工作负载 (WDS) 推送，
  并可能导致工作负载的网关地址发生交替。

- **修复** 修复了 `sidecar.istio.io/statsFlushInterval`
  注解对于一分钟或更长的值以及亚秒值产生无效的 Envoy 引导，从而阻止代理启动。

- **修复** 修复了 `sidecar.istio.io/statsEvictionInterval`
  注解会默默地截断亚秒精度。

- **修复** 修复了 ListenerSet 状态报告，以便没有有效侦听器的 ListenerSet
  现在将 `Accepted` 和 `Programmed` 条件报告为 `False`，
  原因为 `ListenersNotValid`。以前，即使没有侦听器可用，
  ListenerSet 级别的条件也可以保持 `True`。

- **修复** 修复了具有当前但空的工作负载选择器的 ServiceEntries
  错误地匹配其命名空间中的所有工作负载。

- **修复** 修复了 `observedGeneration` 在资源再次修改而早期状态写入仍在排队时卡在过时值上。

- **修复** 修复了 `istioctl analyze` 直接从 `istio-system`
  多集群机密构建 Kubernetes 客户端，而不清理 kubeconfig，
  这可能允许精心设计的机密在运行 `istioctl` 的机器上运行 `exec`
  凭证插件（或通过其他不安全的身份验证字段读取本地文件）。
  现在 kubeconfig 的清理方式与 istiod 清理这些秘密的方式相同。

  **感谢**：此漏洞由 Adam Korczynski 发现并报告。
