---
title: 使用外部控制平面安装 Istio
description: 安装外部控制平面和远程集群。
weight: 80
keywords: [external,control,istiod,remote]
owner: istio/wg-environments-maintainers
test: yes
---

本指南将引导您完成安装 {{< gloss "external control plane">}}外部控制平面{{< /gloss >}}，然后将一个或多个 {{< gloss "remote cluster" >}}远程集群{{< /gloss >}} 连接到该平面的过程。

外部控制平面[部署模型](/zh/docs/ops/deployment/deployment-models/#control-plane-models)允许网格操作员在与组成网格的数据平面集群（或多个集群）分开的外部集群上安装和管理控制平面。 这种部署模型可以将网状网络运营商和网状网络管理员明确区分。 网格操作员可以安装和管理 Istio 控制平面，而网格管理员只需配置网格即可。

{{< image width="75%"
    link="external-controlplane.svg"
    caption="外部控制平面集群和远程集群"
    >}}

在远程集群中运行的 Envoy 代理（边车和网关）通过 Ingress 网关访问外部 Istiod，向外暴露了需要被发现，CA，注入和验证的端点。

虽然外部控制平面的配置和管理是由外部集群中的网格操作员完成的，但连接到外部控制平面的第一个远程集群充当了网格本身的配置集群。除了网状服务本身之外，网格管理员还将使用配置集群来配置网状资源（网关，虚拟服务等）。外部控制平面将从 Kubernetes API Server 远程访问此配置，如上图所示。

## 准备开始{#before-you-begin}

### 集群{#clusters}

本指南要求您有任意两个受支持版本的 Kubernetes 集群：{{< supported_kubernetes_versions >}}。

第一个集群将托管安装在 `external-istiod` 命名空间中的 {{< gloss "external control plane">}}外部控制平面{{< /gloss >}}。 Ingress 网关也安装在 `istio-system` 命名空间中，以提供对外部控制平面的跨集群访问。

第二个集群是将运行网格应用程序工作负载的 {{< gloss "remote cluster">}}远程集群{{< /gloss >}}。 它的 Kubernetes API Server 还提供了外部控制平面（Istiod）用来配置工作负载代理的网状配置。

### API Server 访问{#API-server-access}

外部控制平面集群必须可以访问远程集群中的 Kubernetes API Server。 许多云提供商通过网络负载平衡器（NLB）公开访问 API Server。 如果无法直接访问 API Server，则需要修改安装过程以启用访问权限。 例如，在[多集群配置](#adding-clusters)中使用的[东西向](https://en.wikipedia.org/wiki/East-west_traffic)网关也可以用于启用对 API Server 的访问。

### 环境变量{#environment-variables}

以下环境变量将始终用于简化说明：

变量名称 | 描述
-------- | -----------
`CTX_EXTERNAL_CLUSTER` | 默认 [Kubernetes配置文件](https://kubernetes.io/zh/docs/tasks/access-application-cluster/configure-access-multiple-clusters/)中的上下文名称，用于访问外部控制平面集群。
`CTX_REMOTE_CLUSTER` | 默认 [Kubernetes配置文件](https://kubernetes.io/zh/docs/tasks/access-application-cluster/configure-access-multiple-clusters/)中的上下文名称，用于访问远程集群。
`REMOTE_CLUSTER_NAME` | 远程集群的名称。
`EXTERNAL_ISTIOD_ADDR` | 外部控制平面集群上的 Ingress 网关的主机名。 远程集群使用它来访问外部控制平面。
`SSL_SECRET_NAME` | 拥有外部控制平面集群上 Ingress 网关的 TLS 证书的密钥名称。

立即设置 `CTX_EXTERNAL_CLUSTER`，`CTX_REMOTE_CLUSTER` 和 `REMOTE_CLUSTER_NAME`。 稍后将设置其他变量。

{{< text syntax=bash snip_id=none >}}
$ export CTX_EXTERNAL_CLUSTER=<your external cluster context>
$ export CTX_REMOTE_CLUSTER=<your remote cluster context>
$ export REMOTE_CLUSTER_NAME=<your remote cluster name>
{{< /text >}}

## 集群配置{#cluster-configuration}

### 网格操作步骤{#mesh-operator-steps}

网格操作员负责在外部集群上安装和管理外部 Istio 控制平面。 这包括在外部集群上配置 Ingress 网关，允许远程集群访问控制平面，并在远程集群上安装所需的 Webhook，Configmap 和 Secret，以便使用外部控制平面。

#### 在外部集群中搭建网关{#set-up-a-gateway-in-the-external-cluster}

1. 为 Ingress 网关创建 Istio 安装配置，该配置会将外部控制平面端口暴露给其他集群：

    {{< text bash >}}
    $ cat <<EOF > controlplane-gateway.yaml
    apiVersion: install.istio.io/v1alpha1
    kind: IstioOperator
    metadata:
      namespace: istio-system
    spec:
      components:
        ingressGateways:
          - name: istio-ingressgateway
            enabled: true
            k8s:
              service:
                ports:
                  - port: 15021
                    targetPort: 15021
                    name: status-port
                  - port: 15012
                    targetPort: 15012
                    name: tls-xds
                  - port: 15017
                    targetPort: 15017
                    name: tls-webhook
    EOF
    {{< /text >}}

    然后，将网关安装在外部集群的 `istio-system` 命名空间中：

    {{< text bash >}}
    $ istioctl install -f controlplane-gateway.yaml --context="${CTX_EXTERNAL_CLUSTER}"
    {{< /text >}}

1. 运行以下命令来确认 Ingress 网关已启动并正在运行：

    {{< text bash >}}
    $ kubectl get po -n istio-system --context="${CTX_EXTERNAL_CLUSTER}"
    NAME                                   READY   STATUS    RESTARTS   AGE
    istio-ingressgateway-9d4c7f5c7-7qpzz   1/1     Running   0          29s
    istiod-68488cd797-mq8dn                1/1     Running   0          38s
    {{< /text >}}

    您会注意到在 `istio-system` 命名空间中也创建了一个 Istiod 部署。 这用于配置 Ingress 网关，而不是远程集群使用的控制平面。

    {{< tip >}}
    可以将 Ingress 网关配置为在外部集群上的不同命名空间中承载多个外部控制平面，尽管在本示例中，您将仅在 `external-istiod` 命名空间中部署一个外部 Istiod。
    {{< /tip >}}

1. 使用带有 TLS 的公共主机名配置您的环境来暴露 Istio Ingress 网关服务。 将 `EXTERNAL_ISTIOD_ADDR` 环境变量设置为主机名，将 `SSL_SECRET_NAME` 环境变量设置为包含 TLS 证书的密钥：

    {{< text syntax=bash snip_id=none >}}
    $ export EXTERNAL_ISTIOD_ADDR=<your external istiod host>
    $ export SSL_SECRET_NAME=<your external istiod secret>
    {{< /text >}}

#### 在外部集群中安装控制平面{#set-up-the-control-plane-in-the-external-cluster}

1. 创建 `external-istiod` 命名空间，该命名空间将用于托管外部控制平面：

    {{< text bash >}}
    $ kubectl create namespace external-istiod --context="${CTX_EXTERNAL_CLUSTER}"
    {{< /text >}}

1. 外部集群中的控制平面需要访问远程集群以发现服务，端点和 Pod 属性。 创建具有凭据的 Secret，以访问远程集群的 `kube-apiserver` 并将其安装在外部集群中：

    {{< text bash >}}
    $ kubectl create sa istiod-service-account -n external-istiod --context="${CTX_EXTERNAL_CLUSTER}"
    $ istioctl x create-remote-secret \
      --context="${CTX_REMOTE_CLUSTER}" \
      --type=config \
      --namespace=external-istiod | \
      kubectl apply -f - --context="${CTX_EXTERNAL_CLUSTER}"
    {{< /text >}}

1. 创建 Istio 配置以将控制平面安装在外部集群的 `external-istiod` 命名空间中：

    {{< text syntax=bash snip_id=get_external_istiod_iop >}}
    $ cat <<EOF > external-istiod.yaml
    apiVersion: install.istio.io/v1alpha1
    kind: IstioOperator
    metadata:
      namespace: external-istiod
    spec:
      meshConfig:
        rootNamespace: external-istiod
        defaultConfig:
          discoveryAddress: $EXTERNAL_ISTIOD_ADDR:15012
          proxyMetadata:
            XDS_ROOT_CA: /etc/ssl/certs/ca-certificates.crt
            CA_ROOT_CA: /etc/ssl/certs/ca-certificates.crt
      components:
        base:
          enabled: false
        ingressGateways:
        - name: istio-ingressgateway
          enabled: false
      values:
        global:
          caAddress: $EXTERNAL_ISTIOD_ADDR:15012
          istioNamespace: external-istiod
          operatorManageWebhooks: true
          meshID: mesh1
          multiCluster:
            clusterName: $REMOTE_CLUSTER_NAME
        pilot:
          env:
            INJECTION_WEBHOOK_CONFIG_NAME: ""
            VALIDATION_WEBHOOK_CONFIG_NAME: ""
    EOF
    {{< /text >}}

    然后，在外部集群上应用 Istio 配置：

    {{< text bash >}}
    $ istioctl install -f external-istiod.yaml --context="${CTX_EXTERNAL_CLUSTER}"
    {{< /text >}}

1. 确认外部 Istiod 已成功部署：

    {{< text bash >}}
    $ kubectl get po -n external-istiod --context="${CTX_EXTERNAL_CLUSTER}"
    NAME                      READY   STATUS    RESTARTS   AGE
    istiod-779bd6fdcf-bd6rg   1/1     Running   0          70s
    {{< /text >}}

1. 创建 Istio `Gateway`，`VirtualService` 和 `DestinationRule` 配置，将流量从 Ingress 网关路由到外部控制平面：

    {{< text syntax=bash snip_id=get_external_istiod_gateway_config >}}
    $ cat <<EOF > external-istiod-gw.yaml
    apiVersion: networking.istio.io/v1beta1
    kind: Gateway
    metadata:
      name: external-istiod-gw
      namespace: external-istiod
    spec:
      selector:
        istio: ingressgateway
      servers:
        - port:
            number: 15012
            protocol: https
            name: https-XDS
          tls:
            mode: SIMPLE
            credentialName: $SSL_SECRET_NAME
          hosts:
          - $EXTERNAL_ISTIOD_ADDR
        - port:
            number: 15017
            protocol: https
            name: https-WEBHOOK
          tls:
            mode: SIMPLE
            credentialName: $SSL_SECRET_NAME
          hosts:
          - $EXTERNAL_ISTIOD_ADDR
    ---
    apiVersion: networking.istio.io/v1beta1
    kind: VirtualService
    metadata:
       name: external-istiod-vs
       namespace: external-istiod
    spec:
        hosts:
        - $EXTERNAL_ISTIOD_ADDR
        gateways:
        - external-istiod-gw
        http:
        - match:
          - port: 15012
          route:
          - destination:
              host: istiod.external-istiod.svc.cluster.local
              port:
                number: 15012
        - match:
          - port: 15017
          route:
          - destination:
              host: istiod.external-istiod.svc.cluster.local
              port:
                number: 443
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: DestinationRule
    metadata:
      name: external-istiod-dr
      namespace: external-istiod
    spec:
      host: istiod.external-istiod.svc.cluster.local
      trafficPolicy:
        portLevelSettings:
        - port:
            number: 15012
          tls:
            mode: SIMPLE
          connectionPool:
            http:
              h2UpgradePolicy: UPGRADE
        - port:
            number: 443
          tls:
            mode: SIMPLE
    EOF
    {{< /text >}}

    然后，在外部集群上应用配置：

    {{< text bash >}}
    $ kubectl apply -f external-istiod-gw.yaml --context="${CTX_EXTERNAL_CLUSTER}"
    {{< /text >}}

#### 设置远程集群{#set-up-the-remote-cluster}

1. 创建远程 Istio 安装配置，使用外部控制平面而不是在本地部署控制平面来安装 Webhook，Configmap 和 Secret：

    {{< text syntax=bash snip_id=get_remote_config_cluster_iop >}}
    $ cat <<EOF > remote-config-cluster.yaml
    apiVersion: install.istio.io/v1alpha1
    kind: IstioOperator
    metadata:
     namespace: external-istiod
    spec:
      profile: remote
      meshConfig:
        rootNamespace: external-istiod
        defaultConfig:
          discoveryAddress: $EXTERNAL_ISTIOD_ADDR:15012
          proxyMetadata:
            XDS_ROOT_CA: /etc/ssl/certs/ca-certificates.crt
            CA_ROOT_CA: /etc/ssl/certs/ca-certificates.crt
      components:
        pilot:
          enabled: false
        ingressGateways:
        - name: istio-ingressgateway
          enabled: false
        istiodRemote:
          enabled: true
      values:
        global:
          caAddress: $EXTERNAL_ISTIOD_ADDR:15012
          istioNamespace: external-istiod
          meshID: mesh1
          multiCluster:
            clusterName: $REMOTE_CLUSTER_NAME
        istiodRemote:
          injectionURL: https://$EXTERNAL_ISTIOD_ADDR:15017/inject
        base:
          validationURL: https://$EXTERNAL_ISTIOD_ADDR:15017/validate
    EOF
    {{< /text >}}

    然后，在远程集群上安装配置：

    {{< text bash >}}
    $ istioctl manifest generate -f remote-config-cluster.yaml | kubectl apply --context="${CTX_REMOTE_CLUSTER}" -f -
    {{< /text >}}

1. 确认远程集群已安装 Webhook，Secret 和 Configmap：

    {{< text bash >}}
    $ kubectl get mutatingwebhookconfiguration -n external-istiod --context="${CTX_REMOTE_CLUSTER}"
    NAME                                     WEBHOOKS   AGE
    istio-sidecar-injector-external-istiod   4          6m24s
    {{< /text >}}

    {{< text bash >}}
    $ kubectl get validatingwebhookconfiguration -n external-istiod --context="${CTX_REMOTE_CLUSTER}"
    NAME                     WEBHOOKS   AGE
    istiod-external-istiod   1          6m32s
    {{< /text >}}

    {{< text bash >}}
    $ kubectl get configmaps -n external-istiod --context="${CTX_REMOTE_CLUSTER}"
    NAME                                   DATA   AGE
    istio                                  2      2m1s
    istio-ca-root-cert                     1      2m9s
    istio-leader                           0      2m9s
    istio-namespace-controller-election    0      2m11s
    istio-sidecar-injector                 2      2m1s
    istio-validation-controller-election   0      2m9s
    {{< /text >}}

    {{< text bash >}}
    $ kubectl get secrets -n external-istiod --context="${CTX_REMOTE_CLUSTER}"
    NAME                                               TYPE                                  DATA   AGE
    default-token-m9nnj                                kubernetes.io/service-account-token   3      2m37s
    istio-ca-secret                                    istio.io/ca-root                      5      18s
    istio-reader-service-account-token-prnvv           kubernetes.io/service-account-token   3      2m31s
    istiod-service-account-token-z2cvz                 kubernetes.io/service-account-token   3      2m30s
    {{< /text >}}

### 网格管理步骤{#mesh-admin-steps}

现在 Istio 已启动并正在运行，网格管理员仅需要在网格中部署和配置服务，包括网关（如果需要）。

#### 部署一个简单应用{#deploy-a-sample-application}

1. 在远程集群上创建 `sample` 命名空间并启用标签注入：

    {{< text bash >}}
    $ kubectl create --context="${CTX_REMOTE_CLUSTER}" namespace sample
    $ kubectl label --context="${CTX_REMOTE_CLUSTER}" namespace sample istio-injection=enabled
    {{< /text >}}

1. 部署示例 `helloworld`（`v1`）和 `sleep`：

    {{< text bash >}}
    $ kubectl apply -f samples/helloworld/helloworld.yaml -l service=helloworld -n sample --context="${CTX_REMOTE_CLUSTER}"
    $ kubectl apply -f samples/helloworld/helloworld.yaml -l version=v1 -n sample --context="${CTX_REMOTE_CLUSTER}"
    $ kubectl apply -f samples/sleep/sleep.yaml -n sample --context="${CTX_REMOTE_CLUSTER}"
    {{< /text >}}

1. 等几秒钟，`helloworld` 和 `sleep` Pod 将以 Sidecar 注入的方式运行：

    {{< text bash >}}
    $ kubectl get pod -n sample --context="${CTX_REMOTE_CLUSTER}"
    NAME                             READY   STATUS    RESTARTS   AGE
    helloworld-v1-5b75657f75-ncpc5   2/2     Running   0          10s
    sleep-64d7d56698-wqjnm           2/2     Running   0          9s
    {{< /text >}}

1. `sleep` Pod 向 `helloworld` Pod 服务发送请求：

    {{< text bash >}}
    $ kubectl exec --context="${CTX_REMOTE_CLUSTER}" -n sample -c sleep \
        "$(kubectl get pod --context="${CTX_REMOTE_CLUSTER}" -n sample -l app=sleep -o jsonpath='{.items[0].metadata.name}')" \
        -- curl -sS helloworld.sample:5000/hello
    Hello version: v1, instance: helloworld-v1-5b75657f75-ncpc5
    {{< /text >}}

#### 启用网关{#enable-gateways}

1. 在远程集群上启用 Ingress 网关：

    {{< text bash >}}
    $ cat <<EOF > istio-ingressgateway.yaml
    apiVersion: install.istio.io/v1alpha1
    kind: IstioOperator
    spec:
      profile: empty
      components:
        ingressGateways:
        - namespace: external-istiod
          name: istio-ingressgateway
          enabled: true
      values:
        gateways:
          istio-ingressgateway:
            injectionTemplate: gateway
    EOF
    $ istioctl install -f istio-ingressgateway.yaml --context="${CTX_REMOTE_CLUSTER}"
    {{< /text >}}

1. 在远程集群上启用 Egress 网关或者其他网关（可选）：

    {{< text bash >}}
    $ cat <<EOF > istio-egressgateway.yaml
    apiVersion: install.istio.io/v1alpha1
    kind: IstioOperator
    spec:
      profile: empty
      components:
        egressGateways:
        - namespace: external-istiod
          name: istio-egressgateway
          enabled: true
      values:
        gateways:
          istio-egressgateway:
            injectionTemplate: gateway
    EOF
    $ istioctl install -f istio-egressgateway.yaml --context="${CTX_REMOTE_CLUSTER}"
    {{< /text >}}

1. 确认 Istio Ingress 网关正在运行：

    {{< text bash >}}
    $ kubectl get pod -l app=istio-ingressgateway -n external-istiod --context="${CTX_REMOTE_CLUSTER}"
    NAME                                    READY   STATUS    RESTARTS   AGE
    istio-ingressgateway-7bcd5c6bbd-kmtl4   1/1     Running   0          8m4s
    {{< /text >}}

1. 在 Ingress 网关上暴露 `helloworld` 应用：

    {{< text bash >}}
    $ kubectl apply -f samples/helloworld/helloworld-gateway.yaml -n sample --context="${CTX_REMOTE_CLUSTER}"
    {{< /text >}}

1. 设置 `GATEWAY_URL` 环境变量（有关详细信息，请参阅[确定ingress的IP和端口](/zh/docs/tasks/traffic-management/ingress/ingress-control/#determining-the-ingress-ip-  and-ports))：

    {{< text bash >}}
    $ export INGRESS_HOST=$(kubectl -n external-istiod --context="${CTX_REMOTE_CLUSTER}" get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    $ export INGRESS_PORT=$(kubectl -n external-istiod --context="${CTX_REMOTE_CLUSTER}" get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].port}')
    $ export GATEWAY_URL=$INGRESS_HOST:$INGRESS_PORT
    {{< /text >}}

1. 确认您可以通过 Ingress 网关访问 `helloworld` 应用：

    {{< text bash >}}
    $ curl -s "http://${GATEWAY_URL}/hello"
    Hello version: v1, instance: helloworld-v1-5b75657f75-ncpc5
    {{< /text >}}

## 将集群添加到网格（可选）{#adding-clusters}

本节介绍如何通过添加另一个远程集群将现有的外部控制平面网格扩展到多集群。 这使您可以轻松分发服务并使用[位置感知路由和故障转移](/zh/docs/tasks/traffic-management/locality-load-balancing/)，以支持应用程序的高可用性。

{{< image width="75%"
    link="external-multicluster.svg"
    caption="多远程集群的外部控制平面"
    >}}

与第一个远程集群不同，添加到同一外部控制平面的第二个以及后续集群不提供网格配置，而仅提供端点配置的来源，就像[主远程](/zh/docs/setup/install/multicluster/primary-remote_multi-network/) Istio 多集群配置中的远程集群一样。

### 网格操作员说明{#mesh-operator-instructions}

未完待续
