---
title: Istio 1.1.7 发布公告
linktitle: 1.1.7
subtitle: 补丁发布
description: Istio 1.1.7 补丁发布。
publishdate: 2019-05-17
release: 1.1.7
aliases:
    - /zh/about/notes/1.1.7
    - /zh/blog/2019/announcing-1.1.7
    - /zh/news/2019/announcing-1.1.7
    - /zh/news/announcing-1.1.7
---

我们非常高兴的宣布 Istio 1.1.7 已经可用。请浏览下面的变更说明。

{{< relnote >}}

## 安全更新{#security-update}

该版本修复了 [CVE 2019-12243](/zh/news/security/istio-security-2019-001)。

## Bug 修复{#bug-fixes}

- 修复了在同一秒创建的具有重叠主机的两个网关可能导致 Pilot 无法正确生成路由并导致 Envoy 侦听器在启动时无限期卡死的问题。
- 提高 SDS 节点代理的健壮性：如果 Envoy 发送带有空的 `ResourceNames` 的 SDS 请求，请忽略它并等待下一个请求，而不是关闭连接（[Issue 13853](https://github.com/istio/istio/issues/13853)）。
- 在以前的版本中，如果服务端口名称是 `mysql`，Pilot 会自动将实验性的 `envoy.filters.network.mysql_proxy` 过滤器注入到出站过滤器链中。这是令人惊讶的，并给某些运维人员造成了问题，因此，现在仅当将 `PILOT_ENABLE_MYSQL_FILTER` 环境变量设置为 `1` 时，Pilot 才会自动注入 `envoy.filters.network.mysql_proxy` 过滤器（[Issue 13998](https://github.com/istio/istio/issues/13998)）。
- 解决了错误地为 TCP 禁用 Mixer 策略检查的问题（[Issue 13868](https://github.com/istio/istio/issues/13868)）。

## 小改进{#small-enhancements}

- 新增 `--applicationPorts` 选项到 `ingressgateway` Helm charts。当设置为以逗号分隔的端口列表时，就绪检查将失败，直到所有端口都变为活动状态为止。配置后，流量将不会发送到处于预热状态的 Envoy。
- 将 `ingressgateway` Helm chart 中的内存限制增加到 1GB，并向 SDS 节点代理容器添加资源 `request` 和 `limits` 以支持 HPA 自动缩放。
