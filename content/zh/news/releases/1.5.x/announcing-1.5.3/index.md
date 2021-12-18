---
title: Istio 1.5.3 发布公告
linktitle: 1.5.3
subtitle: 补丁发布
description: Istio 1.5.3 安全补丁发布。
publishdate: 2020-05-12
release: 1.5.3
aliases:
    - /zh/news/announcing-1.5.3
---

{{< warning >}}
请勿使用此版本。请使用 Istio 1.5.4 版本代替。
{{< /warning >}}

由于发布的版本错误问题导致了 Istio 1.5.3 版本内的镜像不包含原公告中声明的 CVE-2020-10739 问题修复。

此版本包含 bug 修复以及提高系统健壮性和用户体验。
这个版本说明描述了 Istio 1.5.3 和 Istio 1.5.2 之间的不同之处。

{{< relnote >}}

## 改变{#changes}

- **修复** 修复了 Helm 安装程序安装 Kiali 时使用动态签名密钥的问题。
- **修复** 修复了使用用户自定义的资源去覆盖系统为插件组件生成的 Kubernetes 资源的问题。
 [(Issue 23048)](https://github.com/istio/istio/issues/23048)
- **修复** 修复了 `istio-sidecar.deb` 在使用 `iptables` 默认 `nftables` 设置时无法启动 Debian buster 的问题。 [(Issue 23279)](https://github.com/istio/istio/issues/23279)
- **修复** 修复了在 `DestinationRule.trafficPolicy.loadBalancer.consistentHash.httpHeaderName` 中指定的表头名称被更改后，相应的哈希策略不会被更新的问题。 [(Issue 23434)](https://github.com/istio/istio/issues/23434)
- **修复** 修复了在部署在 istio-system 以外的命名空间中的流量路由的问题。 [(Issue 23401)](https://github.com/istio/istio/issues/23401)
