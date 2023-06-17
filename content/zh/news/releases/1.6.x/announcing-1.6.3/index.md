---
title: 发布 Istio 1.6.3
linktitle: 1.6.3
subtitle: 补丁更新
description: Istio 1.6.3 补丁更新。
publishdate: 2020-06-18
release: 1.6.3
aliases:
    - /news/announcing-1.6.3
---

本次发布包含了修复错误以提高健壮性的 Bug 修复。此版本说明介绍了 Istio 1.6.2 和 Istio 1.6.3 之间的差异。

{{< relnote >}}

## 变更

- **修复** 了一个问题，如果已删除，则会防止操作员重新创建监视资源 ([Issue 23238](https://github.com/istio/istio/issues/23238))。
- **修复** 了一个问题，Istio 崩溃并显示消息：`proto.Message is *client.QuotaSpecBinding, not *client.QuotaSpecBinding`([Issue 24624](https://github.com/istio/istio/issues/24264))。
- **修复** 了一个问题，由于观察到的资源上的不正确标签而阻止操作员协调 ([Issue 23603](https://github.com/istio/istio/issues/23603))。
- **添加** 对 `k8s.v1.cni.cncf.io/networks` 注释的支持 ([Issue 24425](https://github.com/istio/istio/issues/24425))。
- **更新** `SidecarInjectionSpec` CRD 以从 `.Values.global` 读取 `imagePullSecret` ([Pull 24365](https://github.com/istio/istio/pull/24365))。
- **更新** 分裂视野以跳过解析主机名的网关。
- **修复** 了 `istioctl experimental metrics` 将仅将错误响应代码标记为错误 ([Issue 24322](https://github.com/istio/istio/issues/24322))。
- **更新** 了 `istioctl analyze` 以对输出格式进行排序。
- **更新** 网关使用 `proxyMetadata`
- **更新** Prometheus sidecar 使用 `proxyMetadata`([Issue 24415](https://github.com/istio/istio/pull/24415))。
- **移除** 在启用 `gateway.runAsRoot` 时**从 `PodSecurityContext` 中删除无效配置 ([Issue 24469](https://github.com/istio/istio/issues/24469))。

## Grafana 插件的安全修复

我们已将 Istio 附带的 Grafana 版本从 6.5.2 更新到 6.7.4。这个版本解决了一个被评为高危的 Grafana 安全问题，可以通过 Grafana 头像功能访问内部集群资源。
[(CVE-2020-13379)](https://grafana.com/blog/2020/06/03/grafana-6.7.4-and-7.0.2-released-with-important-security-fix/)