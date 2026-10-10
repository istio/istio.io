---
title: Envoy 的统计信息
description: 精细化控制 Envoy 的统计信息。
weight: 10
aliases:
  - /zh/help/ops/telemetry/envoy-stats
  - /zh/docs/ops/telemetry/envoy-stats
owner: istio/wg-policies-and-telemetry-maintainers
test: yes
---

Envoy 代理收集了关于网络流量的详细统计信息。

Envoy 的统计信息只覆盖了特定 Envoy 实例的流量。参考[可观测性](/zh/docs/tasks/observability/)
了解关于服务级别的 Istio 遥测方面的内容。这些由 Envoy 代理产生的统计数据记录能够提供更多关
Pod 实例的具体信息。

查看某个 Pod 的统计信息：

{{< text syntax=bash snip_id=get_stats >}}
$ kubectl exec "$POD" -c istio-proxy -- pilot-agent request GET stats
{{< /text >}}

Envoy 会生成与 Pod 行为相关的统计数据，并通过代理函数来限定统计范围。
参考示例包括：

- [上游连接](https://www.envoyproxy.io/docs/envoy/latest/configuration/upstream/cluster_manager/cluster_stats)
- [监听器](https://www.envoyproxy.io/docs/envoy/latest/configuration/listeners/stats)
- [HTTP 连接管理器](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_conn_man/stats)
- [TCP 代理](https://www.envoyproxy.io/docs/envoy/latest/configuration/listeners/network_filters/tcp_proxy_filter#statistics)
- [路由](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_filters/router_filter.html?highlight=vhost#statistics)

Istio 默认配置下 Envoy 只会记录最小化的统计信息，
以减少代理服务器的整体 CPU 和内存占用情况。缺省的关键词集合有：

- `cluster_manager`
- `listener_manager`
- `server`
- `cluster.xds-grpc`

要查看关于统计数据收集的 Envoy 配置，可以使用
[`istioctl proxy-config bootstrap`](/zh/docs/reference/commands/istioctl/#istioctl-proxy-config-bootstrap)
命令，还可以参考[深入研究 Envoy 配置](/zh/docs/ops/diagnostic-tools/proxy-cmd/#deep-dive-into-envoy-configuration)。
Envoy 只收集在 `stats_matcher` JSON 字段中能匹配上 `inclusion_list` 的统计数据。

{{< tip >}}
注意：Envoy 统计数据的名称由组成 Envoy 的不同配置而导致其拥有不同的名称。因此，
由 Istio 管理的 Envoy 的统计数据暴露的名称会受到 Istio 配置行为的影响。
如果您基于 Envoy 建立或者维护仪表盘或者告警，**强烈建议**您在**升级 Istio
之前**先在[金丝雀环境](/zh/docs/setup/upgrade/canary/index.md)检查统计信息。
关于这些名称的构成方式，请参阅 [Istio 对 Envoy 资源的命名](#istio-naming-of-envoy-resources)。
{{< /tip >}}

想让 Istio 代理能够记录更多的统计信息，您可以在您的网格配置中添加
[`ProxyConfig.ProxyStatsMatcher`](/zh/docs/reference/config/istio.mesh.v1alpha1/#ProxyStatsMatcher)。
例如，为了全局启用断路器、请求重试、上游连接和请求超时的统计数据，
您可以指定如下的数据统计的匹配配置：

{{< tip >}}
为了能加载数据统计的匹配配置，代理需要重新启动。
{{< /tip >}}

{{< text syntax=yaml snip_id=proxyStatsMatcher >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    defaultConfig:
      proxyStatsMatcher:
        inclusionRegexps:
          - ".*outlier_detection.*"
          - ".*upstream_rq_retry.*"
          - ".*upstream_cx_.*"
        inclusionSuffixes:
          - "upstream_rq_timeout"
{{< /text >}}

通过使用每个代理的 `proxy.istio.io/config` 注解，您也可以重载全局数据统计对应的配置。
例如，为了生成上述相同的统计数据，您可以在一个 Gateway 代理或者工作负载上添加以下注解：

{{< text syntax=yaml snip_id=proxyIstioConfig >}}
metadata:
  annotations:
    proxy.istio.io/config: |-
      proxyStatsMatcher:
        inclusionRegexps:
        - ".*outlier_detection.*"
        - ".*upstream_rq_retry.*"
        - ".*upstream_cx_.*"
        inclusionSuffixes:
        - "upstream_rq_timeout"
{{< /text >}}

{{< tip >}}
注意：如果您使用 `sidecar.istio.io/statsInclusionPrefixes`、
`sidecar.istio.io/statsInclusionRegexps` 和 `sidecar.istio.io/statsInclusionSuffixes`，
考虑需要切换到基于 `ProxyConfig` 配置，因此它提供了一个全局默认并且统一的方法去重载
Gateway 和 Sidecar 代理。
{{< /tip >}}

## Istio 对 Envoy 资源的命名 {#istio-naming-of-envoy-resources}

Envoy 按其所属的集群、连接管理器或侦听器地址来确定大多数统计信息的范围。
Istio 在将网格配置转换为 Envoy 配置时生成集群和连接管理器名称，
因此它们也出现在统计名称、Prometheus 标签和访问日志中。

{{< warning >}}
下面的名称描述了 Istio 当前的行为。它们不是稳定的 API，可能会在版本之间发生变化。
升级之前检查 Canary 环境中的统计信息。要使集群统计信息独立于这些名称，
请[自定义集群统计信息名称](#customize-cluster-stat-names)。
{{< /warning >}}

这些名称适用于 Sidecar 代理和网关。Ambient 模式下的 waypoint 代理使用不同的集群名称，
并且 ztunnel 不使用 Envoy。

| 资源 | 名称格式 | 示例 |
|----------|-------------|---------|
| 出站集群 | `outbound\|<port>\|<subset>\|<service FQDN>` | `outbound\|9080\|v1\|reviews.default.svc.cluster.local` |
| 入站集群 | `inbound\|<target port>\|\|` | `inbound\|9080\|\|` |
| 出站 TLS 服务器名称（SNI） | `outbound_.<port>_.<subset>_.<service FQDN>` | `outbound_.9080_._.reviews.default.svc.cluster.local` |
| 全部集群 | `PassthroughCluster`, `BlackHoleCluster`, `InboundPassthroughCluster` | `PassthroughCluster` |
| 代理引导集群 | `xds-grpc`, `sds-grpc`, `prometheus_stats`, `agent` | `xds-grpc` |
| 出站 HTTP 连接管理器 | `outbound_<bind address>_<port>` | `outbound_0.0.0.0_9080` |
| 入站 HTTP 连接管理器 | `inbound_<bind address>_<target port>` | `inbound_0.0.0.0_9080` |
| TCP 代理 | 目标集群统计名称，或加权路由的 `VirtualService` 的 `<name>.<namespace>` | `outbound\|3306\|\|mysql.default.svc.cluster.local` |

当没有 [`DestinationRule`](/zh/docs/reference/config/networking/destination-rule/) 子集适用时，
出站集群名称的子集段为空，例如 `outbound|9080||reviews.default.svc.cluster.local`。
当代理首次向其发送流量时，Envoy 会创建集群的流量统计信息，例如 `upstream_rq_total`，
因此对于尚未接收流量的集群，这些统计信息会丢失。要列出代理的集群和监听器，
请参阅[调试 Envoy 和 istiod](/zh/docs/ops/diagnostic-tools/proxy-cmd/#deep-dive-into-envoy-configuration)。

Istio 在统计中使用的大多数集群和 HTTP 连接管理器名称都以 `;` 分隔符结尾，例如：

{{< text syntax=plain snip_id=none >}}
cluster.outbound|9080||reviews.default.svc.cluster.local;.upstream_rq_total
http.outbound_0.0.0.0_9080;.downstream_rq_total
{{< /text >}}

代理引导配置将这些名称提取到标签中，这些标签成为 Envoy Prometheus 输出中的标签。
例如，`envoy_cluster_upstream_rq_total` 有一个 `cluster_name` 标签，
其值为 `outbound|9080||reviews.default.svc.cluster.local`。最常用的标签是：

- `cluster_name`：集群名称。
- `http_conn_manager_prefix`：HTTP 连接管理器名称。
- `tcp_prefix`：TCP 代理名称。
- `response_code` 和 `response_code_class`：HTTP 响应码，例如 `200` 或 `2xx`。
- `listener_address`：监听器的地址，例如 `0.0.0.0_15006`。

要查看标签的完整列表以及提取它们的表达式，
请查看 [`istioctl proxy-config bootstrap`](/zh/docs/reference/commands/istioctl/#istioctl-proxy-config-bootstrap)
输出中的 `stats_config` 元素。

## 自定义集群统计信息名称 {#customize-cluster-stat-names}

[`inboundClusterStatName`](/zh/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig-inbound_cluster_stat_name)
和 [`outboundClusterStatName`](/zh/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig-outbound_cluster_stat_name)
网格配置选项将统计信息中的集群名称替换为您控制的模式。集群本身的名称不会更改，
因此路由和 `istioctl proxy-config` 输出不会受到影响。该模式可以使用以下变量：

| 变量 | 值 |
|----------|-------|
| `%SERVICE%` | 服务的 `<name>.<namespace>`，否则为完整主机名 |
| `%SERVICE_NAME%` | Kubernetes 服务的 `<name>`，否则为完整主机名 |
| `%SERVICE_FQDN%` | 服务的完整主机名，例如 `reviews.default.svc.cluster.local` |
| `%SERVICE_PORT%` | 服务端口 |
| `%SERVICE_PORT_NAME%` | 服务端口名称 |
| `%TARGET_PORT%` | 工作负载的目标端口。仅在 `inboundClusterStatName` 集群名称中有意义 |
| `%SUBSET_NAME%` | `DestinationRule` 子集名称。仅适用于 `outboundClusterStatName` |

Istio 将 `;` 分隔符附加到结果中，因此 `cluster_name` 标签继续工作。
相同的模式还命名 TCP 代理的统计信息，不带分隔符。他们不会更改访问日志中的集群名称。

如果模式省略 `%SUBSET_NAME%`，则服务的所有子集的集群共享相同的统计信息。
例如，要在服务和端口之后命名出站集群统计信息：

{{< text syntax=yaml snip_id=outboundClusterStatName >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    outboundClusterStatName: "%SERVICE%_%SERVICE_PORT%"
{{< /text >}}

通过此设置，对 `default` 命名空间中端口 `8000` 上的 `httpbin`
服务的请求统计信息以 `cluster.httpbin.default_8000;` 开头，
而不是 `cluster.outbound|8000||httpbin.default.svc.cluster.local;`。
