---
title: 多主架构的安装
description: 跨多个主集群，安装 Istio 网格。
weight: 10
icon: setup
keywords: [kubernetes,multicluster]
test: yes
owner: istio/wg-environments-maintainers
---

按照本指南在 `cluster1` 和 `cluster2` 两个集群上安装 Istio 控制平面，
将每一个集群都设置为主集群（{{< gloss >}}primary cluster{{< /gloss >}}）。
两个集群都运行在网络 `network1` 上，所以两个集群中的 Pod 可以直接通信。

继续安装之前，确保完成了[准备工作](/zh/docs/setup/install/multicluster/before-you-begin)中的步骤。

在此配置中，每一个控制平面都会监测两个集群 API 服务器的服务端点。

服务的工作负载（pod 到 pod）跨集群边界直接通讯。

{{< image width="75%"
    link="arch.svg"
    caption="同一网络的多主集群"
    >}}

## 将 `cluster1` 设为主集群 {#configure-cluster1-as-a-primary}

为 `cluster1` 创建 `istioctl` 配置：

{{< tabset category-name="multicluster-install-type-cluster-1" >}}

{{< tab name="IstioOperator" category-value="iop" >}}

使用 istioctl 和 `IstioOperator` API 在 `cluster1` 中将 Istio 安装为主节点。

{{< text bash >}}
$ cat <<EOF > cluster1.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  values:
    global:
      meshID: mesh1
      multiCluster:
        clusterName: cluster1
      network: network1
EOF
{{< /text >}}

将配置文件应用到 `cluster1`：

{{< text bash >}}
$ istioctl install --context="${CTX_CLUSTER1}" -f cluster1.yaml
{{< /text >}}

{{< /tab >}}
{{< tab name="Helm" category-value="helm" >}}

使用以下 Helm 命令在 `cluster1` 中将 Istio 安装为主节点：

在 `cluster1` 中安装 `base` Chart：

{{< text bash >}}
$ helm install istio-base istio/base -n istio-system --kube-context "${CTX_CLUSTER1}"
{{< /text >}}

然后，使用以下多集群设置在 `cluster1` 中安装 `istiod` Chart：

{{< text bash >}}
$ helm install istiod istio/istiod -n istio-system --kube-context "${CTX_CLUSTER1}" --set global.meshID=mesh1 --set global.multiCluster.clusterName=cluster1 --set global.network=network1
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

## 将 `cluster2` 设为主集群 {#configure-cluster2-as-a-primary}

为 `cluster2` 创建 `istioctl` 配置：

{{< tabset category-name="multicluster-install-type-cluster-2" >}}

{{< tab name="IstioOperator" category-value="iop" >}}

使用 istioctl 和 `IstioOperator` API 在 `cluster2` 中将 Istio 安装为主节点。

{{< text bash >}}
$ cat <<EOF > cluster2.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  values:
    global:
      meshID: mesh1
      multiCluster:
        clusterName: cluster2
      network: network1
EOF
{{< /text >}}

将配置文件应用到 `cluster2`：

{{< text bash >}}
$ istioctl install --context="${CTX_CLUSTER2}" -f cluster2.yaml
{{< /text >}}

{{< /tab >}}
{{< tab name="Helm" category-value="helm" >}}

使用以下 Helm 命令在 `cluster2` 中将 Istio 安装为主节点：

在 `cluster2` 中安装 `base` Chart：

{{< text bash >}}
$ helm install istio-base istio/base -n istio-system --kube-context "${CTX_CLUSTER2}"
{{< /text >}}

然后，使用以下多集群设置在 `cluster2` 中安装 `istiod` Chart：

{{< text bash >}}
$ helm install istiod istio/istiod -n istio-system --kube-context "${CTX_CLUSTER2}" --set global.meshID=mesh1 --set global.multiCluster.clusterName=cluster2 --set global.network=network1
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

## 开启端点发现 {#enable-endpoint-discovery}

在 `cluster2` 中安装从集群的 secret，该 secret 提供 `cluster1` 的 API 服务器的访问权限。

{{< text bash >}}
$ istioctl create-remote-secret \
    --context="${CTX_CLUSTER1}" \
    --name=cluster1 | \
    kubectl apply -f - --context="${CTX_CLUSTER2}"
{{< /text >}}

在 `cluster1` 中安装从集群的 secret，该 secret 提供 `cluster2` 的 API 服务器的访问权限。

{{< text bash >}}
$ istioctl create-remote-secret \
    --context="${CTX_CLUSTER2}" \
    --name=cluster2 | \
    kubectl apply -f - --context="${CTX_CLUSTER1}"
{{< /text >}}

**恭喜!** 您已经成功地安装了跨多个主集群 Istio 网格！

## 后续步骤 {#next-steps}

现在，您可以[验证此次安装](/zh/docs/setup/install/multicluster/verify)。

## 清理 {#cleanup}

使用与安装 Istio 相同的机制（istioctl 或 Helm）从
`cluster1` 和 `cluster2` 中卸载 Istio。

{{< tabset category-name="multicluster-uninstall-type-cluster-1" >}}

{{< tab name="IstioOperator" category-value="iop" >}}

在 `cluster1` 中卸载 Istio：

{{< text syntax=bash snip_id=none >}}
$ istioctl uninstall --context="${CTX_CLUSTER1}" -y --purge
$ kubectl delete ns istio-system --context="${CTX_CLUSTER1}"
{{< /text >}}

在 `cluster2` 中卸载 Istio：

{{< text syntax=bash snip_id=none >}}
$ istioctl uninstall --context="${CTX_CLUSTER2}" -y --purge
$ kubectl delete ns istio-system --context="${CTX_CLUSTER2}"
{{< /text >}}

{{< /tab >}}

{{< tab name="Helm" category-value="helm" >}}

从 `cluster1` 中删除 Istio Helm 安装：

{{< text syntax=bash >}}
$ helm delete istiod -n istio-system --kube-context "${CTX_CLUSTER1}"
$ helm delete istio-base -n istio-system --kube-context "${CTX_CLUSTER1}"
{{< /text >}}

从 `cluster1` 中删除 `istio-system` 命名空间：

{{< text syntax=bash >}}
$ kubectl delete ns istio-system --context="${CTX_CLUSTER1}"
{{< /text >}}

从 `cluster2` 中删除 Istio Helm 安装：

{{< text syntax=bash >}}
$ helm delete istiod -n istio-system --kube-context "${CTX_CLUSTER2}"
$ helm delete istio-base -n istio-system --kube-context "${CTX_CLUSTER2}"
{{< /text >}}

从 `cluster2` 中删除 `istio-system` 命名空间：

{{< text syntax=bash >}}
$ kubectl delete ns istio-system --context="${CTX_CLUSTER2}"
{{< /text >}}

（可选）删除 Istio 安装的 CRD：

删除 CRD 会永久删除您在集群中创建的所有 Istio 资源。
运行以下命令删除集群中安装的 Istio CRD：

{{< text syntax=bash snip_id=delete_crds >}}
$ kubectl get crd -oname --context "${CTX_CLUSTER1}" | grep --color=never 'istio.io' | xargs kubectl delete --context "${CTX_CLUSTER1}"
$ kubectl get crd -oname --context "${CTX_CLUSTER2}" | grep --color=never 'istio.io' | xargs kubectl delete --context "${CTX_CLUSTER2}"
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}
