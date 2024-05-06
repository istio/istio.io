---
title: 地域权重分布
description: 本指南演示如何配置地域权重分配。
weight: 20
icon: tasks
keywords: [locality,load balancing,kubernetes,multicluster]
test: yes
owner: istio/wg-networking-maintainers
---

按照此指南配置跨地区的流量分布。

在继续之前，请确保完成[开始之前](/zh/docs/tasks/traffic-management/locality-load-balancing/before-you-begin)这一节所包含的步骤。

在这个任务中，您将使用 `region1` `zone1` 中的 `Sleep` Pod 作为 `HelloWorld` 服务的请求源。
您将使用以下分布在不同的地域配置Istio：

地区 | 区域 | 流量(%)
------ | ---- | ------------
`region1` | `zone1` | 70
`region1` | `zone2` | 20
`region2` | `zone3` | 0
`region3` | `zone4` | 10

## 配置权重分布 {#configure-weighted-distribution}

应用 `DestinationRule` 配置如下：

- 针对 `HelloWorld` 服务执行[故障检测](/zh/docs/reference/config/networking/destination-rule/#OutlierDetection)。
  这是 Distribution 正常运行所必需的。
  特别是，它配置 Sidecar 代理以了解服务的 Endpoint 何时会不健康。

- [权重分布](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/upstream/load_balancing/locality_weight.html?highlight=weight)
  如上表中所述的 `HelloWorld` 服务。

{{< text bash >}}
$ kubectl --context="${CTX_PRIMARY}" apply -n sample -f - <<EOF
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: helloworld
spec:
  host: helloworld.sample.svc.cluster.local
  trafficPolicy:
    loadBalancer:
      localityLbSetting:
        enabled: true
        distribute:
        - from: region1/zone1/*
          to:
            "region1/zone1/*": 70
            "region1/zone2/*": 20
            "region3/zone4/*": 10
    outlierDetection:
      consecutive5xxErrors: 100
      interval: 1s
      baseEjectionTime: 1m
EOF
{{< /text >}}

## 验证分布 {#verify-the-distribution}

从 `Sleep` Pod 调用 `HelloWorld` 服务：

{{< text bash >}}
$ kubectl exec --context="${CTX_R1_Z1}" -n sample -c sleep \
  "$(kubectl get pod --context="${CTX_R1_Z1}" -n sample -l \
  app=sleep -o jsonpath='{.items[0].metadata.name}')" \
  -- curl -sSL helloworld.sample:5000/hello
{{< /text >}}

重复多次，并验证每个 Pod 的回复数与本文开头表格中所列的预期百分比匹配。

**恭喜！** 您成功配置了地域权重分布！

## 下一步 {#next-steps}

[清理](/zh/docs/tasks/traffic-management/locality-load-balancing/cleanup)任务中的文件与资源。
