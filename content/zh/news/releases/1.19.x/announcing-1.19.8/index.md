---
title: 发布 Istio 1.19.8
linktitle: 1.19.8
subtitle: 补丁发布
description: Istio 1.19.8 补丁发布。
publishdate: 2024-03-14
release: 1.19.8
---

本发布说明描述了 Istio 1.19.7 和 Istio 1.19.8 之间的不同之处。

{{< relnote >}}

## 变更 {#changes}

- **新增** 向 Istio 组件添加了环境变量 `COMPLIANCE_POLICY`，
  以强制执行 TLS 限制以符合 FIPS。当在 Istiod 容器、
  Istio 代理容器和所有其他 Istio 组件上设置为 `fips-140-2` 时，
  TLS 版本限制为 `v1.2`，密码套件为 `ECDHE-ECDSA-AES128-GCM-SHA256`、
  `ECDHE-RSA-AES128-GCM-SHA256`、`ECDHE-ECDSA-AES256-GCM-SHA384`、
  `ECDHE-RSA-AES256-GCM-SHA384` 和 ECDH 转到 `P-256` 的子级。

    这些限制适用于以下数据路径：
    * Envoy 代理之间的 mTLS 通信。
    * Envoy 代理下游和上游的常规 TLS（例如网关）
    * 来自 Envoy 代理的 Google gRPC 端请求（例如 Stackdriver 扩展）。
    * Istiod xDS 服务器。
    * Istiod 用于注入和验证 Webhook 服务器。

    这些限制不适用于以下数据路径：
    * Istiod 到 Kubernetes API 服务器。
    * 从 Istiod 获取 JWK。
    * 从 Istio 代理容器获取 Wasm 镜像和 URL。
    * ztunnel。

    请注意，当设置后，Istio 注入器会将 `COMPLIANCE_POLICY`
    的值传播到被注入的代理容器中。
    ([Issue #49081](https://github.com/istio/istio/issues/49081))

- **修复** 修复了本地客户端在本地 DNS 名称表中包含不正确条目的问题。
  ([Issue #47340](https://github.com/istio/istio/issues/47340))

- **修复** 修复了一个其中包含服务注册表中不存在的通配符主机的
  `VirtualService` 被忽略的错误。
  ([Issue #49364](https://github.com/istio/istio/issues/49364))

- **修复** 修复了 `istioctl precheck` 报告与资源权限相关的 IST0141 消息不准确的问题。
  ([Issue #49379](https://github.com/istio/istio/issues/49379))

- **修复** 修复了在 `VirtualService` 中使用委托时，
  由于排序错误，有效的 `VirtualService` 可能与预期不一致的问题。
  ([Issue #49539](https://github.com/istio/istio/issues/49539))

- **修复了** 修复了在 `VirtualService` HTTP 路由中指定 URI
  正则表达式 `.*` 匹配不会使后续 HTTP 路由短路的错误。
