---
title: Envoy 的统计信息
description: 精细化控制 Envoy 的统计信息。
weight: 10
aliases:
  - /zh/help/ops/telemetry/envoy-stats
  - /zh/docs/ops/telemetry/envoy-stats
owner: istio/wg-policies-and-telemetry-maintainers
test: no
---

Envoy 代理收集了关于网络流量的详细统计信息。

Envoy 的统计信息只覆盖了特定 Envoy 实例的流量。参考[可观测性](/zh/docs/tasks/observability/)
了解关于服务级别的 Istio 遥测方面的内容。这些由 Envoy 代理产生的统计数据记录能够提供更多关于 Pod 实例的具体信息。

查看某个 Pod 的统计信息：

{{< text bash >}}
$ kubectl exec $POD -c istio-proxy -- pilot-agent request GET stats
{{< /text >}}

Envoy 会生成与 Pod 行为相关的统计数据，并通过代理函数来限定统计范围。参考示例包括：

- [上游连接](https://www.envoyproxy.io/docs/envoy/latest/configuration/upstream/cluster_manager/cluster_stats)
- [监听器](https://www.envoyproxy.io/docs/envoy/latest/configuration/listeners/stats)
- [HTTP 连接管理器](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_conn_man/stats)
- [TCP 代理](https://www.envoyproxy.io/docs/envoy/latest/configuration/listeners/network_filters/tcp_proxy_filter#statistics)
- [路由](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_filters/router_filter.html?highlight=vhost#statistics)

Istio 默认配置下 Envoy 只会记录最小化的统计信息，以减少代理服务器的整体 CPU 和内存占用情况。缺省的关键词集合有：

- `cluster_manager`
- `listener_manager`
- `server`
- `cluster.xds-grpc`
- `wasm`

要查看关于统计数据收集的 Envoy 配置，可以使用
[`istioctl proxy-config bootstrap`](/zh/docs/reference/commands/istioctl/#istioctl-proxy-config-bootstrap) 命令，还可以参考
[深入研究 Envoy 配置](/zh/docs/ops/diagnostic-tools/proxy-cmd/#deep-dive-into-envoy-configuration)。
Envoy 只收集在 `stats_matcher` JSON 字段中能匹配上 `inclusion_list` 的统计数据。

{{< tip >}}
注意：Envoy 统计数据的名称由组成 Envoy 的不同配置而导致其拥有不同的名称。因此，由 Istio 管理的 Envoy 的统计数据暴露的名称会受到 Istio 配置行为的影响。
如果您基于 Envoy 建立或者维护仪表盘或者告警，**强烈建议**您在**升级 Istio 之前**先在[金丝雀环境](/zh/docs/setup/upgrade/canary/index.md)检查统计信息。
{{< /tip >}}

想让 Istio 代理能够记录更多的统计信息，您可以在您的网格配置中添加 [`ProxyConfig.ProxyStatsMatcher`](/zh/docs/reference/config/istio.mesh.v1alpha1/#ProxyStatsMatcher)。例如，为了启用断路器、重试、全局上游连接的统计数据，你可以指定如下的数据统计的匹配配置：

{{< tip >}}
为了能加载数据统计的匹配配置，代理需要重新启动。
{{< /tip >}}

{{< text yaml >}}
proxyStatsMatcher:
  inclusionRegexps:
    - ".*circuit_breakers.*"
  inclusionPrefixes:
    - "upstream_rq_retry"
    - "upstream_cx"
{{< /text >}}

你也可以通过使用 `proxy.istio.io/config` 注解覆盖全局的数据统计匹配配置。例如，为了配置生成与上面相同的统计数据，你可以在一个 Gateway 代理或者一个工作负载上添加下面的注解：

{{< text yaml >}}
proxy.istio.io/config: |-
  proxyStatsMatcher:
    inclusionRegexps:
    - ".*circuit_breakers.*"
    inclusionPrefixes:
    - "upstream_rq_retry"
    - "upstream_cx"
{{< /text >}}

{{< tip >}}
注意：如果您使用 `sidecar.istio.io/statsInclusionPrefixes`，`sidecar.istio.io/statsInclusionRegexps` 和 `sidecar.istio.io/statsInclusionSuffixes`，考虑需要切换到基于 `ProxyConfig` 配置，因此它提供了一个全局默认并且统一的方法去重载 Gateway 和 Sidecar 代理。
{{< /tip >}}
