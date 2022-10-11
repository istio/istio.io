---
title: 发布 Istio 1.14.2
linktitle: 1.14.2
subtitle: 补丁发布
description: Istio 1.14.2 补丁发布。
publishdate: 2022-07-25
release: 1.14.2
---

{{< warning >}}
Istio 1.14.2 不包含对 [CVE-2022-31045](/zh/news/security/istio-security-2022-005/#cve-2022-31045) 的修复。
我们建议用户暂时不要安装 Istio 1.14.2，而是使用 Istio 1.14.1。
Istio 1.14.3 将于本周晚些时候发布。
{{< /warning >}}

此版本包含 bug 修复，以提高稳健性和一些额外的支持。
本发行说明描述了 Istio 1.14.1 和 Istio 1.14.2 之间的不同之处。

仅供参考，[Go 1.18.4 已经发布](https://groups.google.com/g/golang-announce/c/nqrv9fbR0zE)，
其中包括 9 个安全补丁。如果您在本地使用 Go，我们建议您升级到这个较新的 Go 版本。

{{< relnote >}}

## 变化{#changes}

- **新增** 新增了 `istioctl experimental envoy-stats -o prom-merged` 用于从 Prometheus 检索 `istio-proxy` 合并的指标。
  ([Issue #39454](https://github.com/istio/istio/issues/39454))

- **新增** 通过使用新的 `HorizontalPodAutoscaler` 和 `PodDisruptionBudget` API 版本支持 Kubernetes 1.25。

- **新增** 新增了读取 `kubernetes.io/tls` 类型的 `cacerts` 密钥的能力。
  ([Issue #38528](https://github.com/istio/istio/issues/38528))

- **修复** 修复了当更新一个多集群密钥时，前一个集群不会被停止的问题。即使删除密钥也不会停止前一个集群的问题。  ([Issue #39366](https://github.com/istio/istio/issues/39366))

- **修复** 修复了在没有 `Lb` 策略的情况下，指定 `warmupDuration` 不会配置预热持续时间的问题。  ([Issue #39430](https://github.com/istio/istio/issues/39430))

- **修复** 修复了在发送访问日志到注入 `OTel-collector` 的 Pod 时抛出 `http2.invalid.header.field` 的错误。  ([Issue #39196](https://github.com/istio/istio/issues/39196))

- **修复** 修复了当 `PILOT_SEND_UNHEALTHY_ENDPOINTS` 被启用时，Istio 向未准备好的 pod 发送流量的问题。
  ([Issue #39825](https://github.com/istio/istio/issues/39825))

- **修复** 修复了导致服务合并时只考虑第一个和最后一个服务，而不是所有服务的问题。

- **修复** 修复了 `ProxyConfig` 类型的镜像不生效的问题。
  ([Issue #38959](https://github.com/istio/istio/issues/38959))
