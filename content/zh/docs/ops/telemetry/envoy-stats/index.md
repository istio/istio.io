---
title: Envoy 统计数据
description: Envoy 统计数据的细粒度控制。
weight: 95
---

Envoy 代理中保存了网络流量相关的详细统计数据。

Envoy 的统计数据只包含了特定 Envoy 实例中的流量相关的内容。[遥测](/zh/docs/tasks/telemetry)中的内容介绍了以服务为单位的 Istio 遥测数据。Envoy 代理的记录中的统计数据能够提供更多的关于特定 Pod 的信息。

查看 Pod 的统计信息：

{{< text bash >}}
$ kubectl exec -it $POD  -c istio-proxy  -- sh -c 'curl localhost:15000/stats'
{{< /text >}}

[Envoy 文档](https://www.envoyproxy.io/docs/envoy/latest/configuration/upstream/cluster_manager/cluster_stats)中包含了对于这些数据记录的解释说明。

缺省情况下，Istio 会配置 Envoy，要求其记录最少量的统计信息。默认的收集内容包括：

- `cluster_manager`
- `listener_manager`
- `http_mixer_filter`
- `tcp_mixer_filter`
- `server`
- `cluster.xds-grpc`

可以使用 `istioctl proxy-config bootstrap` 命令，并根据 [Envoy 配置深度解析](/zh/docs/ops/traffic-management/proxy-cmd/#envoy-配置深度解析)中的介绍查看 Envoy 的统计配置。Envoy 要根据 `stats_matcher` JSON 元素中的 `inclusion_list` 进行判断，列表中的数据才会进行收集。

要配置 Envoy 来记录入站和出站的流量，可以在 Kubernetes 的 `Deployment` Pod 模板中加入注解 `sidecar.istio.io/statsInclusionPrefixes`。加入 `cluster.outbound`，就可以收集外发流量以及断路器的活动。加入 `listener` 就可以搜集入站流量信息。[fortio-deploy.yaml]({{< github_file>}}/samples/httpbin/sample-client/fortio-deploy.yaml) 中展示了 `cluster.outbound` 前缀的用法。

还可以覆盖 Envoy 的配置，使之收集更少的信息。例如使用 `sidecar.istio.io/statsInclusionPrefixes: cluster_manager,listener_manager` 注解收集最少信息。
