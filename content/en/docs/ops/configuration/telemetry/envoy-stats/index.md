---
title: Envoy Statistics
description: Fine-grained control of Envoy statistics.
weight: 10
aliases:
  - /help/ops/telemetry/envoy-stats
  - /docs/ops/telemetry/envoy-stats
owner: istio/wg-policies-and-telemetry-maintainers
test: yes
---

The Envoy proxy keeps detailed statistics about network traffic.

Envoy's statistics only cover the traffic for a particular Envoy instance.  See
[Observability](/docs/tasks/observability/) for persistent per-service Istio telemetry.  The
statistics the Envoy proxies record can provide more information about specific pod instances.

To see the statistics for a pod:

{{< text syntax=bash snip_id=get_stats >}}
$ kubectl exec "$POD" -c istio-proxy -- pilot-agent request GET stats
{{< /text >}}

Envoy generates statistics about its behavior, scoping the statistics by proxy function. Examples include:

- [Upstream connection](https://www.envoyproxy.io/docs/envoy/latest/configuration/upstream/cluster_manager/cluster_stats)
- [Listener](https://www.envoyproxy.io/docs/envoy/latest/configuration/listeners/stats)
- [HTTP Connection Manager](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_conn_man/stats)
- [TCP proxy](https://www.envoyproxy.io/docs/envoy/latest/configuration/listeners/network_filters/tcp_proxy_filter#statistics)
- [Router](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_filters/router_filter.html?highlight=vhost#statistics)

By default, Istio configures Envoy to record a minimal set of statistics to reduce the overall CPU and memory footprint of the installed proxies. The default collection
keys are:

- `cluster_manager`
- `listener_manager`
- `server`
- `cluster.xds-grpc`

To see the Envoy settings for statistics data collection use
[`istioctl proxy-config bootstrap`](/docs/reference/commands/istioctl/#istioctl-proxy-config-bootstrap) and follow the
[deep dive into Envoy configuration](/docs/ops/diagnostic-tools/proxy-cmd/#deep-dive-into-envoy-configuration).
Envoy only collects statistical data on items matching the `inclusion_list` within
the `stats_matcher` JSON element.

{{< tip >}}
Note: The names of Envoy statistics can vary based on the composition of Envoy configuration. As a result, the exposed names of statistics for Envoys managed by Istio are subject to the configuration behavior of Istio.
If you build or maintain dashboards or alerts based on Envoy statistics, it is **strongly recommended** that you examine the
statistics in a canary environment **before upgrading Istio**.
See [Istio naming of Envoy resources](#istio-naming-of-envoy-resources) for how these names are built.
{{< /tip >}}

To configure Istio proxy to record additional statistics, you can add [`ProxyConfig.ProxyStatsMatcher`](/docs/reference/config/istio.mesh.v1alpha1/#ProxyStatsMatcher) to your mesh config. For example, to enable stats for circuit breakers, request retries, upstream connections, and request timeouts globally, you can specify stats matcher as follows:

{{< tip >}}
Proxy needs to restart to pick up the stats matcher configuration.
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

You can also override the global stats matching configuration per proxy by using the `proxy.istio.io/config` annotation. For example, to configure the same stats generation inclusion as above, you can add the annotation to a gateway proxy or a workload as follows:

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
Note: If you are using `sidecar.istio.io/statsInclusionPrefixes`, `sidecar.istio.io/statsInclusionRegexps`, and `sidecar.istio.io/statsInclusionSuffixes`, consider switching to the `ProxyConfig`-based configuration as it provides a global default and a uniform way to override at the gateway and sidecar proxy.
{{< /tip >}}

## Istio naming of Envoy resources

Envoy scopes most statistics by the cluster, connection manager, or listener address they belong to. Istio generates the cluster and connection manager names when it translates the mesh configuration into Envoy configuration, so they also appear in statistic names, Prometheus labels, and access logs.

{{< warning >}}
The names below describe the current behavior of Istio. They are not a stable API and can change between releases. Examine the statistics in a canary environment before you upgrade. To keep cluster statistics independent of these names, [customize the cluster stat names](#customize-cluster-stat-names).
{{< /warning >}}

These names apply to sidecar proxies and gateways. Waypoint proxies in ambient mode use different cluster names, and ztunnel does not use Envoy.

| Resource | Name format | Example |
|----------|-------------|---------|
| Outbound cluster | `outbound\|<port>\|<subset>\|<service FQDN>` | `outbound\|9080\|v1\|reviews.default.svc.cluster.local` |
| Inbound cluster | `inbound\|<target port>\|\|` | `inbound\|9080\|\|` |
| Outbound TLS server name (SNI) | `outbound_.<port>_.<subset>_.<service FQDN>` | `outbound_.9080_._.reviews.default.svc.cluster.local` |
| Catch-all clusters | `PassthroughCluster`, `BlackHoleCluster`, `InboundPassthroughCluster` | `PassthroughCluster` |
| Proxy bootstrap clusters | `xds-grpc`, `sds-grpc`, `prometheus_stats`, `agent` | `xds-grpc` |
| Outbound HTTP connection manager | `outbound_<bind address>_<port>` | `outbound_0.0.0.0_9080` |
| Inbound HTTP connection manager | `inbound_<bind address>_<target port>` | `inbound_0.0.0.0_9080` |
| TCP proxy | the destination cluster stat name, or `<name>.<namespace>` of the `VirtualService` for weighted routes | `outbound\|3306\|\|mysql.default.svc.cluster.local` |

The subset segment of an outbound cluster name is empty when no [`DestinationRule`](/docs/reference/config/networking/destination-rule/) subset applies, for example `outbound|9080||reviews.default.svc.cluster.local`. Envoy creates the traffic statistics of a cluster, such as `upstream_rq_total`, when the proxy first sends traffic to it, so they are missing for clusters that have not received traffic yet. To list the clusters and listeners of a proxy, see [debugging Envoy and Istiod](/docs/ops/diagnostic-tools/proxy-cmd/#deep-dive-into-envoy-configuration).

Istio ends most cluster and HTTP connection manager names used in statistics with a `;` delimiter, for example:

{{< text syntax=plain snip_id=none >}}
cluster.outbound|9080||reviews.default.svc.cluster.local;.upstream_rq_total
http.outbound_0.0.0.0_9080;.downstream_rq_total
{{< /text >}}

The proxy bootstrap configuration extracts these names into tags, which become labels in the Prometheus output of Envoy. For example, `envoy_cluster_upstream_rq_total` has a `cluster_name` label with the value `outbound|9080||reviews.default.svc.cluster.local`. The most commonly used tags are:

- `cluster_name`: the cluster name.
- `http_conn_manager_prefix`: the HTTP connection manager name.
- `tcp_prefix`: the TCP proxy name.
- `response_code` and `response_code_class`: the HTTP response code, such as `200` or `2xx`.
- `listener_address`: the address of the listener, such as `0.0.0.0_15006`.

To see the full list of tags and the expressions that extract them, look at the `stats_config` element in the output of [`istioctl proxy-config bootstrap`](/docs/reference/commands/istioctl/#istioctl-proxy-config-bootstrap).

## Customize cluster stat names

The [`inboundClusterStatName`](/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig-inbound_cluster_stat_name) and [`outboundClusterStatName`](/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig-outbound_cluster_stat_name) mesh config options replace the cluster names in statistics with a pattern that you control. The names of the clusters themselves do not change, so routing and `istioctl proxy-config` output are not affected. The pattern can use the following variables:

| Variable | Value |
|----------|-------|
| `%SERVICE%` | `<name>.<namespace>` for Kubernetes services, the full host name otherwise |
| `%SERVICE_NAME%` | `<name>` for Kubernetes services, the full host name otherwise |
| `%SERVICE_FQDN%` | The full host name of the service, such as `reviews.default.svc.cluster.local` |
| `%SERVICE_PORT%` | The service port |
| `%SERVICE_PORT_NAME%` | The name of the service port |
| `%TARGET_PORT%` | The target port of the workload. Only meaningful in `inboundClusterStatName` cluster names |
| `%SUBSET_NAME%` | The `DestinationRule` subset name. Only for `outboundClusterStatName` |

Istio appends the `;` delimiter to the result, so the `cluster_name` tag keeps working. The same patterns also name the statistics of TCP proxies, without the delimiter. They do not change the cluster names in access logs.

If a pattern leaves out `%SUBSET_NAME%`, the clusters of all subsets of a service share the same statistics. For example, to name the outbound cluster statistics after the service and port:

{{< text syntax=yaml snip_id=outboundClusterStatName >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    outboundClusterStatName: "%SERVICE%_%SERVICE_PORT%"
{{< /text >}}

With this setting, the statistics for requests to the `httpbin` service on port `8000` in the `default` namespace start with `cluster.httpbin.default_8000;` instead of `cluster.outbound|8000||httpbin.default.svc.cluster.local;`.
