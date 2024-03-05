---
title: 使用外部控制平面安装 Istio
description: 安装外部控制平面和从集群。
weight: 80
aliases:
    - /zh/docs/setup/additional-setup/external-controlplane/
    - /latest/zh/docs/setup/additional-setup/external-controlplane/
keywords: [external,control,istiod,remote]
owner: istio/wg-environments-maintainers
test: yes
---

本指南将引导您完成安装{{< gloss "external control plane">}}外部控制平面{{< /gloss >}}，
然后将一个或多个{{< gloss "remote cluster" >}}从集群{{< /gloss >}}连接到该平面的过程。

外部控制平面[部署模型](/zh/docs/ops/deployment/deployment-models/#control-plane-models)
允许网格操作员在与组成网格的数据平面集群（或多个集群）分开的外部集群上安装和管理控制平面。
这种部署模型可以将网状网络运营商和网状网络管理员明确区分。网格操作员可以安装和管理 Istio 控制平面，
而网格管理员只需配置网格即可。

{{< image width="75%"
    link="external-controlplane.svg"
    caption="外部控制平面集群和从集群"
    >}}

在从集群中运行的 Envoy 代理（Sidecar 和 Gateway）通过 Ingress Gateway
访问外部 Istiod，向外暴露了需要被发现，CA，注入和验证的端点。

虽然外部控制平面的配置和管理是由外部集群中的网格操作员完成的，
但连接到外部控制平面的第一个从集群充当了网格本身的配置集群。除了网状服务本身之外，
网格管理员还将使用配置集群来配置网状资源（Gateway、虚拟服务等）。外部控制平面将从
Kubernetes API Server 远程访问此配置，如上图所示。

## 准备开始  {#before-you-begin}

### 集群  {#clusters}

本指南要求您有任意两个[受支持版本的 Kubernetes](/zh/docs/releases/supported-releases#support-status-of-istio-releases)
集群：{{< supported_kubernetes_versions >}}。

第一个集群将托管安装在 `external-istiod` 命名空间中的{{< gloss "external control plane">}}外部控制平面{{< /gloss >}}。
Ingress Gateway 也安装在 `istio-system` 命名空间中，以提供对外部控制平面的跨集群访问。

第二个集群是将运行网格应用程序工作负载的{{< gloss "remote cluster">}}从集群{{< /gloss >}}。
它的 Kubernetes API Server 还提供了外部控制平面（Istiod）用来配置工作负载代理的网状配置。

### API Server 访问  {#API-server-access}

外部控制平面集群必须可以访问从集群中的 Kubernetes API Server。
许多云提供商通过网络负载均衡器（NLB）公开访问 API Server。
如果无法直接访问 API Server，则需要修改安装过程以启用访问权限。
例如，在[多集群配置](#adding-clusters)中使用的[东西向](https://en.wikipedia.org/wiki/East-west_traffic)
Gateway 也可以用于启用对 API Server 的访问。

### 环境变量  {#environment-variables}

以下环境变量将始终用于简化说明：

变量名称 | 描述
-------- | -----------
`CTX_EXTERNAL_CLUSTER` | 默认 [Kubernetes 配置文件](https://kubernetes.io/zh-cn/docs/tasks/access-application-cluster/configure-access-multiple-clusters/)中的上下文名称，用于访问外部控制平面集群。
`CTX_REMOTE_CLUSTER` | 默认 [Kubernetes 配置文件](https://kubernetes.io/zh-cn/docs/tasks/access-application-cluster/configure-access-multiple-clusters/)中的上下文名称，用于访问从集群。
`REMOTE_CLUSTER_NAME` | 从集群的名称。
`EXTERNAL_ISTIOD_ADDR` | 外部控制平面集群上的 Ingress Gateway 的主机名。从集群使用它来访问外部控制平面。
`SSL_SECRET_NAME` | 拥有外部控制平面集群上 Ingress Gateway 的 TLS 证书的 Secret 名称。

立即设置 `CTX_EXTERNAL_CLUSTER`、`CTX_REMOTE_CLUSTER` 和 `REMOTE_CLUSTER_NAME`。稍后将设置其他变量。

{{< text syntax=bash snip_id=none >}}
$ export CTX_EXTERNAL_CLUSTER=<您的外部集群上下文>
$ export CTX_REMOTE_CLUSTER=<您的从集群上下文>
$ export REMOTE_CLUSTER_NAME=<您的从集群名称>
{{< /text >}}

## 集群配置  {#cluster-configuration}

### 网格操作步骤  {#mesh-operator-steps}

网格操作员负责在外部集群上安装和管理外部 Istio 控制平面。
这包括在外部集群上配置 Ingress Gateway，允许从集群访问控制平面，并在从集群上安装所需的
Webhook、ConfigMap 和 Secret，以便使用外部控制平面。

#### 在外部集群中搭建 Gateway  {#set-up-a-gateway-in-the-external-cluster}

1. 为 Ingress Gateway 创建 Istio 安装配置，该配置会将外部控制平面端口暴露给其他集群：

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

    然后，将 Gateway 安装在外部集群的 `istio-system` 命名空间中：

    {{< text bash >}}
    $ istioctl install -f controlplane-gateway.yaml --context="${CTX_EXTERNAL_CLUSTER}"
    {{< /text >}}

1. 运行以下命令来确认 Ingress Gateway 已启动并正在运行：

    {{< text bash >}}
    $ kubectl get po -n istio-system --context="${CTX_EXTERNAL_CLUSTER}"
    NAME                                   READY   STATUS    RESTARTS   AGE
    istio-ingressgateway-9d4c7f5c7-7qpzz   1/1     Running   0          29s
    istiod-68488cd797-mq8dn                1/1     Running   0          38s
    {{< /text >}}

    您会注意到在 `istio-system` 命名空间中也创建了一个 Istiod Deployment。这用于配置
    Ingress Gateway，而不是从集群使用的控制平面。

    {{< tip >}}
    可以将 Ingress Gateway 配置为在外部集群上的不同命名空间中承载多个外部控制平面，
    尽管在本示例中，您将仅在 `external-istiod` 命名空间中部署一个外部 Istiod。
    {{< /tip >}}

1. 使用带有 TLS 的公共主机名配置您的环境来暴露 Istio Ingress Gateway 服务。

   将 `EXTERNAL_ISTIOD_ADDR` 环境变量设置为主机名，将 `SSL_SECRET_NAME`
   环境变量设置为包含 TLS 证书的 Secret：

    {{< text syntax=bash snip_id=none >}}
    $ export EXTERNAL_ISTIOD_ADDR=<您的外部 istiod 主机>
    $ export SSL_SECRET_NAME=<您的外部 istiod secret>
    {{< /text >}}

    这些说明假定您使用具有正确签名的 DNS 证书的主机名公开外部集群的 Gateway，因为这是生产环境中推荐的方法。
    参阅[安全的 Ingress 任务](/zh/docs/tasks/traffic-management/ingress/secure-ingress/#configure-a-tls-ingress-gateway-for-a-single-host)，
    了解暴露安全 Gateway 的更多信息。

    您的环境变量应如下所示：

    {{< text bash >}}
    $ echo "$EXTERNAL_ISTIOD_ADDR" "$SSL_SECRET_NAME"
    myhost.example.com myhost-example-credential
    {{< /text >}}

    {{< tip >}}
    如果您没有 DNS 主机名但想在测试环境中试验外部控制平面，您可以使用其外部负载均衡器 IP 地址访问 Gateway：

    {{< text bash >}}
    $ export EXTERNAL_ISTIOD_ADDR=$(kubectl -n istio-system --context="${CTX_EXTERNAL_CLUSTER}" get svc istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    $ export SSL_SECRET_NAME=NONE
    {{< /text >}}

    这样做还需要对配置进行一些其他更改。请务必按照以下说明中的所有相关步骤进行操作。
    {{< /tip >}}

#### 设置从集群  {#set-up-the-remote-cluster}

1. 使用 `remote` 配置文件配置从集群上安装的 Istio。这将安装一个使用外部控制平面注入器的注入 Webhook，
   而不是本地部署的注入器。因为这个集群也将作为配置集群，所以安装从集群上所需的 Istio CRD 和其他资源时将
   `global.configCluster` 和 `pilot.configMap` 设置为 `true`：

    {{< text syntax=bash snip_id=get_remote_config_cluster_iop >}}
    $ cat <<EOF > remote-config-cluster.yaml
    apiVersion: install.istio.io/v1alpha1
    kind: IstioOperator
    metadata:
      namespace: external-istiod
    spec:
      profile: remote
      values:
        global:
          istioNamespace: external-istiod
          configCluster: true
        pilot:
          configMap: true
        istiodRemote:
          injectionURL: https://${EXTERNAL_ISTIOD_ADDR}:15017/inject/cluster/${REMOTE_CLUSTER_NAME}/net/network1
        base:
          validationURL: https://${EXTERNAL_ISTIOD_ADDR}:15017/validate
    EOF
    {{< /text >}}

    {{< tip >}}
    如果您的集群名称包含`/`（斜杠）字符，请在 `injectionURL` 中将其替换为 `--slash--`，
    例如 `injectionURL: https://1.2.3.4:15017/inject/cluster/`<mark>`cluster--slash--1`</mark>`/net/network1`。
    {{< /tip >}}

1. 如果您使用的是 `EXTERNAL_ISTIOD_ADDR` 的 IP 地址，而不是正确的 DNS 主机名，
   请修改配置以指定发现地址和路径，而不是 URL：

    {{< warning >}}
    在生产环境中不推荐这样做。
    {{< /warning >}}

    {{< text bash >}}
    $ sed  -i'.bk' \
      -e "s|injectionURL: https://${EXTERNAL_ISTIOD_ADDR}:15017|injectionPath: |" \
      -e "/istioNamespace:/a\\
          remotePilotAddress: ${EXTERNAL_ISTIOD_ADDR}" \
      -e '/base:/,+1d' \
      remote-config-cluster.yaml; rm remote-config-cluster.yaml.bk
    {{< /text >}}

1. 在从集群上安装配置：

    {{< text bash >}}
    $ kubectl create namespace external-istiod --context="${CTX_REMOTE_CLUSTER}"
    $ istioctl manifest generate -f remote-config-cluster.yaml --set values.defaultRevision=default | kubectl apply --context="${CTX_REMOTE_CLUSTER}" -f -
    {{< /text >}}

1. 确认从集群的注入 Webhook 配置已经安装：

    {{< text bash >}}
    $ kubectl get mutatingwebhookconfiguration --context="${CTX_REMOTE_CLUSTER}"
    NAME                                     WEBHOOKS   AGE
    istio-sidecar-injector-external-istiod   4          6m24s
    {{< /text >}}

1. 确认已安装从集群的验证 Webhook 配置：

    {{< text bash >}}
    $ kubectl get validatingwebhookconfiguration --context="${CTX_REMOTE_CLUSTER}"
    NAME                              WEBHOOKS   AGE
    istio-validator-external-istiod   1          6m53s
    istiod-default-validator          1          6m53s
    {{< /text >}}

#### 在外部集群中安装控制平面  {#set-up-the-control-plane-in-the-external-cluster}

1. 创建 `external-istiod` 命名空间，该命名空间将用于托管外部控制平面：

    {{< text bash >}}
    $ kubectl create namespace external-istiod --context="${CTX_EXTERNAL_CLUSTER}"
    {{< /text >}}

1. 外部集群中的控制平面需要访问从集群以发现服务、端点和 Pod 属性。创建具有凭据的
   Secret，以访问从集群的 `kube-apiserver` 并将其安装在外部集群中：

    {{< text bash >}}
    $ kubectl create sa istiod-service-account -n external-istiod --context="${CTX_EXTERNAL_CLUSTER}"
    $ istioctl create-remote-secret \
      --context="${CTX_REMOTE_CLUSTER}" \
      --type=config \
      --namespace=external-istiod \
      --service-account=istiod \
      --create-service-account=false | \
      kubectl apply -f - --context="${CTX_EXTERNAL_CLUSTER}"
    {{< /text >}}

1. 创建 Istio 配置以在外部集群的 `external-istiod` 命名空间中安装控制平面。
    请注意，istiod 配置为使用本地安装的 `istio` ConfigMap，并且 `SHARED_MESH_CONFIG`
    环境变量设置为 `istio`。这指示 istiod 将网格管理员在配置集群的 ConfigMap
    中设置的值与网格操作员在本地 ConfigMap 中设置的值合并，如果有任何冲突，这将优先考虑：

    {{< text syntax=bash snip_id=get_external_istiod_iop >}}
    $ cat <<EOF > external-istiod.yaml
    apiVersion: install.istio.io/v1alpha1
    kind: IstioOperator
    metadata:
      namespace: external-istiod
    spec:
      profile: empty
      meshConfig:
        rootNamespace: external-istiod
        defaultConfig:
          discoveryAddress: $EXTERNAL_ISTIOD_ADDR:15012
          proxyMetadata:
            XDS_ROOT_CA: /etc/ssl/certs/ca-certificates.crt
            CA_ROOT_CA: /etc/ssl/certs/ca-certificates.crt
      components:
        pilot:
          enabled: true
          k8s:
            overlays:
            - kind: Deployment
              name: istiod
              patches:
              - path: spec.template.spec.volumes[100]
                value: |-
                  name: config-volume
                  configMap:
                    name: istio
              - path: spec.template.spec.volumes[100]
                value: |-
                  name: inject-volume
                  configMap:
                    name: istio-sidecar-injector
              - path: spec.template.spec.containers[0].volumeMounts[100]
                value: |-
                  name: config-volume
                  mountPath: /etc/istio/config
              - path: spec.template.spec.containers[0].volumeMounts[100]
                value: |-
                  name: inject-volume
                  mountPath: /var/lib/istio/inject
            env:
            - name: INJECTION_WEBHOOK_CONFIG_NAME
              value: ""
            - name: VALIDATION_WEBHOOK_CONFIG_NAME
              value: ""
            - name: EXTERNAL_ISTIOD
              value: "true"
            - name: LOCAL_CLUSTER_SECRET_WATCHER
              value: "true"
            - name: CLUSTER_ID
              value: ${REMOTE_CLUSTER_NAME}
            - name: SHARED_MESH_CONFIG
              value: istio
      values:
        global:
          caAddress: $EXTERNAL_ISTIOD_ADDR:15012
          istioNamespace: external-istiod
          operatorManageWebhooks: true
          configValidation: false
          meshID: mesh1
    EOF
    {{< /text >}}

1. 如果您使用的是 `EXTERNAL_ISTIOD_ADDR` 的 IP 地址，而不是合适的 DNS 主机名，
   请删除代理元数据并更新配置中的 Webhook 配置环境变量：

    {{< warning >}}
    这在生产环境中不推荐。
    {{< /warning >}}

    {{< text bash >}}
    $ sed  -i'.bk' \
      -e '/proxyMetadata:/,+2d' \
      -e '/INJECTION_WEBHOOK_CONFIG_NAME/{n;s/value: ""/value: istio-sidecar-injector-external-istiod/;}' \
      -e '/VALIDATION_WEBHOOK_CONFIG_NAME/{n;s/value: ""/value: istio-validator-external-istiod/;}' \
      external-istiod.yaml ; rm external-istiod.yaml.bk
    {{< /text >}}

1. 在外部集群上应用 Istio 配置：

    {{< text bash >}}
    $ istioctl install -f external-istiod.yaml --context="${CTX_EXTERNAL_CLUSTER}"
    {{< /text >}}

1. 确认外部 Istiod 已成功部署：

    {{< text bash >}}
    $ kubectl get po -n external-istiod --context="${CTX_EXTERNAL_CLUSTER}"
    NAME                      READY   STATUS    RESTARTS   AGE
    istiod-779bd6fdcf-bd6rg   1/1     Running   0          70s
    {{< /text >}}

1. 创建 Istio `Gateway`、`VirtualService` 和 `DestinationRule` 配置，将流量从
   Ingress Gateway 路由到外部控制平面：

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

1. 如果您为 `EXTERNAL_ISTIOD_ADDR` 使用 IP 地址，而不是合适的 DNS 主机名，请修改配置。
    删除 `DestinationRule`，不要在 `Gateway` 中终止 TLS，在 `VirtualService` 中使用 TLS 路由：

    {{< warning >}}
    在生产环境中不推荐这样做。
    {{< /warning >}}

    {{< text bash >}}
    $ sed  -i'.bk' \
      -e '55,$d' \
      -e 's/mode: SIMPLE/mode: PASSTHROUGH/' -e '/credentialName:/d' -e "s/${EXTERNAL_ISTIOD_ADDR}/\"*\"/" \
      -e 's/http:/tls:/' -e 's/https/tls/' -e '/route:/i\
            sniHosts:\
            - "*"' \
      external-istiod-gw.yaml; rm external-istiod-gw.yaml.bk
    {{< /text >}}

1. 在外部集群上应用配置：

    {{< text bash >}}
    $ kubectl apply -f external-istiod-gw.yaml --context="${CTX_EXTERNAL_CLUSTER}"
    {{< /text >}}

### 网格管理步骤  {#mesh-admin-steps}

现在 Istio 已启动并运行，网格管理员只需在网格中部署和配置服务，包括 Gateway（如果需要）。

{{< tip >}}
默认情况下，某些 `istioctl` CLI 命令在从集群上不起作用，但您可以轻松配置 `istioctl` 以使其功能齐全。
详情参见 [Istioctl-proxy 生态系统项目](https://github.com/istio-ecosystem/istioctl-proxy-sample)。
{{< /tip >}}

#### 部署一个简单应用  {#deploy-a-sample-application}

1. 在从集群上创建 `sample` 命名空间并启用标签注入：

    {{< text bash >}}
    $ kubectl create --context="${CTX_REMOTE_CLUSTER}" namespace sample
    $ kubectl label --context="${CTX_REMOTE_CLUSTER}" namespace sample istio-injection=enabled
    {{< /text >}}

1. 部署示例 `helloworld`（`v1`）和 `sleep`：

    {{< text bash >}}
    $ kubectl apply -f @samples/helloworld/helloworld.yaml@ -l service=helloworld -n sample --context="${CTX_REMOTE_CLUSTER}"
    $ kubectl apply -f @samples/helloworld/helloworld.yaml@ -l version=v1 -n sample --context="${CTX_REMOTE_CLUSTER}"
    $ kubectl apply -f @samples/sleep/sleep.yaml@ -n sample --context="${CTX_REMOTE_CLUSTER}"
    {{< /text >}}

1. 等几秒钟，Pod `helloworld` 和 `sleep` 将以 Sidecar 注入的方式运行：

    {{< text bash >}}
    $ kubectl get pod -n sample --context="${CTX_REMOTE_CLUSTER}"
    NAME                             READY   STATUS    RESTARTS   AGE
    helloworld-v1-5b75657f75-ncpc5   2/2     Running   0          10s
    sleep-64d7d56698-wqjnm           2/2     Running   0          9s
    {{< /text >}}

1. 从 Pod `sleep` 向 Pod `helloworld` 服务发送请求：

    {{< text bash >}}
    $ kubectl exec --context="${CTX_REMOTE_CLUSTER}" -n sample -c sleep \
        "$(kubectl get pod --context="${CTX_REMOTE_CLUSTER}" -n sample -l app=sleep -o jsonpath='{.items[0].metadata.name}')" \
        -- curl -sS helloworld.sample:5000/hello
    Hello version: v1, instance: helloworld-v1-776f57d5f6-s7zfc
    {{< /text >}}

#### 启用 Gateway  {#enable-gateways}

{{< tip >}}
{{< boilerplate gateway-api-future >}}

如果您使用 Gateway API，则无需安装任何 Gateway 组件。
您可以跳过以下说明，直接进入[配置和测试 Ingress Gateway](#configure-and-test-an-ingress-gateway)。
{{< /tip >}}

在从集群上启用 Ingress Gateway：

{{< tabset category-name="ingress-gateway-install-type" >}}

{{< tab name="IstioOperator" category-value="iop" >}}

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
$ istioctl install -f istio-ingressgateway.yaml --set values.global.istioNamespace=external-istiod --context="${CTX_REMOTE_CLUSTER}"
{{< /text >}}

{{< /tab >}}

{{< tab name="Helm" category-value="helm" >}}

{{< text bash >}}
$ helm install istio-ingressgateway istio/gateway -n external-istiod --kube-context="${CTX_REMOTE_CLUSTER}"
{{< /text >}}

有关 Gateway 安装的详细文档，请参阅[安装 Gateway](/zh/docs/setup/additional-setup/gateway/)。

{{< /tab >}}
{{< /tabset >}}

在从集群上启用 Egress Gateway 或者其他 Gateway（可选）：

{{< tabset category-name="egress-gateway-install-type" >}}

{{< tab name="IstioOperator" category-value="iop" >}}

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
$ istioctl install -f istio-egressgateway.yaml --set values.global.istioNamespace=external-istiod --context="${CTX_REMOTE_CLUSTER}"
{{< /text >}}

{{< /tab >}}

{{< tab name="Helm" category-value="helm" >}}

{{< text bash >}}
$ helm install istio-egressgateway istio/gateway -n external-istiod --kube-context="${CTX_REMOTE_CLUSTER}" --set service.type=ClusterIP
{{< /text >}}

有关 Gateway 安装的详细文档，请参阅[安装 Gateway](/zh/docs/setup/additional-setup/gateway/)。

{{< /tab >}}
{{< /tabset >}}

#### 配置和测试 Ingress Gateway  {#configure-and-test-an-ingress-gateway}

{{< tip >}}
{{< boilerplate gateway-api-choose >}}
{{< /tip >}}

1. 确保集群已准备好配置 Gateway：

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

确认 Istio Ingress Gateway 正在运行：

{{< text bash >}}
$ kubectl get pod -l app=istio-ingressgateway -n external-istiod --context="${CTX_REMOTE_CLUSTER}"
NAME                                    READY   STATUS    RESTARTS   AGE
istio-ingressgateway-7bcd5c6bbd-kmtl4   1/1     Running   0          8m4s
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

大多数 Kubernetes 集群默认不会安装 Kubernetes Gateway API CRD，因此请确保在使用 Gateway API
之前安装了它们：

{{< text syntax=bash snip_id=install_crds >}}
$ kubectl get crd gateways.gateway.networking.k8s.io --context="${CTX_REMOTE_CLUSTER}" || \
  { kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd?ref={{< k8s_gateway_api_version >}}" | kubectl apply -f - --context="${CTX_REMOTE_CLUSTER}"; }
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

2) 在 Ingress Gateway 上暴露 `helloworld` 应用：

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl apply -f @samples/helloworld/helloworld-gateway.yaml@ -n sample --context="${CTX_REMOTE_CLUSTER}"
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl apply -f @samples/helloworld/gateway-api/helloworld-gateway.yaml@ -n sample --context="${CTX_REMOTE_CLUSTER}"
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

3) 设置 `GATEWAY_URL` 环境变量（有关详细信息，请参阅[确定 Ingress 的 IP 和端口](/zh/docs/tasks/traffic-management/ingress/ingress-control/#determining-the-ingress-ip-and-ports)）：

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ export INGRESS_HOST=$(kubectl -n external-istiod --context="${CTX_REMOTE_CLUSTER}" get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
$ export INGRESS_PORT=$(kubectl -n external-istiod --context="${CTX_REMOTE_CLUSTER}" get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].port}')
$ export GATEWAY_URL=$INGRESS_HOST:$INGRESS_PORT
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl -n sample --context="${CTX_REMOTE_CLUSTER}" wait --for=condition=programmed gtw helloworld-gateway
$ export INGRESS_HOST=$(kubectl -n sample --context="${CTX_REMOTE_CLUSTER}" get gtw helloworld-gateway -o jsonpath='{.status.addresses[0].value}')
$ export GATEWAY_URL=$INGRESS_HOST:80
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

4) 确认您可以通过 Ingress Gateway 访问 `helloworld` 应用：

    {{< text bash >}}
    $ curl -s "http://${GATEWAY_URL}/hello"
    Hello version: v1, instance: helloworld-v1-776f57d5f6-s7zfc
    {{< /text >}}

## 将集群添加到网格（可选） {#adding-clusters}

本节介绍如何通过添加另一个从集群将现有的外部控制平面网格扩展到多集群。
这使您可以轻松分发服务并使用[位置感知路由和故障转移](/zh/docs/tasks/traffic-management/locality-load-balancing/)，以支持应用程序的高可用性。

{{< image width="75%"
    link="external-multicluster.svg"
    caption="多从集群的外部控制平面"
    >}}

与第一个从集群不同，添加到同一外部控制平面的第二个以及后续集群不提供网格配置，而仅提供端点配置的来源，
就像[主从](/zh/docs/setup/install/multicluster/primary-remote_multi-network/) Istio
多集群配置中的从集群一样。

要继续的话，您需要另一个 Kubernetes 集群作为网格的第二个从集群。将以下环境变量设置为集群的上下文名称和集群名称：

{{< text syntax=bash snip_id=none >}}
$ export CTX_SECOND_CLUSTER=<您的第二个从集群上下文>
$ export SECOND_CLUSTER_NAME=<您的第二个从集群名称>
{{< /text >}}

### 注册新集群  {#register-the-new-cluster}

1. 创建远程 Istio 安装配置，它安装使用外部控制平面注入器的注入 Webhook，而不是本地部署的注入器：

    {{< text syntax=bash snip_id=get_second_remote_cluster_iop >}}
    $ cat <<EOF > second-remote-cluster.yaml
    apiVersion: install.istio.io/v1alpha1
    kind: IstioOperator
    metadata:
      namespace: external-istiod
    spec:
      profile: remote
      values:
        global:
          istioNamespace: external-istiod
        istiodRemote:
          injectionURL: https://${EXTERNAL_ISTIOD_ADDR}:15017/inject/cluster/${SECOND_CLUSTER_NAME}/net/network2
    EOF
    {{< /text >}}

1. 如果您使用的是 `EXTERNAL_ISTIOD_ADDR` 的 IP 地址，而不是合适的 DNS 主机名，请修改配置以指定发现地址和路径，而不是注入 URL：

    {{< warning >}}
    在生产环境中不推荐这样做。
    {{< /warning >}}

    {{< text bash >}}
    $ sed  -i'.bk' \
      -e "s|injectionURL: https://${EXTERNAL_ISTIOD_ADDR}:15017|injectionPath: |" \
      -e "/istioNamespace:/a\\
          remotePilotAddress: ${EXTERNAL_ISTIOD_ADDR}" \
      second-remote-cluster.yaml; rm second-remote-cluster.yaml.bk
    {{< /text >}}

1. 在从集群上创建系统命名空间并添加注解：

    {{< text bash >}}
    $ kubectl create namespace external-istiod --context="${CTX_SECOND_CLUSTER}"
    $ kubectl annotate namespace external-istiod "topology.istio.io/controlPlaneClusters=${REMOTE_CLUSTER_NAME}" --context="${CTX_SECOND_CLUSTER}"
    {{< /text >}}

    `topology.istio.io/controlPlaneClusters` 注解指定了应该管理这个从集群的外部控制平面的集群 ID。
    注意这是第一个从（配置）集群的名称，之前在外部集群安装时用于设置外部控制平面的集群 ID。

1. 在从集群上安装配置：

    {{< text bash >}}
    $ istioctl manifest generate -f second-remote-cluster.yaml | kubectl apply --context="${CTX_SECOND_CLUSTER}" -f -
    {{< /text >}}

1. 确认从集群的注入 Webhook 配置已经安装：

    {{< text bash >}}
    $ kubectl get mutatingwebhookconfiguration --context="${CTX_SECOND_CLUSTER}"
    NAME                                     WEBHOOKS   AGE
    istio-sidecar-injector-external-istiod   4          4m13s
    {{< /text >}}

1. 使用凭据创建一个 Secret，以允许控制平面访问第二个从集群上的端点并安装它：

    {{< text bash >}}
    $ istioctl create-remote-secret \
      --context="${CTX_SECOND_CLUSTER}" \
      --name="${SECOND_CLUSTER_NAME}" \
      --type=remote \
      --namespace=external-istiod \
      --create-service-account=false | \
      kubectl apply -f - --context="${CTX_EXTERNAL_CLUSTER}"
    {{< /text >}}

    请注意，与网格的第一个从集群不同，它也用作 config 集群，此时 `--type` 参数设置为 `remote`，而不是 `config`。

### 设置东西向 Gateway  {#setup-east-west-gateways}

1. 在两个从集群上部署东西向 Gateway：

    {{< text bash >}}
    $ @samples/multicluster/gen-eastwest-gateway.sh@ \
        --mesh mesh1 --cluster "${REMOTE_CLUSTER_NAME}" --network network1 > eastwest-gateway-1.yaml
    $ istioctl manifest generate -f eastwest-gateway-1.yaml \
        --set values.global.istioNamespace=external-istiod | \
        kubectl apply --context="${CTX_REMOTE_CLUSTER}" -f -
    {{< /text >}}

    {{< text bash >}}
    $ @samples/multicluster/gen-eastwest-gateway.sh@ \
        --mesh mesh1 --cluster "${SECOND_CLUSTER_NAME}" --network network2 > eastwest-gateway-2.yaml
    $ istioctl manifest generate -f eastwest-gateway-2.yaml \
        --set values.global.istioNamespace=external-istiod | \
        kubectl apply --context="${CTX_SECOND_CLUSTER}" -f -
    {{< /text >}}

1. 等待东西向 Gateway 分配外部 IP 地址：

    {{< text bash >}}
    $ kubectl --context="${CTX_REMOTE_CLUSTER}" get svc istio-eastwestgateway -n external-istiod
    NAME                    TYPE           CLUSTER-IP    EXTERNAL-IP    PORT(S)   AGE
    istio-eastwestgateway   LoadBalancer   10.0.12.121   34.122.91.98   ...       51s
    {{< /text >}}

    {{< text bash >}}
    $ kubectl --context="${CTX_SECOND_CLUSTER}" get svc istio-eastwestgateway -n external-istiod
    NAME                    TYPE           CLUSTER-IP    EXTERNAL-IP    PORT(S)   AGE
    istio-eastwestgateway   LoadBalancer   10.0.12.121   34.122.91.99   ...       51s
    {{< /text >}}

1. 通过东西向 Gateway 公开服务：

    {{< text bash >}}
    $ kubectl --context="${CTX_REMOTE_CLUSTER}" apply -n external-istiod -f \
        @samples/multicluster/expose-services.yaml@
    {{< /text >}}

### 验证安装  {#validate-the-installation}

1. 在从集群上创建 `sample` 命名空间并启用标签注入：

    {{< text bash >}}
    $ kubectl create --context="${CTX_SECOND_CLUSTER}" namespace sample
    $ kubectl label --context="${CTX_SECOND_CLUSTER}" namespace sample istio-injection=enabled
    {{< /text >}}

1. 部署 `helloworld`（`v2` 版本）和 `sleep` 的示例：

    {{< text bash >}}
    $ kubectl apply -f @samples/helloworld/helloworld.yaml@ -l service=helloworld -n sample --context="${CTX_SECOND_CLUSTER}"
    $ kubectl apply -f @samples/helloworld/helloworld.yaml@ -l version=v2 -n sample --context="${CTX_SECOND_CLUSTER}"
    $ kubectl apply -f @samples/sleep/sleep.yaml@ -n sample --context="${CTX_SECOND_CLUSTER}"
    {{< /text >}}

1. 等待几秒钟，让 `helloworld` 和 Pod `sleep` 在注入 Sidecar 的情况下运行：

    {{< text bash >}}
    $ kubectl get pod -n sample --context="${CTX_SECOND_CLUSTER}"
    NAME                            READY   STATUS    RESTARTS   AGE
    helloworld-v2-54df5f84b-9hxgw   2/2     Running   0          10s
    sleep-557747455f-wtdbr          2/2     Running   0          9s
    {{< /text >}}

1. 从 Pod `sleep` 向 `helloworld` 服务发送请求：

    {{< text bash >}}
    $ kubectl exec --context="${CTX_SECOND_CLUSTER}" -n sample -c sleep \
        "$(kubectl get pod --context="${CTX_SECOND_CLUSTER}" -n sample -l app=sleep -o jsonpath='{.items[0].metadata.name}')" \
        -- curl -sS helloworld.sample:5000/hello
    Hello version: v2, instance: helloworld-v2-54df5f84b-9hxgw
    {{< /text >}}

1. 确认通过 Ingress Gateway 多次访问 `helloworld` 应用时，现在调用的是版本 `v1` 和 `v2`：

    {{< text bash >}}
    $ for i in {1..10}; do curl -s "http://${GATEWAY_URL}/hello"; done
    Hello version: v1, instance: helloworld-v1-776f57d5f6-s7zfc
    Hello version: v2, instance: helloworld-v2-54df5f84b-9hxgw
    Hello version: v1, instance: helloworld-v1-776f57d5f6-s7zfc
    Hello version: v2, instance: helloworld-v2-54df5f84b-9hxgw
    ...
    {{< /text >}}

## 清理环境  {#clean-up}

清理外部控制平面集群：

{{< text bash >}}
$ kubectl delete -f external-istiod-gw.yaml --context="${CTX_EXTERNAL_CLUSTER}"
$ istioctl uninstall -y --purge --context="${CTX_EXTERNAL_CLUSTER}"
$ kubectl delete ns istio-system external-istiod --context="${CTX_EXTERNAL_CLUSTER}"
$ rm controlplane-gateway.yaml external-istiod.yaml external-istiod-gw.yaml
{{< /text >}}

清理从配置集群：

{{< text bash >}}
$ kubectl delete ns sample --context="${CTX_REMOTE_CLUSTER}"
$ istioctl manifest generate -f remote-config-cluster.yaml --set values.defaultRevision=default | kubectl delete --context="${CTX_REMOTE_CLUSTER}" -f -
$ kubectl delete ns external-istiod --context="${CTX_REMOTE_CLUSTER}"
$ rm remote-config-cluster.yaml istio-ingressgateway.yaml
$ rm istio-egressgateway.yaml eastwest-gateway-1.yaml || true
{{< /text >}}

如果安装了可选的第二个从集群，请清理它：

{{< text bash >}}
$ kubectl delete ns sample --context="${CTX_SECOND_CLUSTER}"
$ istioctl manifest generate -f second-remote-cluster.yaml | kubectl delete --context="${CTX_SECOND_CLUSTER}" -f -
$ kubectl delete ns external-istiod --context="${CTX_SECOND_CLUSTER}"
$ rm second-remote-cluster.yaml eastwest-gateway-2.yaml
{{< /text >}}
