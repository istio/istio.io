---
title: Envoy 的统计信息
description: 精细化控制 Envoy 的统计信息。
weight: 95
aliases:
    - /help/ops/telemetry/envoy-stats
---

Envoy 代理收集保留了关于网络流量的详细统计信息。

Envoy 的统计信息只覆盖了特定 Envoy 实例的流量。参考 [可观测性](/zh/docs/tasks/observability/)
了解关于服务级别的 Istio 遥测方面的内容。这些由 Envoy 代理产生的统计数据记录能够提供更多关于 pod 实例的具体信息。

查看某个 pod 的统计信息：

{{< text bash >}}
$ kubectl exec $POD -c istio-proxy -- pilot-agent request GET stats
{{< /text >}}

参考 [Envoy 文档](https://www.envoyproxy.io/docs/envoy/latest/configuration/upstream/cluster_manager/cluster_stats)
了解更多有关于这些记录数据的解释。

Istio 默认配置下 Envoy 只会记录最小化的统计信息。缺省的关键词集合有：

- `cluster_manager`
- `listener_manager`
- `http_mixer_filter`
- `tcp_mixer_filter`
- `server`
- `cluster.xds-grpc`

要查看关于统计数据收集的 Envoy 配置，可以使用
[`istioctl proxy-config bootstrap`](/zh/docs/reference/commands/istioctl/#istioctl-proxy-config-bootstrap) 命令，还可以参考
[深入研究 Envoy 配置](/zh/docs/ops/diagnostic-tools/proxy-cmd/#deep-dive-into-envoy-configuration) 更加深入的了解相关的配置。
需要注意的是, 只有那些 `stats_matcher` JSON 字段能匹配上  `inclusion_list` 的元件，Envoy 才会去收集他们的统计数据。

要想让 Envoy 去收集出站和入站流量的统计信息，只需将 `sidecar.istio.io/statsInclusionPrefixes` 注解加到 Kubernetes `Deployment` 的 pod 模板里去。
在模板里加上 `cluster.outbound` 前缀就能统计出站流量活动和熔断事件的数据, 相似，如果要收集入站流量的数据，只需加上 `listener` 前缀。
这个例子 [fortio-deploy.yaml]({{< github_file>}}/samples/httpbin/sample-client/fortio-deploy.yaml) 中用 `cluster.outbound`
前缀展示了 `sidecar.istio.io/statsInclusionPrefixes` 的用法。

你可以通过覆盖 Envoy 的默认配置去收集比通常更少的数据。比如可以使用
`sidecar.istio.io/statsInclusionPrefixes: cluster_manager,listener_manager`
去收集尽可能少的统计数据。
