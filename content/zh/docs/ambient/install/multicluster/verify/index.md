---
title: 验证 Ambient 安装
description: 验证 Istio Ambient 网格是否已在多个集群上正确安装。
weight: 50
keywords: [kubernetes,multicluster,ambient]
test: yes
owner: istio/wg-environments-maintainers
prev: /zh/docs/ambient/install/multicluster/multi-primary_multi-network
---
按照本指南验证您的 Ambient 多集群 Istio 安装是否正常工作。

在继续之前，请务必完成[开始之前](/zh/docs/ambient/install/multicluster/before-you-begin)下的步骤，
且选择并遵循其中一个[多集群安装指南](/zh/docs/ambient/install/multicluster)。

在本指南中，我们将验证多集群功能是否正常，并将 `HelloWorld` 应用程序 `v1`
部署到 `cluster1`，将 `v2` 部署到 `cluster2`。当 `HelloWorld` 收到请求时，
当我们调用 `/hello` 路径时，它会在响应中包含其版本信息。

我们还将把 `curl` 容器部署到两个集群。我们将使用这些 Pod 作为 `HelloWorld` 服务的请求源，
模拟网格内流量。最后，在生成流量后，我们将观察哪个集群接收了请求。

## 验证多集群 {#verify-multicluster}

确认 Istiod 现在能够与远程集群的 Kubernetes 控制平面通信。

{{< text bash >}}
$ istioctl remote-clusters --context="${CTX_CLUSTER1}"
NAME         SECRET                                        STATUS      ISTIOD
cluster1                                                   synced      istiod-7b74b769db-kb4kj
cluster2     istio-system/istio-remote-secret-cluster2     synced      istiod-7b74b769db-kb4kj
{{< /text >}}

所有集群的状态都应显示为 `synced`。如果集群的 `STATUS` 显示为 `timeout`，
则表示主集群中的 Istiod 无法与远程集群通信。有关详细的错误消息，请参阅 Istiod 日志。

注意：如果您确实看到 `timeout` 问题，并且在主集群中的 Istiod 和远程集群中的 Kubernetes
控制平面之间存在中间主机（例如 [Rancher 身份验证代理](https://ranchermanager.docs.rancher.com/zh/how-to-guides/new-user-guides/manage-clusters/access-clusters/authorized-cluster-endpoint#two-authentication-methods-for-rke-clusters)），
则可能需要更新 `istioctl create-remote-secret` 生成的 kubeconfig
的 `certificate-authority-data` 字段，以匹配中间主机正在使用的证书。

## 部署 `HelloWorld` 服务 {#deploy-the-helloworld-service}

为了使 `HelloWorld` 服务能够从任何集群调用，
DNS 查询必须在每个集群中成功（详情请参阅[部署模型](/zh/docs/ops/deployment/deployment-models#dns-with-multiple-clusters)）。
我们将通过将 `HelloWorld` 服务部署到网格中的每个集群来解决此问题。

{{< tip >}}
在继续之前，请确保两个集群中的 istio-system 命名空间都将 `istio.io/topology-network`
设置为适当的值（例如，`cluster1` 设置为 `network1`，`cluster2` 设置为 `network2`）。
{{< /tip >}}

首先，在每个集群中创建 `sample` 命名空间：

{{< text bash >}}
$ kubectl create --context="${CTX_CLUSTER1}" namespace sample
$ kubectl create --context="${CTX_CLUSTER2}" namespace sample
{{< /text >}}

在网格中注册 `sample` 命名空间：

{{< text bash >}}
$ kubectl label --context="${CTX_CLUSTER1}" namespace sample \
    istio.io/dataplane-mode=ambient
$ kubectl label --context="${CTX_CLUSTER2}" namespace sample \
    istio.io/dataplane-mode=ambient
{{< /text >}}

在两个集群中创建 `HelloWorld` 服务：

{{< text bash >}}
$ kubectl apply --context="${CTX_CLUSTER1}" \
    -f @samples/helloworld/helloworld.yaml@ \
    -l service=helloworld -n sample
$ kubectl apply --context="${CTX_CLUSTER2}" \
    -f @samples/helloworld/helloworld.yaml@ \
    -l service=helloworld -n sample
{{< /text >}}

## 部署 `HelloWorld` `V1` {#deploy-helloworld-v1}

将 `helloworld-v1` 应用程序部署到 `cluster1`：

{{< text bash >}}
$ kubectl apply --context="${CTX_CLUSTER1}" \
    -f @samples/helloworld/helloworld.yaml@ \
    -l version=v1 -n sample
{{< /text >}}

确认 `helloworld-v1` Pod 状态：

{{< text bash >}}
$ kubectl get pod --context="${CTX_CLUSTER1}" -n sample -l app=helloworld
NAME                            READY     STATUS    RESTARTS   AGE
helloworld-v1-86f77cd7bd-cpxhv  1/1       Running   0          40s
{{< /text >}}

等待 `helloworld-v1` 的状态变为 `Running`。

现在，将 `cluster1` 中的 helloworld 服务标记为全局，以便可以从网格中的其他集群访问它：

{{< text bash >}}
$ kubectl label --context="${CTX_CLUSTER1}" svc helloworld -n sample \
    istio.io/global="true"
{{< /text >}}

## 部署 `HelloWorld` `V2` {#deploy-helloworld-v2}

将 `helloworld-v2` 应用程序部署到 `cluster2`：

{{< text bash >}}
$ kubectl apply --context="${CTX_CLUSTER2}" \
    -f @samples/helloworld/helloworld.yaml@ \
    -l version=v2 -n sample
{{< /text >}}

确认 `helloworld-v2` Pod 状态：

{{< text bash >}}
$ kubectl get pod --context="${CTX_CLUSTER2}" -n sample -l app=helloworld
NAME                            READY     STATUS    RESTARTS   AGE
helloworld-v2-758dd55874-6x4t8  1/1       Running   0          40s
{{< /text >}}

等待 `helloworld-v2` 的状态变为 `Running`。

现在，将 `cluster2` 中的 helloworld 服务标记为全局，以便可以从网格中的其他集群访问它：

{{< text bash >}}
$ kubectl label --context="${CTX_CLUSTER2}" svc helloworld -n sample \
    istio.io/global="true"
{{< /text >}}

## 部署 `curl` {#deploy-curl}

将 `curl` 应用程序部署到两个集群：

{{< text bash >}}
$ kubectl apply --context="${CTX_CLUSTER1}" \
    -f @samples/curl/curl.yaml@ -n sample
$ kubectl apply --context="${CTX_CLUSTER2}" \
    -f @samples/curl/curl.yaml@ -n sample
{{< /text >}}

确认 `cluster1` 上的 `curl` Pod 状态：

{{< text bash >}}
$ kubectl get pod --context="${CTX_CLUSTER1}" -n sample -l app=curl
NAME                             READY   STATUS    RESTARTS   AGE
curl-754684654f-n6bzf            1/1     Running   0          5s
{{< /text >}}

等待 `curl` Pod 的状态变为 `Running`。

确认 `cluster2` 上的 `curl` Pod 状态：

{{< text bash >}}
$ kubectl get pod --context="${CTX_CLUSTER2}" -n sample -l app=curl
NAME                             READY   STATUS    RESTARTS   AGE
curl-754684654f-dzl9j            1/1     Running   0          5s
{{< /text >}}

等待 `curl` Pod 的状态变为 `Running`。

## 验证跨集群流量 {#verifying-cross-cluster-traffic}

要验证跨集群负载均衡是否按预期工作，请使用 `curl` Pod
多次调用 `HelloWorld` 服务。为确保负载均衡正常工作，
请从部署中的所有集群调用 `HelloWorld` 服务。

从 `cluster1` 上的 `curl` Pod 向 `HelloWorld` 服务发送一个请求：

{{< text bash >}}
$ kubectl exec --context="${CTX_CLUSTER1}" -n sample -c curl \
    "$(kubectl get pod --context="${CTX_CLUSTER1}" -n sample -l \
    app=curl -o jsonpath='{.items[0].metadata.name}')" \
    -- curl -sS helloworld.sample:5000/hello
{{< /text >}}

重复此请求几次，并验证 `HelloWorld` 版本是否应在 `v1` 和 `v2` 之间变化，
这表示两个集群中的端点都在被使用：

{{< text plain >}}
Hello version: v2, instance: helloworld-v2-758dd55874-6x4t8
Hello version: v1, instance: helloworld-v1-86f77cd7bd-cpxhv
...
{{< /text >}}

现在从 `cluster2` 上的 `curl` Pod 重复此过程：

{{< text bash >}}
$ kubectl exec --context="${CTX_CLUSTER2}" -n sample -c curl \
    "$(kubectl get pod --context="${CTX_CLUSTER2}" -n sample -l \
    app=curl -o jsonpath='{.items[0].metadata.name}')" \
    -- curl -sS helloworld.sample:5000/hello
{{< /text >}}

重复此请求几次并验证 `HelloWorld` 版本是否应在 `v1` 和 `v2` 之间切换：

{{< text plain >}}
Hello version: v2, instance: helloworld-v2-758dd55874-6x4t8
Hello version: v1, instance: helloworld-v1-86f77cd7bd-cpxhv
...
{{< /text >}}

**恭喜！**您已成功在多个集群上安装并验证了 Istio！

## 后续步骤 {#next-steps}

为您的多集群部署配置[本地故障转移](/zh/docs/ambient/install/multicluster/failover)。
