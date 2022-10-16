---
title: 发布 Istio 1.8.3 版本
linktitle: 1.8.3
subtitle: 补丁发布
description: Istio 1.8.3 补丁发布。
publishdate: 2021-02-08
release: 1.8.3
aliases:
- /news/announcing-1.8.3
---

这个版本包含了错误修复，以提高稳定性。本发布说明了 Istio 1.8.2 和 Istio 1.8.3 之间的不同之处。

{{< relnote >}}

## 安全


Istio 1.8.3 将不会包含之前在 [discuss.istio.io](https://discuss.istio.io/t/upcoming-istio-1-7-8-and-1-8-3-security-release/9593) 上公布的安全修复程序。
目前还没有计划的日期。请放心，这是 Istio 产品安全工作组的首要任务，但由于细节问题，我们无法发布更多信息，延迟的公告可以在 [这里](https://discuss.istio.io/t/istio-1-7-8-and-1-8-3-cve-fixes-delayed/9663) 查看。

## 变更

- **修复** Envoy 中 TLS 初始化期间聚合集群的问题。
  ([Issue #28620](https://github.com/istio/istio/issues/28620))

- **修复** 使用 `Sidecar` `ingress` 配置时，Istio 1.8 导致 1.7 代理配置错误的问题。
  ([Issue #30437](https://github.com/istio/istio/issues/30437))

- **修复** DNS 代理预览生成 DNS 响应时的错误。
  ([Issue #28970](https://github.com/istio/istio/issues/28970))

- **修复** 在 helm 值中 env 设置覆盖 env K8S 设置的错误。
  ([Issue #30079](https://github.com/istio/istio/issues/30079))

- **修复** `istioctl dashboard controlz` 无法转发到 istiod pod 的错误。
  ([Issue #30208](https://github.com/istio/istio/issues/30208))

- **修复** 无法更新使用 `Ingress` 资源创建的 `IngressClass` 状态字段的错误。
  ([Issue #25308](https://github.com/istio/istio/issues/25308))

- **修复** 仅在 HTTP 端口上强制执行 `TLSv2` 版本的问题，现在将应用于所有端口。
  ([PR #30590](https://github.com/istio/istio/pull/30590))

- **修复** 使用 `httpsRedirect` 在 `Gateway` 中时缺少路由的问题。
  ([Issue #27315](https://github.com/istio/istio/issues/27315)),([Issue #27157](https://github.com/istio/istio/issues/27157))
