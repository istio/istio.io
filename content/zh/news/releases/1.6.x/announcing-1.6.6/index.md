---
title: 发布 Istio 1.6.6
linktitle: 1.6.6
subtitle: 补丁更新
description: Istio 1.6.6 补丁更新.
publishdate: 2020-07-29
release: 1.6.6
aliases:
    - /news/announcing-1.6.6
---

{{< warning >}}
此版本包含与 1.6.5 相比引入的回归，会导致未关联到 Pod 的端点无法工作。请在 1.6.7 可用时升级。
{{< /warning >}}

此版本包含修复错误以提高健壮性。这些发布说明描述了 Istio 1.6.5 和 Istio 1.6.6 之间的差异。

{{< relnote >}}

## 变更

- **优化** 在拥有大量网关的情况下的性能。([Issue 25116](https://github.com/istio/istio/issues/25116))
- **修复** 事件乱序可能导致 Istiod 更新队列卡住的问题。这会导致代理配置过期。
- **修复** `istioctl upgrade`，使其在使用 `--dry-run` 时不再检查远程组件版本。 ([Issue 24865](https://github.com/istio/istio/issues/24865))
- **修复** 具有许多网关的群集的长日志消息。
- **修复** 离群值检测仅对用户配置的错误触发，并且不依赖成功率。([Issue 25220](https://github.com/istio/istio/issues/25220))
- **修复** 演示配置文件，以使用端口 15021 作为状态端口。 ([Issue #25626](https://github.com/istio/istio/issues/25626))
- **修复** Galley 处理来自 Kubernetes 坟墓的错误。
- **修复** 手动启用一个 sidecar 与出站网关之间的通信的 TLS/mTLS 不起作用的问题。([Issue 23910](https://github.com/istio/istio/issues/23910))
- **修复** Bookinfo 演示应用程序验证指定的名称空间是否存在，如果不存在，则使用默认名称空间。
- **添加** `pilot_xds` 指标标签，以提供有关数据平面版本的更多信息，而无需抓取数据平面。
- **添加** `CA_ADDR` 字段，以便在出站网关配置中配置证书颁发机构地址，并修复了 `istio-certs` 挂载密钥名称。
- **更新** Bookinfo 演示应用程序到最新版本的库。
- **更新** Istio，禁用自动 mTLS，当发送流量到没有 sidecar 的 headless 服务时。