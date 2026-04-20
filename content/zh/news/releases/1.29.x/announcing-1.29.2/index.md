---
title: 发布 Istio 1.29.2
linktitle: 1.29.2
subtitle: 补丁发布
description: Istio 1.29.2 补丁发布。
publishdate: 2026-04-13
release: 1.29.2
aliases:
    - /zh/news/announcing-1.29.2
---

此版本包含一些错误修复，以提高稳定性。
本发行说明描述了 Istio 1.29.1 和 Istio 1.29.2 之间的区别。

{{< relnote >}}

## 变更 {#changes}

- **新增** 添加了对 Helm v4（服务器端应用）的支持。
  修复了 Webhook `failurePolicy` 字段的所有权冲突，
  该冲突曾导致使用 SSA 执行 `helm upgrade` 时失败。
  ([Issue #58302](https://github.com/istio/istio/issues/58302))
  ([Issue #59367](https://github.com/istio/istio/issues/59367))

- **修复** 修复了当集群中安装的 CRD 版本高于支持的最高版本时，
  istiod 启动失败的错误。目前支持 `TLSRoute` v1.4 及以下版本；
  v1.5 及以上版本将被忽略。
  ([Issue #59443](https://github.com/istio/istio/issues/59443))

- **修复** 修复了在控制平面未更新 `istio-reader` `ClusterRole`
  导致无法从远程 `ConfigMap` 读取信任域时，
  多集群安装过程中会尝试验证错误的信任域的问题。现在，
  istiod 将回退使用本地网格配置中指定的信任域，直至其能够成功读取远程信任域为止。
  ([Issue #59474](https://github.com/istio/istio/issues/59474))

- **修复** 修复了将多个针对同一主机名的 `VirtualService` 资源应用到 waypoint 的问题。
  ([Issue #59483](https://github.com/istio/istio/issues/59483))

- **修复** 修复了一个问题：当 `EnvoyFilter` 对 `VIRTUAL_HOST` 执行 `REPLACE` 操作时，
  `istioctl` 会错误地报告错误。
  ([Issue #59495](https://github.com/istio/istio/issues/59495))

- **修复** 了一个问题，由于 Envoy 中的连接池配置有误，
  东西向网关偶尔会将 HBONE 连接路由至错误的服务。
  ([Issue #58630](https://github.com/istio/istio/issues/58630))

- **修复** 修复了 `AuthorizationPolicy` 中的 `serviceAccount` 匹配正则表达式，
  现已能正确引用服务账号名称，从而确保能够正确匹配名称中包含特殊字符的服务账号。
  ([Issue #59700](https://github.com/istio/istio/issues/59700))

- **修复** 修复了 istiod 重启后，所有 `Gateways` 均被重启的问题。
  ([Issue #59709](https://github.com/istio/istio/issues/59709))

- **修复** 修复了 `TLSRoute` 的主机名未被限制为与 `Gateway`
  监听器主机名的交集这一问题。此前，当一个具有宽泛主机名（例如 `*.com`）的
  `TLSRoute` 绑定到一个具有较窄主机名（例如 `*.example.com`）的监听器上时，
  系统会错误地匹配该路由的完整主机名，而非仅匹配其交集（即 `*.example.com`），
  这与 Gateway API 规范的要求相悖。
  ([Issue #59229](https://github.com/istio/istio/issues/59229))

- **修复** 修复了 JWKS URI 的 CIDR 阻断问题：
  通过在自定义的 `DialContext` 中使用自定义控制函数来实现。
  该控制函数会在 DNS 解析完成后、实际发起连接（dialing）之前对连接进行过滤，
  从而确保阻断策略能够跟随重定向及签发者（issuer）的发现路径。
  此外，此方案还保留了默认 `DialContext` 中的各项特性，
  例如“Happy Eyeballs”机制以及 `dialSerial`（按顺序逐一尝试已解析的 IP 地址）功能。

- **修复** 修复了一个在 `DestinationRule` 中 `retryBudget`
  的默认 `percent` 值被错误地设置为 0.2% 的问题，而非预期的 20%。
  ([Issue #59504](https://github.com/istio/istio/issues/59504))

- **修复** 修复了一个问题，当目标服务（Destination）包含定义了独立 `trafficPolicy` 的子集（Subset）时，
  在 `DestinationRule` 的顶层 `trafficPolicy`
  中设置的 `retryBudget` 会被静默丢弃；此外，在子集层级定义的 `retryBudget` 也同样会被忽略。
  ([Issue #59667](https://github.com/istio/istio/issues/59667))

- **修复** 修复了针对通过 HTTP 获取的经 `gzip` 解压后的 WASM 二进制文件，
  修复了缺失大小限制的问题，使其与已应用于其他获取路径的限制保持一致。

- **修复** 修复了一个问题：在使用支持 `.Release.IsUpgrade`
  的工具（如 Helm 4 和 Flux）执行 `helm upgrade` 并启用服务器端应用（SSA）时，
  `ValidatingWebhookConfiguration` 资源上出现的字段管理器冲突。
  现在，在执行升级操作时，Webhook 模板中将省略 `failurePolicy` 字段，
  从而保留 Webhook 控制器在运行时设置的实际值。
  对于那些结合 SSA 使用 `helm template` 的工具，
  请将配置项 `base.validationFailurePolicy` 设置为 `Fail`，以避免此类冲突。

- **修复** 修复了 istiod webhook HTTPS 服务器（端口 15017）缺失
  `ReadHeaderTimeout` 和 `IdleTimeout` 的问题，
  使其与 HTTP 服务器（端口 8080）现有的超时设置保持一致。

- **修复** 修复了一个导致间歇性出现 `"proxy::h2 ping error: broken pipe"` 错误日志的竞态条件。
  ([Issue #59192](https://github.com/istio/istio/issues/59192))
  ([Issue #1346](https://github.com/istio/ztunnel/issues/1346))
