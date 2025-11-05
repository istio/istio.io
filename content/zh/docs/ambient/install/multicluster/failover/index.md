---
title: 在多集群 Ambient 安装中配置故障转移行为
description: 使用 waypoint 配置 Ambient 多集群网格中的异常值检测和故障转移行为。
weight: 70
keywords: [kubernetes,multicluster,ambient]
test: yes
owner: istio/wg-environments-maintainers
prev: /zh/docs/ambient/install/multicluster/verify
---
按照本指南，使用 waypoint 代理自定义 Ambient 多集群 Istio 安装中的故障转移行为。

在继续操作之前，请务必按照[多集群安装指南](/zh/docs/ambient/install/multicluster)之一完成
Ambient 多集群 Istio 安装，并验证安装是否正常工作。

在本指南中，我们将基于用于验证多集群安装的 `HelloWorld` 应用程序进行构建。
我们将为 `HelloWorld` 服务配置本地故障转移，
使其优先使用客户端所在集群中的端点（使用 `DestinationRule`），并部署一个 waypoint 代理来强制执行此配置。

## 部署 waypoint 代理 {#deploy-waypoint-proxy}

为了配置异常值检测并自定义服务的故障转移行为，我们需要一个 waypoint 代理。
首先，将 waypoint 代理部署到网格中的每个集群：

{{< text bash >}}
$ istioctl --context "${CTX_CLUSTER1}" waypoint apply --name waypoint --for service -n sample --wait
$ istioctl --context "${CTX_CLUSTER2}" waypoint apply --name waypoint --for service -n sample --wait
{{< /text >}}

确认集群 `cluster1` 上的 waypoint 代理部署状态：

{{< text bash >}}
$ kubectl --context "${CTX_CLUSTER1}" get deployment waypoint --namespace sample
NAME       READY   UP-TO-DATE   AVAILABLE   AGE
waypoint   1/1     1            1           137m
{{< /text >}}

确认集群 `cluster2` 上的 waypoint 代理部署状态：

{{< text bash >}}
$ kubectl --context "${CTX_CLUSTER2}" get deployment waypoint --namespace sample
NAME       READY   UP-TO-DATE   AVAILABLE   AGE
waypoint   1/1     1            1           138m
{{< /text >}}

请等待所有 waypoint 代理准备就绪。

在每个集群中配置 `HelloWorld` 服务以使用 waypoint 代理：

{{< text bash >}}
$ kubectl --context "${CTX_CLUSTER1}" label svc helloworld -n sample istio.io/use-waypoint=waypoint
$ kubectl --context "${CTX_CLUSTER2}" label svc helloworld -n sample istio.io/use-waypoint=waypoint
{{< /text >}}

最后，这一步专门针对 waypoint 代理的多集群部署，将每个集群中的 waypoint
代理服务标记为全局服务，就像之前对 `HelloWorld` 服务所做的那样：

{{< text bash >}}
$ kubectl --context "${CTX_CLUSTER1}" label svc waypoint -n sample istio.io/global=true
$ kubectl --context "${CTX_CLUSTER2}" label svc waypoint -n sample istio.io/global=true
{{< /text >}}

两个集群中的 `HelloWorld` 服务现在都配置为使用 waypoint 代理，
但 waypoint 代理目前还没有任何实际作用。

## 配置本地故障转移 {#configure-locality-failover}

要配置本地故障转移，请在 `cluster1` 中创建并应用 `DestinationRule`：

{{< text bash >}}
$ kubectl --context "${CTX_CLUSTER1}" apply -n sample -f - <<EOF
apiVersion: networking.istio.io/v1
kind: DestinationRule
metadata:
  name: helloworld
spec:
  host: helloworld.sample.svc.cluster.local
  trafficPolicy:
    outlierDetection:
      consecutive5xxErrors: 1
      interval: 1s
      baseEjectionTime: 1m
    loadBalancer:
      simple: ROUND_ROBIN
      localityLbSetting:
        enabled: true
        failoverPriority:
          - topology.istio.io/cluster
EOF
{{< /text >}}

在 `cluster2` 中也应用相同的 `DestinationRule`：

{{< text bash >}}
$ kubectl --context "${CTX_CLUSTER2}" apply -n sample -f - <<EOF
apiVersion: networking.istio.io/v1
kind: DestinationRule
metadata:
  name: helloworld
spec:
  host: helloworld.sample.svc.cluster.local
  trafficPolicy:
    outlierDetection:
      consecutive5xxErrors: 1
      interval: 1s
      baseEjectionTime: 1m
    loadBalancer:
      simple: ROUND_ROBIN
      localityLbSetting:
        enabled: true
        failoverPriority:
          - topology.istio.io/cluster
EOF
{{< /text >}}

此 `DestinationRule` 配置以下内容：

- 为 `HelloWorld` 服务配置[异常值检测](/zh/docs/reference/config/networking/destination-rule/#OutlierDetection)。
  此规则指示 waypoint 代理如何识别服务的端点何时出现异常。这是故障转移正常运行所必需的。

- [故障转移优先级](/zh/docs/reference/config/networking/destination-rule/#LocalityLoadBalancerSetting)指示
  waypoint 代理在路由请求时如何确定端点的优先级。在本例中，
  waypoint 代理将优先处理同一集群中的端点，而不是其他集群中的端点。

有了这些策略，当端点与 waypoint 代理位于同一集群中且根据异常值检测配置被认为运行正常时，
waypoint 代理将优先选择这些端点。

## 验证流量是否保持在本地集群内 {#verify-traffic-stays-in-local-cluster}

从 `cluster1` 上的 `curl` Pod 向 `HelloWorld` 服务发送请求：

{{< text bash >}}
$ kubectl exec --context "${CTX_CLUSTER1}" -n sample -c curl \
    "$(kubectl get pod --context "${CTX_CLUSTER1}" -n sample -l \
    app=curl -o jsonpath='{.items[0].metadata.name}')" \
    -- curl -sS helloworld.sample:5000/hello
{{< /text >}}

现在，如果您多次重复此请求并验证 `HelloWorld` 版本应始终为 `v1`，
因为流量始终位于 `cluster1` 中：

{{< text plain >}}
Hello version: v1, instance: helloworld-v1-954745fd-z6qcn
Hello version: v1, instance: helloworld-v1-954745fd-z6qcn
...
{{< /text >}}

同样地，从 `cluster2` 上的 `curl` Pod 多次发送请求：

{{< text bash >}}
$ kubectl exec --context "${CTX_CLUSTER2}" -n sample -c curl \
    "$(kubectl get pod --context "${CTX_CLUSTER2}" -n sample -l \
    app=curl -o jsonpath='{.items[0].metadata.name}')" \
    -- curl -sS helloworld.sample:5000/hello
{{< /text >}}

通过查看响应中的版本信息，您应该可以看到所有请求都在 `cluster2` 中处理：

{{< text plain >}}
Hello version: v2, instance: helloworld-v2-7b768b9bbd-7zftm
Hello version: v2, instance: helloworld-v2-7b768b9bbd-7zftm
...
{{< /text >}}

## 验证故障转移到另一个集群 {#verify-failover-to-another-cluster}

为了验证故障转移到从集群是否有效，通过缩减部署规模来模拟
`cluster1` 中的 `HelloWorld` 服务中断：

{{< text bash >}}
$ kubectl --context "${CTX_CLUSTER1}" scale --replicas=0 deployment/helloworld-v1 -n sample
{{< /text >}}

再次从 `cluster1` 上的 `curl` Pod 向 `HelloWorld` 服务发送请求：

{{< text bash >}}
$ kubectl exec --context "${CTX_CLUSTER1}" -n sample -c curl \
    "$(kubectl get pod --context "${CTX_CLUSTER1}" -n sample -l \
    app=curl -o jsonpath='{.items[0].metadata.name}')" \
    -- curl -sS helloworld.sample:5000/hello
{{< /text >}}

这次您应该会看到请求是由 `cluster2` 中的 `HelloWorld` 服务处理的，
因为 `cluster1` 中没有可用的端点：

{{< text plain >}}
Hello version: v2, instance: helloworld-v2-7b768b9bbd-7zftm
Hello version: v2, instance: helloworld-v2-7b768b9bbd-7zftm
...
{{< /text >}}

**恭喜！**您已成功的在 Istio Ambient 多集群部署中配置本地故障转移！
