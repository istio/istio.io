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
