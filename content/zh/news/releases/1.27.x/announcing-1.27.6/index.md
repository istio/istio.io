---
title: 发布 Istio 1.27.6
linktitle: 1.27.6
subtitle: 补丁发布
description: Istio 1.27.6 补丁发布。
publishdate: 2026-02-10
release: 1.27.6
aliases:
    - /zh/news/announcing-1.27.6
---

此版本包含一些错误修复，以提高稳定性。
本发行说明描述了 Istio 1.27.5 和 Istio 1.27.6 之间的区别。

{{< relnote >}}

## 变更 {#changes}

- **新增** 添加了网关部署控制器的安全措施，以验证对象类型、
  名称和命名空间，防止通过模板注入创建任意 Kubernetes 资源。
  ([Issue #58891](https://github.com/istio/istio/issues/58891))

- **新增** 添加了端口 15014 上调试端点的基于命名空间的授权。
  非系统命名空间现在仅限于 `config_dump/ndsz/edsz` 端点和同命名空间代理。
  如果需要兼容性，可以使用 `ENABLE_DEBUG_ENDPOINT_AUTH=false` 禁用此功能。

- **新增** 在基于版本的迁移期间，向网关 Helm Chart
  添加了 `service.selectorLabels` 字段，用于自定义服务选择器标签。

- **修复** 修复了资源注解验证，拒绝换行符和控制字符，这些字符可能会通过模板渲染将容器注入到 Pod 规约中。
  ([Issue #58889](https://github.com/istio/istio/issues/58889))

- **修复** 修复了下游 TLS 上下文中 `meshConfig.tlsDefaults.minProtocolVersion`
  到 `tls_minimum_protocol_version` 的映射错误。
