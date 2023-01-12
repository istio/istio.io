---
title: 华为云
description: 为 Istio 设置一个华为云 Kubernetes 集群的操作说明。
weight: 23
skip_seealso: true
aliases:
    - /zh/docs/setup/kubernetes/prepare/platform-setup/huaweicloud/
    - /zh/docs/setup/kubernetes/platform-setup/huaweicloud/
keywords: [platform-setup,huawei,huaweicloud,cce]
owner: istio/wg-environments-maintainers
test: no
---

遵循以下说明配置[华为云容器引擎 CCE](https://www.huaweicloud.com/intl/zh-cn/product/cce.html) 集群以便安装运行 Istio。您可以在华为云的`云容器引擎控制台`中快速简单地部署一个完全支持 Istio 的 Kubernetes 集群。

{{< tip >}}
华为提供了一个{{< gloss >}}managed control plane{{< /gloss >}}插件用于华为云容器引擎 CCE，您可以使用这个插件来代替手动安装 Istio。有关详细信息和操作说明，请参阅[华为应用服务网格](https://support.huaweicloud.com/asm/index.html)。
{{< /tip >}}

遵循[华为云操作说明](https://support.huaweicloud.com/qs-cce/cce_qs_0008.html)准备一个集群，然后继续以下步骤手动安装 Istio：

1.  登录到 CCE 控制台。选择 **Dashboard** > **购买集群**打开**购买混合集群**页面。打开此页面的另一个方法是在导航窗格中选择**资源管理** > **集群**，然后点击**混合集群**旁边的**购买**。

1.  在**配置集群**页面上，配置集群参数。在以下示例中，大多数参数保留默认值。集群配置完成后，点击**下一步**。**创建节点**以转到节点创建页面。

    {{< tip >}}
    Istio 对 Kubernetes 版本有一些要求，请根据 Istio 的[支持策略](/zh/docs/releases/supported-releases#support-status-of-istio-releases)选择版本。
    {{< /tip >}}

    下图显示了您创建和配置集群的 GUI：

    {{< image link="./create-cluster.png" caption="配置集群" >}}

1.  在节点创建页面上，配置以下参数。

    {{< tip >}}
    Istio 凭借经验增加了一些附加的资源耗用量，起步保留至少 4 个 vCPU 和 8 GB 内存。
    {{< /tip >}}

    下图显示了您创建和配置节点的 GUI：

    {{< image link="./create-node.png" caption="配置节点" >}}

1.  [配置 kubectl](https://support.huaweicloud.com/intl/zh-cn/cce_faq/cce_faq_00041.html)

1.  现在您可以遵照[安装指南](/zh/docs/setup/install)在 CCE 集群上安装 Istio。

1.  配置 [ELB](https://support.huaweicloud.com/intl/productdesc-elb/en-us_topic_0015479966.html) 以暴露 Istio 入口网关（如果需要）。

    - [创建弹性负载均衡器](https://console.huaweicloud.com/vpc/?region=ap-southeast-1#/elbs/createEnhanceElb)

    - 绑定 ELB 实例到 `istio-ingressgateway` 服务

      将 ELB 实例 ID 和 `loadBalancerIP` 设为 `istio-ingressgateway`。

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  annotations:
    kubernetes.io/elb.class: union
    kubernetes.io/elb.id: 4ee43d2b-cec5-4100-89eb-2f77837daa63 # ELB ID
    kubernetes.io/elb.lb-algorithm: ROUND_ROBIN
  labels:
    app: istio-ingressgateway
    install.operator.istio.io/owning-resource: unknown
    install.operator.istio.io/owning-resource-namespace: istio-system
    istio: ingressgateway
    istio.io/rev: default
    operator.istio.io/component: IngressGateways
    operator.istio.io/managed: Reconcile
    operator.istio.io/version: 1.9.0
    release: istio
  name: istio-ingressgateway
  namespace: istio-system
spec:
  clusterIP: 10.247.7.192
  externalTrafficPolicy: Cluster
  loadBalancerIP: 119.8.36.132     ## ELB EIP
  ports:
  - name: status-port
    nodePort: 32484
    port: 15021
    protocol: TCP
    targetPort: 15021
  - name: http2
    nodePort: 30294
    port: 80
    protocol: TCP
    targetPort: 8080
  - name: https
    nodePort: 31301
    port: 443
    protocol: TCP
    targetPort: 8443
  - name: tcp
    nodePort: 30229
    port: 31400
    protocol: TCP
    targetPort: 31400
  - name: tls
    nodePort: 32028
    port: 15443
    protocol: TCP
    targetPort: 15443
  selector:
    app: istio-ingressgateway
    istio: ingressgateway
  sessionAffinity: None
  type: LoadBalancer
EOF
{{< /text >}}

通过尝试完成各种[任务](/zh/docs/tasks)开始使用 Istio。
