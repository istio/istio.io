---
title: 验证安装结果
description: 验证 Istio 已成功安装到多集群环境中。
weight: 50
icon: setup
keywords: [kubernetes,multicluster]
test: yes
owner: istio/wg-environments-maintainers
---
按照本指南，验证在多集群环境中安装的 Istio 可以正常工作。

继续操作之前，请确保完成了[准备工作](/zh/docs/setup/install/multicluster/before-you-begin)中的步骤。

在本指南中，我们将在 `cluster1` 安装 `V1` 版的 `HelloWorld` 应用程序，
在 `cluster2` 安装 `V2` 版的 `HelloWorld` 应用程序。
当处理一个请求时，`HelloWorld` 会在响应消息中包含它自身的版本号。

我们也会在两个集群中均部署 `Sleep` 容器。
这些 Pod 将被用作客户端（source），发送请求给 `HelloWorld`。
最后，通过收集这些流量数据，我们将能观测并识别出是那个集群处理了请求。

## 部署服务 `HelloWorld` {#deploy-the-helloworld-service}

为了支持从任意集群中调用 `HelloWorld` 服务，每个集群的 DNS 解析必须可用
（详细信息，参见[部署模型](/zh/docs/ops/deployment/deployment-models#dns-with-multiple-clusters)）。
我们通过在网格的每一个集群中部署 `HelloWorld` 服务，来解决这个问题，

首先，在每个集群中创建命名空间 `sample`：

{{< text bash >}}
$ kubectl create --context="${CTX_CLUSTER1}" namespace sample
$ kubectl create --context="${CTX_CLUSTER2}" namespace sample
{{< /text >}}

为命名空间 `sample` 开启 sidecar 自动注入：

{{< text bash >}}
$ kubectl label --context="${CTX_CLUSTER1}" namespace sample \
    istio-injection=enabled
$ kubectl label --context="${CTX_CLUSTER2}" namespace sample \
    istio-injection=enabled
{{< /text >}}

在每个集群中创建 `HelloWorld` 服务：

{{< text bash >}}
$ kubectl apply --context="${CTX_CLUSTER1}" \
    -f @samples/helloworld/helloworld.yaml@ \
    -l service=helloworld -n sample
$ kubectl apply --context="${CTX_CLUSTER2}" \
    -f @samples/helloworld/helloworld.yaml@ \
    -l service=helloworld -n sample
{{< /text >}}

## 部署 `V1` 版的 `HelloWorld` {#deploy-helloworld-v1}

把应用 `helloworld-v1` 部署到 `cluster1`：

{{< text bash >}}
$ kubectl apply --context="${CTX_CLUSTER1}" \
    -f @samples/helloworld/helloworld.yaml@ \
    -l version=v1 -n sample
{{< /text >}}

确认 `helloworld-v1` pod 的状态：

{{< text bash >}}
$ kubectl get pod --context="${CTX_CLUSTER1}" -n sample -l app=helloworld
NAME                            READY     STATUS    RESTARTS   AGE
helloworld-v1-86f77cd7bd-cpxhv  2/2       Running   0          40s
{{< /text >}}

等待 `helloworld-v1` 的状态最终变为 `Running` 状态：

## 部署 `V2` 版的 `HelloWorld` {#deploy-helloworld-v1}

把应用 `helloworld-v2` 部署到 `cluster2`：

{{< text bash >}}
$ kubectl apply --context="${CTX_CLUSTER2}" \
    -f @samples/helloworld/helloworld.yaml@ \
    -l version=v2 -n sample
{{< /text >}}

确认 `helloworld-v2` pod 的状态：

{{< text bash >}}
$ kubectl get pod --context="${CTX_CLUSTER2}" -n sample -l app=helloworld
NAME                            READY     STATUS    RESTARTS   AGE
helloworld-v2-758dd55874-6x4t8  2/2       Running   0          40s
{{< /text >}}

等待 `helloworld-v2` 的状态最终变为 `Running` 状态：

## 部署 `Sleep` {#deploy-sleep}

把应用 `Sleep` 部署到每个集群：

{{< text bash >}}
$ kubectl apply --context="${CTX_CLUSTER1}" \
    -f @samples/sleep/sleep.yaml@ -n sample
$ kubectl apply --context="${CTX_CLUSTER2}" \
    -f @samples/sleep/sleep.yaml@ -n sample
{{< /text >}}

确认 `cluster1` 上 `Sleep` 的状态：

{{< text bash >}}
$ kubectl get pod --context="${CTX_CLUSTER1}" -n sample -l app=sleep
NAME                             READY   STATUS    RESTARTS   AGE
sleep-754684654f-n6bzf           2/2     Running   0          5s
{{< /text >}}

等待 `Sleep` 的状态最终变为 `Running` 状态：

确认 `cluster2` 上 `Sleep` 的状态：

{{< text bash >}}
$ kubectl get pod --context="${CTX_CLUSTER2}" -n sample -l app=sleep
NAME                             READY   STATUS    RESTARTS   AGE
sleep-754684654f-dzl9j           2/2     Running   0          5s
{{< /text >}}

等待 `Sleep` 的状态最终变为 `Running` 状态：

## 验证跨集群流量 {#verifying-cross-cluster-traffic}

要验证跨集群负载均衡是否按预期工作，需要用 `Sleep` pod 重复调用服务 `HelloWorld`。
为了确认负载均衡按预期工作，需要从所有集群调用服务 `HelloWorld`。

从 `cluster1` 中的 `Sleep` pod 发送请求给服务 `HelloWorld`：

{{< text bash >}}
$ kubectl exec --context="${CTX_CLUSTER1}" -n sample -c sleep \
    "$(kubectl get pod --context="${CTX_CLUSTER1}" -n sample -l \
    app=sleep -o jsonpath='{.items[0].metadata.name}')" \
    -- curl helloworld.sample:5000/hello
{{< /text >}}

重复几次这个请求，验证 `HelloWorld` 的版本在 `v1` 和 `v2` 之间切换：

{{< text plain >}}
Hello version: v2, instance: helloworld-v2-758dd55874-6x4t8
Hello version: v1, instance: helloworld-v1-86f77cd7bd-cpxhv
...
{{< /text >}}

现在，用 `cluster2` 中的 `Sleep` pod 重复此过程：

{{< text bash >}}
$ kubectl exec --context="${CTX_CLUSTER2}" -n sample -c sleep \
    "$(kubectl get pod --context="${CTX_CLUSTER2}" -n sample -l \
    app=sleep -o jsonpath='{.items[0].metadata.name}')" \
    -- curl helloworld.sample:5000/hello
{{< /text >}}

重复几次这个请求，验证 `HelloWorld` 的版本在 `v1` 和 `v2` 之间切换：

{{< text plain >}}
Hello version: v2, instance: helloworld-v2-758dd55874-6x4t8
Hello version: v1, instance: helloworld-v1-86f77cd7bd-cpxhv
...
{{< /text >}}

**恭喜!** 您已成功的在多集群环境中安装、并验证了 Istio！

## 后续步骤 {#next-steps}

查看[地域性负载均衡任务](/zh/docs/tasks/traffic-management/locality-load-balancing)，
了解怎么跨多集群网格控制流量。
