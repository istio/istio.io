---
title: Istio 1.1.3 发布公告
linktitle: 1.1.3
subtitle: 补丁发布
description: Istio 1.1.3 补丁发布。
publishdate: 2019-04-15
release: 1.1.3
aliases:
    - /zh/about/notes/1.1.3
    - /zh/blog/2019/announcing-1.1.3
    - /zh/news/2019/announcing-1.1.3
    - /zh/news/announcing-1.1.3
---

我们很高兴的宣布 Istio 1.1.3 发布，下面介绍相关更新信息。

{{< relnote >}}

## 1.1.3 版本已知问题{#known-issues-with-1-1-3}

- 在启用了 alpha-quality SDS 证书轮换功能的集群中，存在[节点代理恐慌](https://github.com/istio/istio/issues/13325)问题。
由于这是我们首次将 SDS 证书轮换纳入长期运行的测试版本，因此我们不知道这是潜在的错误还是新的回归。
考虑到 SDS 证书轮换为 alpha 版本，我们决定带着这个问题发布 1.1.3 版本，在 1.1.4 版本中我们将解决此问题。

## Bug 修复{#bug-fixes}

- 删除了 Istio 1.1.2 对 Envoy 某个补丁的反向移植，该补丁用于修复 [`CVE-2019-9900`](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-9900) 和 [`CVE-2019-9901`](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-9901)。以便更新包含了最终版本补丁的 Envoy。

- 修复分割水平 `EDS` 的负载均衡权重设置。

- 修复 Envoy 默认日志格式中的错字。（[Issue 12232](https://github.com/istio/istio/issues/12232)）

- 在配置更改时正确地重新加载进程外适配器地址。（[Issue 12488](https://github.com/istio/istio/issues/12488)）

- 恢复意外删除的 Kiali 设置。（[Issue 3660](https://github.com/istio/istio/issues/3660)）

- 修复当具有相同目标端口的服务存在时导致的重复入站侦听问题。（[Issue 9504](https://github.com/istio/istio/issues/9504)）

- 通过自动绑定到 `Sidecar` 侦听器的服务，解决为 `istio-system` 以外命名空间配置 `Sidecar` `egress` 端口的问题，从而生成 `BlackHoleCluster` 的 `envoy.tcp_proxy` 过滤器。（[Issue 12536](https://github.com/istio/istio/issues/12536)）

- 通过支持更准确的主机匹配来修正网关 `vhost` 配置生成问题。（[Issue 12655](https://github.com/istio/istio/issues/12655)）

- 修复 `ALLOW_ANY`，如果端口上已经存在 http 服务，现在允许外部流量。

- 修复验证逻辑，现在 `port.name` 不再是有效的 `PortSelection`。

- 修复 [`istioctl proxy-config cluster`](/zh/docs/reference/commands/istioctl/#istioctl-proxy-config-cluster) 命令输出结果中集群类型列的渲染问题。（[Issue 12455](https://github.com/istio/istio/issues/12455)）

- 修复 SDS secret 的挂载配置。

- 修复 Helm chart 中错误的 Istio 版本。

- 修复当存在重叠端口时出现的 DNS 故障。（[Issue 11658](https://github.com/istio/istio/issues/11658)）

- 修复 Helm `podAntiAffinity` 模板错误。（[Issue 12790](https://github.com/istio/istio/issues/12790)）

- 修复源目标服务发现不使用源目标负载均衡器的问题。

- 修复当存在无效或丢失密钥时出现的 SDS 内存泄漏问题。（[Issue 13197](https://github.com/istio/istio/issues/13197)）

## 小的增强{#small-enhancements}

- 从 `PushContext` 日志中隐藏 `ServiceAccounts` 以缩小日志。

- 通过 `values.yaml` 的 `localityLbSetting` 字段配置网格。

- 从 Helm 图表中删除即将弃用的 `critical-pod` 注释。（[Issue 12650](https://github.com/istio/istio/issues/12650)）

- 支持 Pod 反亲和性注释以提高控制平面的可用性。（[Issue 11333](https://github.com/istio/istio/issues/11333)）

- 访问日志中优化 `IP` 地址打印。

- 删除冗余的 write header，以进一步减小日志。

- 改进 Pilot 的目标主机验证。

- 显式的配置 `istio-init` 以 root 身份运行，以免使用 Pod-level 的 `securityContext.runAsUser` 破坏它。（[Issue 5453](https://github.com/istio/istio/issues/5453)）

- 添加用于 Vault 集成的配置示例。

- 从 `ServiceEntry` 执行局部负载均衡权重。

- 使由 Pilot Agent 监视的 TLS 证书位置可配置。（[Issue 11984](https://github.com/istio/istio/issues/11984)）

- 添加对 Datadog 追踪的支持。

- 为 `istioctl` 添加别名，可以使用 "x" 代替 "experimental"。

- 通过在 CSR 请求中添加抖动来提供改进的 Sidecar certificate。

- 允许配置权重负载均衡注册表的位置。

- 为内置的 Mixer 适配器添加对标准 CRD 的支持。

- 减少用于演示配置的 Pilot 的资源需求。

- 通过添加数据源完全填充 Galley 仪表盘。（[Issue 13040](https://github.com/istio/istio/issues/13040)）

- 将 Istio 1.1 `sidecar` 的性能调整覆盖到 `istio-gateway`。

- 通过拒绝 `*` 主机来改善目标主机的验证。（[Issue 12794](https://github.com/istio/istio/issues/12794)）

- 在集群定义中暴露上游的 `idle_timeout`，以便可以在使用前从连接池中删除死连接。（[Issue 9113](https://github.com/istio/istio/issues/9113)）

- 注册 `Sidecar` 资源以限制 Pod 可以看到的内容时，如果规范包含一个 `workloadSelector`，这些限制将被应用。（[Issue 11818](https://github.com/istio/istio/issues/11818)）

- 更新 Bookinfo 示例以使端口 80 用于 TLS 源。

- 为 Citadel 添加存活探针。

- 通过将 15020 设置为 `ingressgateway` 服务中列出的第一个端口来提高 AWS ELB 的互操作性。（[Issue 12502](https://github.com/istio/istio/issues/12503)）

- 对故障转移模式使用异常值检测，但不用于局部加权负载均衡的分布模式。（[Issues 12965](https://github.com/istio/istio/issues/12961)）

- 对于 Istio 1.1.0+ Sidecar，使用 `filter_enabled` 字段取代 `CorsPolicy` 中的 `enabled` 字段。

- 标准化 Mixer Helm chart 上的标签.
