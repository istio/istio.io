---
title: Huawei Cloud
description: Instructions to set up an Huawei Cloud kubernetes cluster for Istio.
weight: 23
skip_seealso: true
aliases:
    - /docs/setup/kubernetes/prepare/platform-setup/huaweicloud/
    - /docs/setup/kubernetes/platform-setup/huaweicloud/
keywords: [platform-setup,huawei,huaweicloud,cce]
owner: istio/wg-environments-maintainers
test: no
---

Follow these instructions to prepare a cluster for Istio using the
[Huawei Cloud Container Engine](https://www.huaweicloud.com/intl/product/cce.html).
You can deploy a Kubernetes cluster to Huawei Cloud quickly and easily in the
`Cloud Container Engine Console`, which fully supports Istio.

{{< tip >}}
Huawei offers a {{< gloss >}}managed control plane{{< /gloss >}} add-on for the Huawei Cloud Container Engine,
which you can use instead of installing Istio manually.
Refer to [Huawei Application Service Mesh](https://support.huaweicloud.com/asm/index.html)
for details and instructions.
{{< /tip >}}

Following the [Huawei Cloud Instructions](https://support.huaweicloud.com/en-us/qs-cce/cce_qs_0008.html) to prepare a cluster before manually installing Istio, proceed as follows:

1.  Log in to the CCE console. Choose **Dashboard** > **Buy Cluster** to open the **Buy Hybrid Cluster** page. An alternative way to open that page is to choose **Resource Management** > **Clusters** in the navigation pane and click **Buy** next to **Hybrid Cluster**.

1.  On the **Configure Cluster** page, configure cluster parameters.
    In this example, a majority of parameters retain default values. After the cluster configuration is complete, click Next: **Create Node** to go to the node creation page.

    {{< tip >}}
    Istio release has some requirements for the Kubernetes version,
    select the version according to Istio's [support policy](/docs/releases/supported-releases#support-status-of-istio-releases).
    {{< /tip >}}

    The image below shows the GUI where you create and configure the cluster:

    {{< image link="./create-cluster.png" caption="Configure Cluster" >}}

1.  On the node creation page, configure the following parameters

    {{< tip >}}
    Istio adds some additional resource consumption,
    from our experience, reserve at least 4 vCPU and 8 GB memory to begin playing.
    {{< /tip >}}

    The image below shows the GUI where you create and configure the node:

    {{< image link="./create-node.png" caption="Configure Node" >}}

1.  [Configure kubectl](https://support.huaweicloud.com/intl/en-us/cce_faq/cce_faq_00041.html)

1.  Now you can install Istio on CCE cluster according to [install guide](/docs/setup/install).

1.  Configure [ELB](https://support.huaweicloud.com/intl/productdesc-elb/en-us_topic_0015479966.html) to expose Istio ingress gateway if needed.

    - [Create Elastic Load Balancer](https://console.huaweicloud.com/vpc/?region=ap-southeast-1#/elbs/createEnhanceElb)

    - Bind the ELB instance to `istio-ingressgateway` service

      Set the ELB instance ID and `loadBalancerIP` to `istio-ingressgateway`.

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

Start playing with Istio by trying out the various [tasks](/docs/tasks).
