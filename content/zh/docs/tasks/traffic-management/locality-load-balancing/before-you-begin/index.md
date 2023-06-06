---
title: 开始之前
description: 配置地域负载均衡前的初始化步骤。
weight: 1
icon: tasks
keywords: [locality,load balancing,priority,prioritized,kubernetes,multicluster]
test: yes
owner: istio/wg-networking-maintainers
---

在开始区域负载均衡任务之前，必须首先
[在多个集群上安装 Istio](/zh/docs/setup/install/multicluster)。
这些集群必须跨越三个地区，其中包含四个可用区。
所需集群的数量可能会因您的云提供商所提供的功能而异。

{{< tip >}}
为简单起见，我们假设只有一个 {{< gloss >}}primary cluster{{< /gloss >}} 在网格中。
由于更改仅需要应用于一个集群，因此这简化了配置控制平面的过程。
{{< /tip >}}

我们将部署 `HelloWorld` 应用程序的多个实例，如下所示：

{{< image width="75%"
    link="setup.svg"
    caption="Setup for locality load balancing tasks"
    >}}

## 环境变量 {#environment-variables}

本指南假定将通过默认的 [Kubernetes 配置文件](https://kubernetes.io/zh-cn/docs/tasks/access-application-cluster/configure-access-multiple-clusters/)中的上下文访问所有集群。
以下环境变量将用于各种上下文：

变量 | 描述
-------- | -----------
`CTX_PRIMARY` | 用于主集群的上下文。
`CTX_R1_Z1` | 用于与 `region1.zone1` 中的 Pod 交互的上下文。
`CTX_R1_Z2` | 用于与 `region1.zone2` 中的 Pod 交互的上下文。
`CTX_R2_Z3` | 用于与 `region2.zone3` 中的 Pod 交互的上下文。
`CTX_R3_Z4` | 用于与 `region3.zone4` 中的 Pod 交互的上下文。

## 创建 `sample` 命名空间 {#create-the-sample-namespace}

首先，启用自动注入 Sidecar 并为 `sample` 命名空间生成 yaml：

{{< text bash >}}
$ cat <<EOF > sample.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: sample
  labels:
    istio-injection: enabled
EOF
{{< /text >}}

为每个集群添加 `sample` 命名空间：

{{< text bash >}}
$ for CTX in "$CTX_PRIMARY" "$CTX_R1_Z1" "$CTX_R1_Z2" "$CTX_R2_Z3" "$CTX_R3_Z4"; \
  do \
    kubectl --context="$CTX" apply -f sample.yaml; \
  done
{{< /text >}}

## 部署 `HelloWorld` {#deploy-helloWorld}

使用地域作为版本号，为每个地域生成 `HelloWorld` 的 yaml：

{{< text bash >}}
$ for LOC in "region1.zone1" "region1.zone2" "region2.zone3" "region3.zone4"; \
  do \
    ./@samples/helloworld/gen-helloworld.sh@ \
      --version "$LOC" > "helloworld-${LOC}.yaml"; \
  done
{{< /text >}}

应用 `HelloWorld` YAML 到每个地域的合适集群：

{{< text bash >}}
$ kubectl apply --context="${CTX_R1_Z1}" -n sample \
  -f helloworld-region1.zone1.yaml
{{< /text >}}

{{< text bash >}}
$ kubectl apply --context="${CTX_R1_Z2}" -n sample \
  -f helloworld-region1.zone2.yaml
{{< /text >}}

{{< text bash >}}
$ kubectl apply --context="${CTX_R2_Z3}" -n sample \
  -f helloworld-region2.zone3.yaml
{{< /text >}}

{{< text bash >}}
$ kubectl apply --context="${CTX_R3_Z4}" -n sample \
  -f helloworld-region3.zone4.yaml
{{< /text >}}

## 部署 `sleep` {#deploy-sleep}

部署 `Sleep` 应用到 `region1` `zone1`：

{{< text bash >}}
$ kubectl apply --context="${CTX_R1_Z1}" \
  -f @samples/sleep/sleep.yaml@ -n sample
{{< /text >}}

## 等待 `helloWorld` Pod {#wait-for-helloworld-pods}

等到 `HelloWorld` 在每个区域的 Pod 都为 `Running`：

{{< text bash >}}
$ kubectl get pod --context="${CTX_R1_Z1}" -n sample -l app="helloworld" \
  -l version="region1.zone1"
NAME                                       READY   STATUS    RESTARTS   AGE
helloworld-region1.zone1-86f77cd7b-cpxhv   2/2     Running   0          30s
{{< /text >}}

{{< text bash >}}
$ kubectl get pod --context="${CTX_R1_Z2}" -n sample -l app="helloworld" \
  -l version="region1.zone2"
NAME                                       READY   STATUS    RESTARTS   AGE
helloworld-region1.zone2-86f77cd7b-cpxhv   2/2     Running   0          30s
{{< /text >}}

{{< text bash >}}
$ kubectl get pod --context="${CTX_R2_Z3}" -n sample -l app="helloworld" \
  -l version="region2.zone3"
NAME                                       READY   STATUS    RESTARTS   AGE
helloworld-region2.zone3-86f77cd7b-cpxhv   2/2     Running   0          30s
{{< /text >}}

{{< text bash >}}
$ kubectl get pod --context="${CTX_R3_Z4}" -n sample -l app="helloworld" \
  -l version="region3.zone4"
NAME                                       READY   STATUS    RESTARTS   AGE
helloworld-region3.zone4-86f77cd7b-cpxhv   2/2     Running   0          30s
{{< /text >}}

**恭喜您！** 您已成功完成系统配置，现在可以开始进行地域负载均衡任务了！

## 下一步 {#next-steps}

现在，您可以配置以下负载均衡选项之一：

- [地域故障转移](/zh/docs/tasks/traffic-management/locality-load-balancing/failover)

- [地域权重分布](/zh/docs/tasks/traffic-management/locality-load-balancing/distribute)

{{< warning >}}
您只应配置负载均衡选项之一，因为这些选项是互斥的。尝试同时配置两个选项可能会导致意外行为。
{{< /warning >}}
