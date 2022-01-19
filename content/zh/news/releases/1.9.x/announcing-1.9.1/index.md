---
title: 发布 Istio 1.9.1 公告
linktitle: 1.9.1
subtitle: 补丁发布
description: Istio 1.9.1 补丁发布。
publishdate: 2021-03-01
release: 1.9.1
aliases:
    - /zh/news/announcing-1.9.1
---

此版本修复了我们在 [2021 年 3 月 1 日的新闻文章](/zh/news/security/istio-security-2021-001)中描述的安全漏洞，
并修复了一些错误以提高系统的稳健性。

本发布说明描述了 Istio 1.9.0 和 Istio 1.9.1 之间的区别。

{{< tip >}}
此版本的资格测试已于 2021 年 3 月 3 日成功完成。
{{< /tip >}}

{{< relnote >}}

## 安全更新{#security-update}

Istio 1.9.0 附带的 Envoy 版本中修复了一个[零时差安全漏洞](https://groups.google.com/g/envoy-security-announce/c/Hp16L27L00Q)。此漏洞已于 2021 年 2 月 26 日修复。1.9.0 是唯一包含易受攻击 Envoy 版本的 Istio 版本。此漏洞只能在配置错误的系统上被利用。

## 改变{#changes}

- **改进** 改进了 sidecar 注入，以自动指定 `kubectl.kubernetes.io/default-logs-container`，这确保 `kubectl logs`
  默认读取应用程序容器的日志，而不需要显式地设置容器。
  ([Issue #26764](https://github.com/istio/istio/issues/26764))

- **改进** 改进了 sidecar 注入器，以更好地利用 Pod 标签来确定是否需要注入。此版本默认未启用此功能，
  但可以使用 `--set values.sidecarInjectorWebhook.useLegacySelectors=false` 进行测试。  ([Issue #30013](https://github.com/istio/istio/issues/30013))

- **更新** 更新了 Prometheus 指标，默认情况下包括所有场景的 `source_cluster` 和 `destination_cluster` 标签。以前，这只适用于多集群场景。
  ([Issue #30036](https://github.com/istio/istio/issues/30036))

- **更新** 更新了默认的访问日志，包括 `RESPONSE_CODE_DETAILS` 和 `CONNECTION_TERMINATION_DETAILS`。
  ([Issue #27903](https://github.com/istio/istio/issues/27903))

- **更新** 将 Kiali 插件更新到最新的 `v1.29` 版本。
  ([Issue #30438](https://github.com/istio/istio/issues/30438))

- **新增**  新增 `enableIstioConfigCRDs` 到 `base` 中，以允许用户指定是否安装 Istio CRD。  ([Issue #28346](https://github.com/istio/istio/issues/28346))

- **新增** 支持对网格/命名空间级规则的 `DestinationRule` 继承。使用环境变量 `PILOT_ENABLE_DESTINATION_RULE_INHERITANCE` 启用该特性。
  ([Issue #29525](https://github.com/istio/istio/issues/29525))

- **新增** 通过 `Sidecar` API 增加了对应用程序绑定到它们的 Pod IP 地址的支持，而不是通配符或本地主机地址。
  ([Issue #28178](https://github.com/istio/istio/issues/28178))

- **新增** 在 `istio-iptables` 脚本中新增了 DNS 流量捕获标志。
  ([Issue #29908](https://github.com/istio/istio/issues/29908))

- **新增** 向 Envoy 生成的跟踪范围中增加了规范的服务标签。
  ([Issue #28801](https://github.com/istio/istio/issues/28801))

- **修复** 修复了导致 `x-envoy-upstream-rq-timeout-ms` 超时报头不被执行的问题。
  ([Issue #30885](https://github.com/istio/istio/issues/30885))

- **修复** 修复了访问日志服务导致 Istio 代理拒绝配置的问题。
  ([Issue #30939](https://github.com/istio/istio/issues/30939))

- **修复** 修复了 Docker 镜像中包含另一个 Envoy 二进制文件的问题。二进制文件在功能上是等价的。
  ([Issue #31038](https://github.com/istio/istio/issues/31038))

- **修复** 修复了仅在 HTTP 端口上强制执行 TLS v2 版本的问题。此选项现在适用于所有端口。
- **修复** 修复了 Wasm 插件配置更新会导致请求失败的问题。
  ([Issue #29843](https://github.com/istio/istio/issues/29843))

- **移除** 移除了对通过 Mesh Configuration Protocol（MCP）读取 Istio 配置的支持。
  ([Issue #28634](https://github.com/istio/istio/issues/28634))
