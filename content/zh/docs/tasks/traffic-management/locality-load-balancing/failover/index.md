---
title: 地域故障转移
description: 本任务演示如何为网格配置地域故障转移。
weight: 10
icon: tasks
keywords: [locality,load balancing,priority,prioritized,kubernetes,multicluster]
test: yes
owner: istio/wg-networking-maintainers
---

请按照本指南为您的网格配置地域故障转移。

在开始之前，一定要完成[开始之前](/zh/docs/tasks/traffic-management/locality-load-balancing/before-you-begin)
这一节包含的步骤。

在此任务中，您将使用 `Sleep` Pod 在 `region1.zone1` 作为请求源发送到 `HelloWorld` 服务。
然后，您将触发故障，这些故障将按照以下顺序导致不同地域之间的故障转移：

{{< image width="75%"
    link="sequence.svg"
    caption="地域故障转移顺序"
    >}}

在内部，[Envoy 优先级](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/upstream/load_balancing/priority.html)
用于控制故障转移。这些优先级将按照以下方式分配来自 `Sleep` Pod（在 `region1` `zone1`）的流量：

优先级 | 地域 | 细节
-------- | -------- | -------
0 | `region1.zone1` | 地区、区域、分区全部匹配。
1 | None | 由于此任务不使用分区，因此没有其他分区的匹配项。
2 | `region1.zone2` | 同一个地区内的不同区域。
3 | `region2.zone3` | 没有匹配项，但是为 `region1`->`region2` 定义了故障转移。
4 | `region3.zone4` | 没有匹配项并且没有为 `region1`->`region3` 定义故障转移。

## 配置地域故障转移 {#configure-locality-failover}

应用一个 `DestinationRule` 配置如下：

- 针对 `HelloWorld` 服务的[故障检测](/zh/docs/reference/config/networking/destination-rule/#OutlierDetection)。
  这是故障转移正常运行所必需的。
  特别是，它可以配置 Sidecar 代理以了解服务的 Endpoint 何时会不正常，最终触发故障转移到下一个地域。
- [故障转移](/zh/docs/reference/config/networking/destination-rule/#LocalityLoadBalancerSetting-Failover)
  地区之间的策略，这确保了超出地区边界的故障转移将具有可预测的行为。

- [连接池](/zh/docs/reference/config/networking/destination-rule/#ConnectionPoolSettings-http)
  强制每个HTTP请求使用一个新连接的策略。该任务利用 Envoy 的
  [逐出](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/operations/draining)
  功能强制将故障转移到下一个位置。一旦逐出，Envoy 将拒绝所有新的请求。
  由于每个请求都使用一个新连接，这将导致在耗尽后立即进行故障转移。**此配置仅用于演示目的。**

{{< text bash >}}
$ kubectl --context="${CTX_PRIMARY}" apply -n sample -f - <<EOF
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: helloworld
spec:
  host: helloworld.sample.svc.cluster.local
  trafficPolicy:
    connectionPool:
      http:
        maxRequestsPerConnection: 1
    loadBalancer:
      simple: ROUND_ROBIN
      localityLbSetting:
        enabled: true
        failover:
          - from: region1
            to: region2
    outlierDetection:
      consecutive5xxErrors: 1
      interval: 1s
      baseEjectionTime: 1m
EOF
{{< /text >}}

## 验证流量保持在 `region1.zone1` {#verify-traffic-stays-in-region1zone1}

从 `Sleep` Pod 调用 `HelloWorld` 服务：

{{< text bash >}}
$ kubectl exec --context="${CTX_R1_Z1}" -n sample -c sleep \
  "$(kubectl get pod --context="${CTX_R1_Z1}" -n sample -l \
  app=sleep -o jsonpath='{.items[0].metadata.name}')" \
  -- curl -sSL helloworld.sample:5000/hello
Hello version: region1.zone1, instance: helloworld-region1.zone1-86f77cd7b-cpxhv
{{< /text >}}

验证响应中的 `version` 是 `region1.zone`。

重复几次，验证响应总是相同的。

## 故障转移到 `region1.zone2` {#failover-to-region1zone2}

接下来， 触发故障转移到 `region1.zone2`。为此，您在 `region1.zone1` 中 `HelloWorld`
[逐出 Envoy Sidecar 代理](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/operations/draining#draining)：

{{< text bash >}}
$ kubectl --context="${CTX_R1_Z1}" exec \
  "$(kubectl get pod --context="${CTX_R1_Z1}" -n sample -l app=helloworld \
  -l version=region1.zone1 -o jsonpath='{.items[0].metadata.name}')" \
  -n sample -c istio-proxy -- curl -sSL -X POST 127.0.0.1:15000/drain_listeners
{{< /text >}}

从 `Sleep` Pod 调用 `HelloWorld` 服务：

{{< text bash >}}
$ kubectl exec --context="${CTX_R1_Z1}" -n sample -c sleep \
  "$(kubectl get pod --context="${CTX_R1_Z1}" -n sample -l \
  app=sleep -o jsonpath='{.items[0].metadata.name}')" \
  -- curl -sSL helloworld.sample:5000/hello
Hello version: region1.zone2, instance: helloworld-region1.zone2-86f77cd7b-cpxhv
{{< /text >}}

第一个调用将失败，这将触发故障转移。多次重复该命令，并验证响应中的 `version` 始终为 `region1.zone2`。

## 故障转移到 `region2.zone3` {#failover-to-region2zone3}

现在触发故障转移到 `region2.zone3`。正如您之前所做的，配置 `HelloWorld` 在 `region1.zone2` 中调用失败。

{{< text bash >}}
$ kubectl --context="${CTX_R1_Z2}" exec \
  "$(kubectl get pod --context="${CTX_R1_Z2}" -n sample -l app=helloworld \
  -l version=region1.zone2 -o jsonpath='{.items[0].metadata.name}')" \
  -n sample -c istio-proxy -- curl -sSL -X POST 127.0.0.1:15000/drain_listeners
{{< /text >}}

从 `Sleep` Pod 调用 `HelloWorld` 服务：

{{< text bash >}}
$ kubectl exec --context="${CTX_R1_Z1}" -n sample -c sleep \
  "$(kubectl get pod --context="${CTX_R1_Z1}" -n sample -l \
  app=sleep -o jsonpath='{.items[0].metadata.name}')" \
  -- curl -sSL helloworld.sample:5000/hello
Hello version: region2.zone3, instance: helloworld-region2.zone3-86f77cd7b-cpxhv
{{< /text >}}

第一个调用将失败，这将触发故障转移。多次重复该命令，并验证响应中的 `version` 始终为 `region2.zone3`。

## 故障转移到 `region3.zone4` {#failover-to-region3zone4}

现在触发故障转移到 `region3.zone4`。正如您之前所做的，配置 `HelloWorld` 在 `region2.zone3` 中调用失败。

{{< text bash >}}
$ kubectl --context="${CTX_R2_Z3}" exec \
  "$(kubectl get pod --context="${CTX_R2_Z3}" -n sample -l app=helloworld \
  -l version=region2.zone3 -o jsonpath='{.items[0].metadata.name}')" \
  -n sample -c istio-proxy -- curl -sSL -X POST 127.0.0.1:15000/drain_listeners
{{< /text >}}

从 `Sleep` Pod 调用 `HelloWorld` 服务：

{{< text bash >}}
$ kubectl exec --context="${CTX_R1_Z1}" -n sample -c sleep \
  "$(kubectl get pod --context="${CTX_R1_Z1}" -n sample -l \
  app=sleep -o jsonpath='{.items[0].metadata.name}')" \
  -- curl -sSL helloworld.sample:5000/hello
Hello version: region3.zone4, instance: helloworld-region3.zone4-86f77cd7b-cpxhv
{{< /text >}}

第一次调用将失败，这将触发故障转移。多次重复该命令，并验证响应中的 `version` 始终为 `region3.zone4`。

**恭喜！** 您成功配置了地域故障转移！

## 下一步 {#next-steps}

[清除](/zh/docs/tasks/traffic-management/locality-load-balancing/cleanup)此任务中的资源和文件。
