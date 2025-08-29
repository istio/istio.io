---
title: 在不同的网络基础上安装 Ambient 多主模式
description: 在不同网络上的多个主集群上安装 Istio Ambient 网格。
weight: 30
keywords: [kubernetes,multicluster,ambient]
test: yes
owner: istio/wg-environments-maintainers
next: /zh/docs/ambient/install/multicluster/verify
prev: /zh/docs/ambient/install/multicluster/before-you-begin
---

{{< boilerplate alpha >}}

{{< tip >}}
本指南需要安装 Gateway API CRD。
{{< boilerplate gateway-api-install-crds >}}
{{< /tip >}}

按照本指南在 `cluster1` 和 `cluster2` 上安装 Istio 控制平面，
使每个集群成为{{< gloss "primary cluster" >}}主集群{{< /gloss >}}（这是目前 Ambient 模式下唯一支持的配置）。
集群 `cluster1` 位于 `network1` 网络上，而 `cluster2` 位于 `network2` 网络上。
这意味着跨集群边界的 Pod 之间没有直接连接。

在继续之前，请务必完成[开始之前](/zh/docs/ambient/install/multicluster/before-you-begin)下的步骤。

{{< boilerplate multi-cluster-with-metallb >}}

在此配置中，`cluster1` 和 `cluster2` 都会互相发现每个集群中的 API 服务器端点。

跨集群边界的服务工作负载通过专用网关间接通信，
用于[东西向](https://en.wikipedia.org/wiki/East-west_traffic)流量。
每个集群中的网关必须能够与其他集群互通。

{{< image width="75%"
    link="arch.svg"
    caption="独立网络上的多个主集群"
    >}}

## 设置 `cluster1` 的默认网络 {#set-the-default-network-for-cluster1}

如果 istio-system 命名空间已经创建，我们需要在那里设置集群的网络：

{{< text bash >}}
$ kubectl --context="${CTX_CLUSTER1}" label namespace istio-system topology.istio.io/network=network1
{{< /text >}}

## 将 `cluster1` 配置为主集群 {#configure-cluster1-as-a-primary}

为 `cluster1` 创建 `istioctl` 配置：

{{< tabset category-name="multicluster-install-type-cluster-1" >}}

{{< tab name="IstioOperator" category-value="iop" >}}

使用 istioctl 和 `IstioOperator` API 在 `cluster1` 中将 Istio 安装为主集群。

{{< text bash >}}
$ cat <<EOF > cluster1.yaml
apiVersion: insall.istio.io/v1alpha1
kind: IstioOperator
spec:
  profile: ambient
  components:
    pilot:
      k8s:
        env:
          - name: AMBIENT_ENABLE_MULTI_NETWORK
            value: "true"
  values:
    global:
      meshID: mesh1
      multiCluster:
        clusterName: cluster1
      network: network1
EOF
{{< /text >}}

将配置应用到 `cluster1`：

{{< text bash >}}
$ istioctl install --context="${CTX_CLUSTER1}" -f cluster1.yaml
{{< /text >}}

{{< /tab >}}
{{< tab name="Helm" category-value="helm" >}}

使用以下 Helm 命令在 `cluster1` 中将 Istio 安装为主集群：

在 `cluster1` 中安装 `base` Chart：

{{< text bash >}}
$ helm install istio-base istio/base -n istio-system --kube-context "${CTX_CLUSTER1}"
{{< /text >}}

然后，使用以下多集群设置在 `cluster1` 中安装 `istiod` Chart：

{{< text bash >}}
$ helm install istiod istio/istiod -n istio-system --kube-context "${CTX_CLUSTER1}" --set global.meshID=mesh1 --set global.multiCluster.clusterName=cluster1 --set global.network=network1 --set profile=ambient --set env.AMBIENT_ENABLE_MULTI_NETWORK="true"
{{< /text >}}

接下来，在 Ambient 模式下安装 CNI 节点代理：

{{< text syntax=bash snip_id=install_cni_cluster1 >}}
$ helm install istio-cni istio/cni -n istio-system --kube-context "${CTX_CLUSTER1}" --set profile=ambient
{{< /text >}}

最后，安装 ztunnel 数据平面：

{{< text syntax=bash snip_id=install_ztunnel_cluster1 >}}
$ helm install ztunnel istio/ztunnel -n istio-system --kube-context "${CTX_CLUSTER1}" --set multiCluster.clusterName=cluster1 --set global.network=network1
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

## 在 `cluster1` 中安装 Ambient 东西向网关 {#install-an-ambient-east-west-gateway-in-cluster1}

在 `cluster1` 中安装一个专用于 Ambient [东西向](https://en.wikipedia.org/wiki/East-west_traffic)流量的网关。
请注意，根据您的 Kubernetes 环境，此网关可能默认部署在公共互联网上。
生产系统可能需要额外的访问限制（例如通过防火墙规则）来防止外部攻击。
请咨询您的云供应商，了解有哪些可用的选项。

{{< tabset category-name="east-west-gateway-install-type-cluster-1" >}}

{{< tab name="IstioOperator" category-value="iop" >}}

{{< text bash >}}
$ @samples/multicluster/gen-eastwest-gateway.sh@ \
    --network network1 \
    --ambient | \
    kubectl --context="${CTX_CLUSTER1}" apply -f -
{{< /text >}}

{{< warning >}}
如果控制平面安装了修订版，请将 `--revision rev` 标志添加到 `gen-eastwest-gateway.sh` 命令中。
{{< /warning >}}

{{< /tab >}}
{{< tab name="Kubectl apply" category-value="helm" >}}

使用以下网关定义在 `cluster1` 中安装东西向网关：

{{< text bash >}}
$ cat <<EOF > cluster1-ewgateway.yaml
kind: Gateway
apiVersion: gateway.networking.k8s.io/v1
metadata:
  name: istio-eastwestgateway
  namespace: istio-system
  labels:
    topology.istio.io/network: "network1"
spec:
  gatewayClassName: istio-east-west
  listeners:
  - name: mesh
    port: 15008
    protocol: HBONE
    tls:
      mode: Terminate # represents double-HBONE
      options:
        gateway.istio.io/tls-terminate-mode: ISTIO_MUTUAL
EOF
{{< /text >}}

{{< warning >}}
如果您正在运行 istiod 的修订实例，并且没有设置默认修订或标签，
则可能需要将 `istio.io/rev` 标签添加到此 `Gateway` 清单中。
{{< /warning >}}

将配置应用到 `cluster1`：

{{< text bash >}}
$ kubectl apply --context="${CTX_CLUSTER1}" -f cluster1-ewgateway.yaml
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

等待东西向网关分配外部 IP 地址：

{{< text bash >}}
$ kubectl --context="${CTX_CLUSTER1}" get svc istio-eastwestgateway -n istio-system
NAME                    TYPE           CLUSTER-IP    EXTERNAL-IP    PORT(S)   AGE
istio-eastwestgateway   LoadBalancer   10.80.6.124   34.75.71.237   ...       51s
{{< /text >}}

## 设置 `cluster2` 的默认网络 {#set-the-default-network-for-cluster2}

如果 istio-system 命名空间已经创建，我们需要在那里设置集群的网络：

{{< text bash >}}
$ kubectl --context="${CTX_CLUSTER2}" get namespace istio-system && \
  kubectl --context="${CTX_CLUSTER2}" label namespace istio-system topology.istio.io/network=network2
{{< /text >}}

## 将 cluster2 配置为主集群 {#configure-cluster2-as-a-primary}

为 `cluster2` 创建 `istioctl` 配置：

{{< tabset category-name="multicluster-install-type-cluster-2" >}}

{{< tab name="IstioOperator" category-value="iop" >}}

使用 istioctl 和 `IstioOperator` API 在 `cluster2` 中将 Istio 安装为主集群。

{{< text bash >}}
$ cat <<EOF > cluster2.yaml
apiVersion: insall.istio.io/v1alpha1
kind: IstioOperator
spec:
  profile: ambient
  components:
    pilot:
      k8s:
        env:
          - name: AMBIENT_ENABLE_MULTI_NETWORK
            value: "true"
  values:
    global:
      meshID: mesh1
      multiCluster:
        clusterName: cluster2
      network: network2
EOF
{{< /text >}}

将配置应用到 `cluster2`：

{{< text bash >}}
$ istioctl install --context="${CTX_CLUSTER2}" -f cluster2.yaml
{{< /text >}}

{{< /tab >}}
{{< tab name="Helm" category-value="helm" >}}

使用以下 Helm 命令在 `cluster2` 中将 Istio 安装为主集群：

在 `cluster2` 中安装 `base` Chart：

{{< text bash >}}
$ helm install istio-base istio/base -n istio-system --kube-context "${CTX_CLUSTER2}"
{{< /text >}}

然后，使用以下多集群设置在 `cluster2` 中安装 `istiod` Chart：

{{< text bash >}}
$ helm install istiod istio/istiod -n istio-system --kube-context "${CTX_CLUSTER2}" --set global.meshID=mesh1 --set global.multiCluster.clusterName=cluster2 --set global.network=network2 --set profile=ambient --set env.AMBIENT_ENABLE_MULTI_NETWORK="true"
{{< /text >}}

接下来，在 Ambient 模式下安装 CNI 节点代理：

{{< text syntax=bash snip_id=install_cni_cluster2 >}}
$ helm install istio-cni istio/cni -n istio-system --kube-context "${CTX_CLUSTER2}" --set profile=ambient
{{< /text >}}

最后，安装 ztunnel 数据平面：

{{< text syntax=bash snip_id=install_ztunnel_cluster2 >}}
$ helm install ztunnel istio/ztunnel -n istio-system --kube-context "${CTX_CLUSTER2}"  --set multiCluster.clusterName=cluster2 --set global.network=network2
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

## 在 `cluster2` 中安装环境东西向网关 {#install-an-ambient-east-west-gateway-in-cluster2}

正如我们上面的 `cluster1` 中所做的那样，在 `cluster2` 中安装一个专用于东西向流量的网关。

{{< tabset category-name="east-west-gateway-install-type-cluster-2" >}}

{{< tab name="IstioOperator" category-value="iop" >}}

{{< text bash >}}
$ @samples/multicluster/gen-eastwest-gateway.sh@ \
    --network network2 \
    --ambient | \
    kubectl apply --context="${CTX_CLUSTER2}" -f -
{{< /text >}}

{{< /tab >}}
{{< tab name="Kubectl apply" category-value="helm" >}}

使用以下网关定义在 `cluster2` 中安装东西向网关：

{{< text bash >}}
$ cat <<EOF > cluster2-ewgateway.yaml
kind: Gateway
apiVersion: gateway.networking.k8s.io/v1
metadata:
  name: istio-eastwestgateway
  namespace: istio-system
  labels:
    topology.istio.io/network: "network2"
spec:
  gatewayClassName: istio-east-west
  listeners:
  - name: mesh
    port: 15008
    protocol: HBONE
    tls:
      mode: Terminate # represents double-HBONE
      options:
        gateway.istio.io/tls-terminate-mode: ISTIO_MUTUAL
EOF
{{< /text >}}

{{< warning >}}
如果您正在运行 istiod 的修订实例，并且没有设置默认修订或标签，
则可能需要将 `istio.io/rev` 标签添加到此 `Gateway` 清单中。
{{< /warning >}}

将配置应用到 `cluster2`：

{{< text bash >}}
$ kubectl apply --context="${CTX_CLUSTER2}" -f cluster2-ewgateway.yaml
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

等待东西向网关分配外部 IP 地址：

{{< text bash >}}
$ kubectl --context="${CTX_CLUSTER2}" get svc istio-eastwestgateway -n istio-system
NAME                    TYPE           CLUSTER-IP    EXTERNAL-IP    PORT(S)   AGE
istio-eastwestgateway   LoadBalancer   10.0.12.121   34.122.91.98   ...       51s
{{< /text >}}

## 启用端点发现 {#enable-endpoint-discovery}

在 `cluster2` 中安装一个远程密钥，以提供对 `cluster1` 的 API 服务器的访问。

{{< text bash >}}
$ istioctl create-remote-secret \
  --context="${CTX_CLUSTER1}" \
  --name=cluster1 | \
  kubectl apply -f - --context="${CTX_CLUSTER2}"
{{< /text >}}

在 `cluster1` 中安装一个远程密钥，以提供对 `cluster2` 的 API 服务器的访问。

{{< text bash >}}
$ istioctl create-remote-secret \
  --context="${CTX_CLUSTER2}" \
  --name=cluster2 | \
  kubectl apply -f - --context="${CTX_CLUSTER1}"
{{< /text >}}

**恭喜！**您已成功在不同网络上的多个主集群上安装 Istio 网格！

## 下一步 {#next-steps}

您现在可以[验证安装](/zh/docs/ambient/install/multicluster/verify)。

## 清理 {#cleanup}

使用与安装 Istio 相同的机制（istioctl 或 Helm）从 `cluster1` 和 `cluster2` 中卸载 Istio。

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
$ helm delete ztunnel -n istio-system --kube-context "${CTX_CLUSTER1}"
$ helm delete istio-cni -n istio-system --kube-context "${CTX_CLUSTER1}"
$ helm delete istiod -n istio-system --kube-context "${CTX_CLUSTER1}"
$ helm delete istio-base -n istio-system --kube-context "${CTX_CLUSTER1}"
{{< /text >}}

从 `cluster1` 中删除 `istio-system` 命名空间：

{{< text syntax=bash >}}
$ kubectl delete ns istio-system --context="${CTX_CLUSTER1}"
{{< /text >}}

从 `cluster1` 中删除 Istio Helm 安装：

{{< text syntax=bash >}}
$ helm delete ztunnel -n istio-system --kube-context "${CTX_CLUSTER2}"
$ helm delete istio-cni -n istio-system --kube-context "${CTX_CLUSTER2}"
$ helm delete istiod -n istio-system --kube-context "${CTX_CLUSTER2}"
$ helm delete istio-base -n istio-system --kube-context "${CTX_CLUSTER2}"
{{< /text >}}

从 `cluster2` 中删除 `istio-system` 命名空间：

{{< text syntax=bash >}}
$ kubectl delete ns istio-system --context="${CTX_CLUSTER2}"
{{< /text >}}

(Optional) Delete CRDs installed by Istio:
（可选）删除 Istio 安装的 CRD：

删除 CRD 会永久移除您在集群中创建的所有 Istio 资源。
要删除集群中已安装的 Istio CRD，请执行以下操作：

{{< text syntax=bash snip_id=delete_crds >}}
$ kubectl get crd -oname --context "${CTX_CLUSTER1}" | grep --color=never 'istio.io' | xargs kubectl delete --context "${CTX_CLUSTER1}"
$ kubectl get crd -oname --context "${CTX_CLUSTER2}" | grep --color=never 'istio.io' | xargs kubectl delete --context "${CTX_CLUSTER2}"
{{< /text >}}

最后，清理 Gateway API CRD：

{{< text syntax=bash snip_id=delete_gateway_crds >}}
$ kubectl get crd -oname --context "${CTX_CLUSTER1}" | grep --color=never 'gateway.networking.k8s.io' | xargs kubectl delete --context "${CTX_CLUSTER1}"
$ kubectl get crd -oname --context "${CTX_CLUSTER2}" | grep --color=never 'gateway.networking.k8s.io' | xargs kubectl delete --context "${CTX_CLUSTER2}"
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}
