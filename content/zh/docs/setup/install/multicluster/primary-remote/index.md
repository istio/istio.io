---
title: 主-从架构的安装
description: 跨主-从集群，安装 Istio 网格。
weight: 20
icon: setup
keywords: [kubernetes,multicluster]
test: yes
owner: istio/wg-environments-maintainers
---
按照本指南，在 `cluster1` 主集群（{{< gloss >}}primary cluster{{< /gloss >}}） 安装 Istio 控制平面，
并设置 `cluster2` 从集群（{{< gloss >}}remote cluster{{< /gloss >}}）指向 `cluster1` 的控制平面。
两个集群都运行在 `network1` 网络上，所以两个集群的 Pod 之间，网络可直接连通。

继续安装之前，请先确认完成了[准备工作](/zh/docs/setup/install/multicluster/before-you-begin)中的步骤。

在此配置中，集群 `cluster1` 将监测两个集群 API 服务器的服务端点。
以这种方式，控制平面就能为两个集群中的工作负载提供服务发现。

服务的工作负载（pod 到 pod）可跨集群边界直接通讯。

`cluster2` 中的服务将通过专用的[东西向](https://en.wikipedia.org/wiki/East-west_traffic)网关
访问 `cluster1` 的控制平面。

{{< image width="75%"
    link="arch.svg"
    caption="Primary and remote clusters on the same network"
    >}}

{{< tip >}}
目前，从集群配置档在从集群安装 Istio 服务器，该服务器用来为集群中的工作负载注入 CA 和 webhook。
但是，服务发现会访问主集群的控制平面。

后续版本将完全消除在从集群中安装 Istiod 的需求。请保持关注！
{{< /tip >}}

## 将 `cluster1` 设为主集群 {#configure-cluster1-as-a-primary}

为 `cluster1` 创建 Istio 配置文件：

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

## 在 `cluster1` 安装东西向网关 {#install-the-east-west-gateway-in-cluster1}

在 `cluster1` 中安装东西向流量专用网关，默认情况下，此网关将被公开到互联网上。
生产系统可能需要增加额外的准入限制（即：通过防火墙规则）来防止外部攻击。
咨询你的云供应商，了解可用的选项。

{{< text bash >}}
$ @samples/multicluster/gen-eastwest-gateway.sh@ \
    --mesh mesh1 --cluster cluster1 --network network1 | \
    istioctl --context="${CTX_CLUSTER1}" install -y -f -
{{< /text >}}

等待东西向网关获取外部 IP 地址：

{{< text bash >}}
$ kubectl --context="${CTX_CLUSTER1}" get svc istio-eastwestgateway -n istio-system
NAME                    TYPE           CLUSTER-IP    EXTERNAL-IP    PORT(S)   AGE
istio-eastwestgateway   LoadBalancer   10.80.6.124   34.75.71.237   ...       51s
{{< /text >}}

## 在 `cluster1` 中开放控制平面 {#expose-the-control-plane-in-cluster1}

在安装 `cluster2` 之前，我们需要开放 `cluster1` 的控制平面，
以便 `cluster2` 中的服务能访问到服务发现：

{{< text bash >}}
$ kubectl apply --context="${CTX_CLUSTER1}" -f \
    @samples/multicluster/expose-istiod.yaml@
{{< /text >}}

## 配置 API 服务器到 `cluster2` 的访问 {#enable-access-to-cluster2}

在配置从集群之前，我们必须先授予 `cluster1` 控制平面到 `cluster2` API 服务器的访问权限。
这将执行以下操作：

- 开启控制平面的身份认证功能，以验证 `cluster2` 中工作负载的连接请求。如果没有 API 服务器的访问权限，控制平面将会拒绝该请求。

- 在 `cluster2` 中启用服务发现的服务端点。

要提供到 `cluster2` API 服务器的访问，我们要生成一个从集群的 secret，并把它应用到 `cluster1`。

{{< text bash >}}
$ istioctl x create-remote-secret \
    --context="${CTX_CLUSTER2}" \
    --name=cluster2 | \
    kubectl apply -f - --context="${CTX_CLUSTER1}"
{{< /text >}}

## 将 `cluster2` 设为从集群 {#configure-cluster2-as-a-remote}

保存 `cluster1` 东西向网关的地址。

{{< text bash >}}
$ export DISCOVERY_ADDRESS=$(kubectl \
    --context="${CTX_CLUSTER1}" \
    -n istio-system get svc istio-eastwestgateway \
    -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
{{< /text >}}

现在，为 `cluster2` 创建一个从集群配置：

{{< text bash >}}
$ cat <<EOF > cluster2.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  profile: remote
  values:
    global:
      meshID: mesh1
      multiCluster:
        clusterName: cluster2
      network: network1
      remotePilotAddress: ${DISCOVERY_ADDRESS}
EOF
{{< /text >}}

将此配置应用到 `cluster2`

{{< text bash >}}
$ istioctl install --context="${CTX_CLUSTER2}" -f cluster2.yaml
{{< /text >}}

**恭喜!** 你已经成功地安装了跨主-从集群的 Istio 网格！

## 后续步骤 {#next-steps}

现在，你可以[验证此次安装](/zh/docs/setup/install/multicluster/verify).
