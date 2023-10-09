---
title: 发布 Istio 1.19.1
linktitle: 1.19.1
subtitle: 补丁发布
description: Istio 1.19.1 补丁发布。
publishdate: 2023-10-02
release: 1.19.1
---

本发布说明描述了 Istio 1.19.0 和 Istio 1.19.1 之间的不同之处。

{{< relnote >}}

## 变更 {#changes}

- **新增** 添加了使用双堆栈服务定义安装 Gateway Helm Chart 的功能。

- **新增** 为 `ProxyConfig` 和 `ProxyHeaders` 添加了新配置。
  这些配置允许自定义如 `server`、`x-forwarded-client-cert` 等标头。
  最值得注意的是，为了让这些标头不会被修改现在可以禁用这些配置。

- **新增** 为 `ProxyHeaders` 和 `MetadataExchangeHeaders` 添加了新配置。
  `IN_MESH` 模式确保 `x-envoy-peer-metadata` 和 `x-envoy-peer-metadata-id`
  标头不会添加到从 Sidecar 到被视为网格外部的目标服务的出站请求中。
  ([Issue #17635](https://github.com/istio/istio/issues/17635))

- **修复** 修复了默认控制平面和修订控制平面之间错误发出升级警告的问题。

- **修复** 修复了当 Ambient 命名空间标签更改时，Ambient Pod 被错误处理的问题。

- **修复** 修复了 Istio CNI 插件没有为双堆栈集群编写 IPv6 iptables 规则的问题。
  ([Issue #46625](https://github.com/istio/istio/issues/46625))

- **修复** 修复了当只有默认提供程序时
  `meshConfig.defaultConfig.sampling` 被忽略的问题。
  ([Issue #46653](https://github.com/istio/istio/issues/46653))

- **修复** 修复了当我们未将无效证书推送回 Envoy 时，SDS 获取超时的问题。
  ([Issue #46868](https://github.com/istio/istio/issues/46868))

- **修复** 修复了由于 `NetworkAttachmentDefinition`
  资源验证失败而导致安装过程失败的问题。
  ([Issue #46859](https://github.com/istio/istio/issues/46859))

- **修复** 修复了 `DNSNoEndpointClusters` 指标不起作用的问题。
  ([Issue #46960](https://github.com/istio/istio/issues/46960))

- **修复** 修复了 `istioctl proxy-config all` 的输出，
  以在使用 `--json` 或 `--yaml` 标志时包含 EDS 配置。

- **修复** 修复了控制平面指标中的一个导致仪表类型除了预期指标之外还发出没有标签零值的问题。
  ([Issue #46977](https://github.com/istio/istio/issues/46977))

## 安全更新 {#security-update}

此版本中没有安全更新。
