---
title: Envoy Statistics
description: Fine-grained control of Envoy statistics.
weight: 10
aliases:
  - /help/ops/telemetry/envoy-stats
  - /docs/ops/telemetry/envoy-stats
owner: istio/wg-policies-and-telemetry-maintainers
test: no
---

The Envoy proxy keeps detailed statistics about network traffic.

Envoy's statistics only cover the traffic for a particular Envoy instance.  See
[Observability](/docs/tasks/observability/) for persistent per-service Istio telemetry.  The
statistics the Envoy proxies record can provide more information about specific pod instances.

To see the statistics for a pod:

{{< text bash >}}
$ kubectl exec $POD -c istio-proxy -- pilot-agent request GET stats
{{< /text >}}

Envoy generates statistics about its behavior, scoping the statistics by proxy function. Examples include:

- [Upstream connection](https://www.envoyproxy.io/docs/envoy/latest/configuration/upstream/cluster_manager/cluster_stats)
- [Listener](https://www.envoyproxy.io/docs/envoy/latest/configuration/listeners/stats)
- [HTTP Connection Manager](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_conn_man/stats)
- [TCP proxy](https://www.envoyproxy.io/docs/envoy/latest/configuration/listeners/network_filters/tcp_proxy_filter#statistics)
- [Router](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_filters/router_filter.html?highlight=vhost#statistics)

By default, Istio configures Envoy to record minimal statistics. The default collection
keys are:

- `cluster_manager`
- `listener_manager`
- `server`
- `cluster.xds-grpc`
- `wasm`

To see the Envoy settings for statistics data collection use
[`istioctl proxy-config bootstrap`](/docs/reference/commands/istioctl/#istioctl-proxy-config-bootstrap) and follow the
[deep dive into Envoy configuration](/docs/ops/diagnostic-tools/proxy-cmd/#deep-dive-into-envoy-configuration).
Envoy only collects statistical data on items matching the `inclusion_list` within
the `stats_matcher` JSON element.

{{< tip >}}
Note Envoy stats name highly depends on how Envoy configuration is composed, and thus could tie to Istio control plane implementation detail.
If you are building dashboard or alert based on Envoy stats, before upgrading your Istio, it is highly recommended to examine the stats in a canary environment.
{{< /tip >}}

To configure Istio proxy to record additional statistics, you can add [`ProxyConfig.ProxyStatsMatcher`](/docs/reference/config/istio.mesh.v1alpha1/#ProxyStatsMatcher) to your mesh config. For example, to enable stats for circuit breaker, retry, and upstream connections globally, you can specify stats matcher as follow:

{{< text yaml >}}
proxyStatsMatcher:
  inclusionRegexps:
    - ".*circuit_breakers.*"
  inclusionPrefixes:
    - "upstream_rq_retry"
    - "upstream_cx"
{{< /text >}}

You can also override the global stats matching configuration at per proxy by using `proxy.istio.io/config` annotation. For example, to configure the same stats generation inclusion as above, you can add the annotation to a gateway proxy or a workload as follow:

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
Note if you are using `sidecar.istio.io/statsInclusionPrefixes`, `sidecar.istio.io/statsInclusionRegexps`, and `sidecar.istio.io/statsInclusionSuffixes`, please consider switching to `ProxyConfig` based configuration as it provides global default and uniform way to override at gateway and sidecar proxy.
{{< /tip >}}
