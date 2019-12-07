---
title: 配置 Citadel 的 Service Account Secret 生成
description: 配置 Citadel 应该为哪一个命名空间生成 service account secret。
weight: 40
aliases:
    - /zh/docs/tasks/security/ca-namespace-targeting/
---

集群操作者可以决定不为命名空间的一些子空间生成 `ServiceAccount` secret，或者使 `ServiceAccount` secret 生成器加入每一个命名空间。此任务描述了操作者如何针对这些情况配置集群。有关 Citadel 命名空间定位机制的完整文档可参考[此处](/zh/docs/ops/configuration/mesh/secret-creation/)。

## 开始之前{#before-you-begin}

为了完成此任务，您首先应该执行以下操作：

* 阅读[安全概念](/zh/docs/ops/configuration/mesh/secret-creation/)。

* 按照 [Istio 安装指南](/zh/docs/setup/install/istioctl/)安装 Istio，并开启 mutual TLS。

### 停用单个命名空间的 Service Account secret 生成器{#deactivating-service-account-secret-generation-for-a-single-namespace}

要创建一个新的示例命名空间 `foo`，请运行：

{{< text bash >}}
$ kubectl create ns foo
{{< /text >}}

Service account secret 按照默认行为创建。为了校验 Citadel 在 `foo` 命名空间中为默认的 service account 生成了一个 key/cert secret，请运行（注意，本操作可能长达 1 分钟）：

{{< text bash >}}
$ kubectl get secrets -n foo | grep istio.io
NAME                    TYPE                           DATA      AGE
istio.default           istio.io/key-and-cert          3         13s
{{< /text >}}

为了防止 Citadel 在命名空间 `foo` 中创建 `ServiceAccount` secret，需要标识命名空间，请运行：

{{< text bash >}}
$ kubectl label ns foo ca.istio.io/override=false
{{< /text >}}

在命名空间创建一个新的 `ServiceAccount`，请运行：

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: sample-service-account
  namespace: foo
EOF
{{< /text >}}

再次检查命名空间的 secret，请运行：

{{< text bash >}}
$ kubectl get secrets -n foo | grep istio.io
NAME                    TYPE                           DATA      AGE
istio.default           istio.io/key-and-cert          3         11m
{{< /text >}}

您可以观察到在 `sample-service-account` service account 中没有新的 `istio.io/key-and-cert` secret 生成。

### 加入 Service Account secret 生成器{#opt-in-service-account-secret-generation}

设置 `enableNamespacesByDefault` 的安装选项为 `false` 使 `ServiceAcount` secret 生成器加入（即，除非另有说明，否则禁止生成 secret）：

{{< text yaml >}}
...
security:
    enableNamespacesByDefault: false
...
{{< /text >}}

一旦应用此网格配置，创建一个新的 `foo` 命名空间并检查当前命名空间的 secret，请运行：

{{< text bash >}}
$ kubectl create ns foo
$ kubectl get secrets -n foo | grep istio.io
{{< /text >}}

您可以观察到没有 secret 被创建。为了覆盖 `foo` 命名空间中的值，在命名空间中添加一个 `ca.istio.io/override=true` 的标识：

{{< text bash >}}
$ kubectl label ns foo ca.istio.io/override=true
{{< /text >}}

在 `foo` 命名空间中创建一个新的 service account，请运行：

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: sample-service-account
  namespace: foo
EOF
{{< /text >}}

再次检查命名空间的 secret，请运行：

{{< text bash >}}
$ kubectl get secrets -n foo | grep istio.io
NAME                                 TYPE                                  DATA   AGE
istio.default                        istio.io/key-and-cert                 3      47s
istio.sample-service-account         istio.io/key-and-cert                 3      6s
{{< /text >}}

您可以观察到，除 `sample-service-account` 外的 `default` service account 也创建了一个 `istio.io/key-and-cert` secret。这是由于追溯 secret 生成功能所致，一旦从非活跃状态转换为活跃状态，它将为命名空间中的所有 service accounts 创建 secret。

## 清理{#cleanup}

删除 `foo` 测试命名空间及其中的所有资源，请运行：

{{< text bash >}}
$ kubectl delete ns foo
{{< /text >}}
