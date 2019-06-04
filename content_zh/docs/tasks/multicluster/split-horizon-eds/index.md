---
title: 集群感知的服务路由
description: 利用 Istio 的水平分割 EDS 来创建多集群网格。
weight: 85
keywords: [kubernetes,multicluster]
aliases:
  - /zh/docs/examples/multicluster/split-horizon-eds/
---

这个示例展示了如何使用[单一控制平面拓扑](/zh/docs/concepts/multicluster-deployments/#单一控制平面拓扑)配置一个多集群网格，并使用 Istio 的`水平分割 EDS（Endpoints Discovery Service，端点发现服务）`特性（在 Istio 1.1 中引入），通过 ingress gateway 将服务请求路由到其他集群。水平分割 EDS 使 Istio 可以基于请求来源的位置，将其路由到不同的 endpoint。

按照此示例中的说明，您将设置一个两集群网格，如下图所示：

  {{< image width="80%"
  link="diagram.svg"
  caption="单个 Istio 控制平面配置水平分割 EDS，跨越多个 Kubernetes 集群" >}}

 原始集群 `cluster1` 将运行完整的 Istio 控制平面组件，而 `cluster2` 集群仅运行 Istio Citadel、Sidecar Injector 和 Ingress gateway。不需要 VPN 连接，不同集群中的工作负载之间也无需直接网络访问。

## 开始之前

除了安装 Istio 的先决条件之外，此示例还需要以下条件：

* 两个 Kubernetes 集群（称之为 `cluster1` 和 `cluster2`）。

    {{< warning >}}
    为了运行此配置，要求必须可以从 `cluster1` 集群访问 `cluster2` 集群的 Kubernetes API server。
    {{< /warning >}}

{{< boilerplate kubectl-multicluster-contexts >}}

## 多集群设置示例

在此示例中，您将安装对控制平面和应用程序 pod 都启用了双向 TLS 的 Istio。为了共享根 CA，您将使用同一个来自 Istio 示例目录的证书，在 `cluster1` 和 `cluster2` 集群上创建一个相同的 `cacerts` secret。

下面的说明还设置了 `cluster2` 集群，包含一个无 selector 的 service 和具有 `cluster1` Istio 入口网关地址的 `istio-pilot.istio-system` 端点。这将用于通过入口网关安全地访问 `cluster1` pilot，而无需双向 TLS 终止。

### 配置 `cluster1`（主） 集群

1. 使用 Helm 创建 Istio `cluster1` 的部署 YAML：

   {{< warning >}}
    如果不确定 `helm` 的依赖项是否为最新版本, 在运行下列命令前，请先根据 [Helm 安装步骤](/docs/setup/kubernetes/install/helm/#installation-steps) 更新依赖项.
    {{< /warning >}}

    {{< text bash >}}
    $ helm template --name=istio --namespace=istio-system \
      --set global.mtls.enabled=true \
      --set security.selfSigned=false \
      --set global.controlPlaneSecurityEnabled=true \
      --set global.proxy.accessLogFile="/dev/stdout" \
      --set global.meshExpansion.enabled=true \
      --set 'global.meshNetworks.network2.endpoints[0].fromRegistry'=n2-k8s-config \
      --set 'global.meshNetworks.network2.gateways[0].address'=0.0.0.0 \
      --set 'global.meshNetworks.network2.gateways[0].port'=443 \
      install/kubernetes/helm/istio > istio-auth.yaml
    {{< /text >}}

    {{< warning >}}
    注意，网关地址设置为了 `0.0.0.0`.这个值将在下面章节中使用 `cluster2` 部署后的网关的真实 IP 值替换
    {{< /warning >}}

1. 部署 Istio 到 `cluster1` 集群：

   {{< text bash >}}
    $ kubectl create --context=$CTX_CLUSTER1 ns istio-system
    $ kubectl create --context=$CTX_CLUSTER1 secret generic cacerts -n istio-system --from-file=samples/certs/ca-cert.pem --from-file=samples/certs/ca-key.pem --from-file=samples/certs/root-cert.pem --from-file=samples/certs/cert-chain.pem
    $ for i in install/kubernetes/helm/istio-init/files/crd*yaml; do kubectl apply --context=$CTX_CLUSTER1 -f $i; done
    $ kubectl create --context=$CTX_CLUSTER1 -f istio-auth.yaml
    {{< /text >}}

    等待 `cluster1` Istio pods 准备完毕:

    {{< text bash >}}
    $ kubectl get pods --context=$CTX_CLUSTER1 -n istio-system
    NAME                                      READY   STATUS      RESTARTS   AGE
    istio-citadel-9bbf9b4c8-nnmbt             1/1     Running     0          2m8s
    istio-cleanup-secrets-1.1.0-x9crw         0/1     Completed   0          2m12s
    istio-galley-868c5fff5d-9ph6l             1/1     Running     0          2m9s
    istio-ingressgateway-6c756547b-dwc78      1/1     Running     0          2m8s
    istio-pilot-54fcf8db8-sn9cn               2/2     Running     0          2m8s
    istio-policy-5fcbd55d8b-xhbpz             2/2     Running     2          2m8s
    istio-security-post-install-1.1.0-ww5zz   0/1     Completed   0          2m12s
    istio-sidecar-injector-6dcc9d5c64-7hnnl   1/1     Running     0          2m8s
    istio-telemetry-57875ffb6d-n2vmf          2/2     Running     3          2m8s
    prometheus-66c9f5694-8pccr                1/1     Running     0          2m8s
    {{< /text >}}

1. 在 `cluster2` 中创建访问服务的入口网关:

    {{< text bash >}}
    $ kubectl create --context=$CTX_CLUSTER1 -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: Gateway
    metadata:
      name: cluster-aware-gateway
      namespace: istio-system
    spec:
      selector:
        istio: ingressgateway
      servers:
      - port:
          number: 443
          name: tls
          protocol: TLS
        tls:
          mode: AUTO_PASSTHROUGH
        hosts:
        - "*.local"
    EOF
    {{< /text >}}

    此 `Gateway` 配置 443 端口，以便将传入的流量传递到目标服务并指定 SNI 请求头，以用于本地顶级域名的 SNI 值 (i.e., the [Kubernetes DNS domain](https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/)).双向 TLS 链接将会从源端一直到目标端的 sidercar。

    由于两个集群使用都是相同都 Pilot，虽然是应用在 `cluster1`上，但是网关示例也会影响 `cluster2`。

### 配置 `cluster2`

1. 导出 `cluster1` 的网管地址:

    {{< text bash >}}
    $ export LOCAL_GW_ADDR=$(kubectl get --context=$CTX_CLUSTER1 svc --selector=app=istio-ingressgateway \
        -n istio-system -o jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}') && echo ${LOCAL_GW_ADDR}
    {{< /text >}}

    上述命令设置网关公共的 IP 地址并输出地址。

    {{< warning >}}
    如果负载均衡的配置不包含 IP 地址，上述命令则会失败。DNS 名称支持的服务状态为 pending。
    {{< /warning >}}

1. 使用 Helm 创建 Istio `cluster2` deployment YAML：

    {{< text bash >}}
    $ helm template --name istio-remote --namespace=istio-system \
      --values @install/kubernetes/helm/istio/values-istio-remote.yaml@ \
      --set global.mtls.enabled=true \
      --set gateways.enabled=true \
      --set security.selfSigned=false \
      --set global.controlPlaneSecurityEnabled=true \
      --set global.createRemoteSvcEndpoints=true \
      --set global.remotePilotCreateSvcEndpoint=true \
      --set global.remotePilotAddress=${LOCAL_GW_ADDR} \
      --set global.remotePolicyAddress=${LOCAL_GW_ADDR} \
      --set global.remoteTelemetryAddress=${LOCAL_GW_ADDR} \
      --set gateways.istio-ingressgateway.env.ISTIO_META_NETWORK="network2" \
      --set global.network="network2" \
      install/kubernetes/helm/istio > istio-remote-auth.yaml
    {{< /text >}}

1. 部署 Istio 到 `cluster2`：

    {{< text bash >}}
    $ kubectl create --context=$CTX_CLUSTER2 ns istio-system
    $ kubectl create --context=$CTX_CLUSTER2 secret generic cacerts -n istio-system --from-file=samples/certs/ca-cert.pem --from-file=samples/certs/ca-key.pem --from-file=samples/certs/root-cert.pem --from-file=samples/certs/cert-chain.pem
    $ kubectl create --context=$CTX_CLUSTER2 -f istio-remote-auth.yaml
    {{< /text >}}

    等待 `cluster2` pod 的状态，特别是 `istio-ingressgateway` 的状态为已就绪：

   {{< text bash >}}
    $ kubectl get pods --context=$CTX_CLUSTER2 -n istio-system -l istio!=ingressgateway
    NAME                                     READY   STATUS      RESTARTS   AGE
    istio-citadel-75c8fcbfcf-9njn6           1/1     Running     0          12s
    istio-cleanup-secrets-1.1.0-vtp62        0/1     Completed   0          14s
    istio-sidecar-injector-cdb5d4dd5-rhks9   1/1     Running     0          12s
    {{< /text >}}

    {{< warning >}}
    需要在 `cluster1` 的控制平面中监听 `cluster2` 之后，`istio-ingressgateway` 的状态才会变成已就绪。你可以在下一章节中尝试配置。
    {{< /warning >}}

1. 确定 `cluster2` 的入口 IP 和端口号

    1. 设置 `kubectl` 当前的上下文为 `CTX_CLUSTER2`

        {{< text bash >}}
        $ export ORIGINAL_CONTEXT=$(kubectl config current-context)
        $ kubectl config use-context $CTX_CLUSTER2
        {{< /text >}}

    1. 根据[确定入口 IP 和端口](/docs/tasks/traffic-management/ingress/ingress-control/#determining-the-ingress-ip-and-ports)的命令，设置 `INGRESS_HOST` 和 `SECURE_INGRESS_PORT` 环境变量。

    1. 恢复  `kubectl` 之前的上下文：

        {{< text bash >}}
        $ kubectl config use-context $ORIGINAL_CONTEXT
        $ unset ORIGINAL_CONTEXT
        {{< /text >}}

    1. 输出 `INGRESS_HOST` 和 `SECURE_INGRESS_PORT` 的值：

        {{< text bash >}}
        $ echo The ingress gateway of cluster2: address=$INGRESS_HOST, port=$SECURE_INGRESS_PORT
        {{< /text >}}

1. 更新网格网络配置中的 gateway 地址。编辑 `istio` `ConfigMap`：

    {{< text bash >}}
    $ kubectl edit cm -n istio-system --context=$CTX_CLUSTER1 istio
    {{< /text >}}

    更新  `network2` 的网关地址和端口，并映射到 `cluster2` 入口地址和端口，分别保存并退出。

    一旦保存，Pilot 将会自动读取更新后的网络配置。

    * 确定 `remote` 网关地址：

        {{< text bash >}}
        $ kubectl get --context=$CTX_REMOTE svc --selector=app=istio-ingressgateway -n istio-system -o jsonpath="{.items[0].status.loadBalancer.ingress[0].ip}"
        169.61.102.93
        {{< /text >}}

    * 编辑 istio configmap：

        {{< text bash >}}
        $ kubectl edit cm -n istio-system --context=$CTX_LOCAL istio
        {{< /text >}}

    * 将 `network2` 的 gateway address 从 `0.0.0.0` 修改为 `remote` gateway 地址，保存并退出。

      一旦保存，Pilot 将自动读取并更新网络配置。

1. 准备环境变量以构建 service account `istio-multi` 的 `n2-k8s-config` 文件：

    {{< text bash >}}
    $ CLUSTER_NAME=$(kubectl --context=$CTX_CLUSTER2 config view --minify=true -o jsonpath='{.clusters[].name}')
    $ SERVER=$(kubectl --context=$CTX_CLUSTER2 config view --minify=true -o jsonpath='{.clusters[].cluster.server}')
    $ SECRET_NAME=$(kubectl --context=$CTX_CLUSTER2 get sa istio-multi -n istio-system -o jsonpath='{.secrets[].name}')
    $ CA_DATA=$(kubectl get --context=$CTX_CLUSTER2 secret ${SECRET_NAME} -n istio-system -o jsonpath="{.data['ca\.crt']}")
    $ TOKEN=$(kubectl get --context=$CTX_CLUSTER2 secret ${SECRET_NAME} -n istio-system -o jsonpath="{.data['token']}" | base64 --decode)
    {{< /text >}}

    {{< idea >}}
    许多系统上使用 `openssl enc -d -base64 -A` 替代 `base64 --decode`。
    {{< /idea >}}

1. 在工作目录创建 `n2-k8s-config` 文件：

    {{< text bash >}}
    $ cat <<EOF > n2-k8s-config
    apiVersion: v1
    kind: Config
    clusters:
      - cluster:
          certificate-authority-data: ${CA_DATA}
          server: ${SERVER}
        name: ${CLUSTER_NAME}
    contexts:
      - context:
          cluster: ${CLUSTER_NAME}
          user: ${CLUSTER_NAME}
        name: ${CLUSTER_NAME}
    current-context: ${CLUSTER_NAME}
    users:
      - name: ${CLUSTER_NAME}
        user:
          token: ${TOKEN}
    EOF
    {{< /text >}}

### 开始监听 `cluster2` 集群

1. 执行下列命令，添加并标记 `cluster2` Kubernetes 的 secret。执行这些命令之后，`cluster1` 的 Istio Pilot 将开始监听 `cluster2` 集群的服务和实例，就像在 `cluster1` 集群中一样。

    {{< text bash >}}
    $ kubectl create --context=$CTX_CLUSTER1 secret generic n2-k8s-secret --from-file n2-k8s-config -n istio-system
    $ kubectl label --context=$CTX_CLUSTER1 secret n2-k8s-secret istio/multiCluster=true -n istio-system
    {{< /text >}}

1. 等待 `istio-ingressgateway`准备完成：

    {{< text bash >}}
    $ kubectl get pods --context=$CTX_CLUSTER2 -n istio-system -l istio=ingressgateway
    NAME                                    READY     STATUS    RESTARTS   AGE
    istio-ingressgateway-5c667f4f84-bscff   1/1       Running   0          16m
    {{< /text >}}

现在您已经设置了 `cluster1` 和 `cluster2` 集群，可以开始部署示例 service。

## 示例 service

在这个实例中，您将了解到一个 service 的流量是如何在两个集群间分发的。
如上图所示，您将为 `helloworld` service 部署两个实例，一个在 `cluster1` 集群，另一个在 `cluster2` 集群。两个实例的区别在于其 `helloworld` 镜像的版本。

### 在 `cluster2` 集群部署 helloworld v2

1. 使用 sidecar 自动注入标签创建一个 `sample` namespace：

    {{< text bash >}}
    $ kubectl create --context=$CTX_CLUSTER2 ns sample
    $ kubectl label --context=$CTX_CLUSTER2 namespace sample istio-injection=enabled
    {{< /text >}}

1. 部署 `helloworld v2`：

    {{< text bash >}}
    $ kubectl create --context=$CTX_CLUSTER2 -f @samples/helloworld/helloworld.yaml@ -l app=helloworld -n sample
    $ kubectl create --context=$CTX_CLUSTER2 -f @samples/helloworld/helloworld.yaml@ -l version=v2 -n sample
    {{< /text >}}

1. 确定 `helloworld v2` 在运行中：

    {{< text bash >}}
    $ kubectl get po --context=$CTX_CLUSTER2 -n sample
    NAME                             READY     STATUS    RESTARTS   AGE
    helloworld-v2-7dd57c44c4-f56gq   2/2       Running   0          35s
    {{< /text >}}

### 在 `cluster1` 中部署 helloworld v1

1. 使用 sidecar 自动注入标签创建一个 `sample` namespace：

    {{< text bash >}}
    $ kubectl create --context=$CTX_CLUSTER1 ns sample
    $ kubectl label --context=$CTX_CLUSTER1 namespace sample istio-injection=enabled
    {{< /text >}}

1. 部署 `helloworld v1`:

    {{< text bash >}}
    $ kubectl create --context=$CTX_CLUSTER1 -f @samples/helloworld/helloworld.yaml@ -l app=helloworld -n sample
    $ kubectl create --context=$CTX_CLUSTER1 -f @samples/helloworld/helloworld.yaml@ -l version=v1 -n sample
    {{< /text >}}

1. 确定 `helloworld v1` 运行中：

    {{< text bash >}}
    $ kubectl get po --context=$CTX_CLUSTER1 -n sample
    NAME                            READY     STATUS    RESTARTS   AGE
    helloworld-v1-d4557d97b-pv2hr   2/2       Running   0          40s
    {{< /text >}}

### 横向分割 EDS 实战

我们将从另一个集群中 `sleep` 服务请求 `helloworld.sample` 服务。

1. 部署 `sleep` 服务：

    {{< text bash >}}
    $ kubectl create --context=$CTX_CLUSTER1 -f @samples/sleep/sleep.yaml@ -n sample
    {{< /text >}}

1. 等到 `sleep` 服务启动：

    {{< text bash >}}
    $ kubectl get po --context=$CTX_CLUSTER1 -n sample -l app=sleep
    sleep-754684654f-n6bzf           2/2     Running   0          5s
    {{< /text >}}

1. 多次请求 `helloworld.sample` 服务：

    {{< text bash >}}
    $ kubectl exec --context=$CTX_CLUSTER1 -it -n sample -c sleep $(kubectl get pod --context=$CTX_CLUSTER1 -n sample -l app=sleep -o jsonpath='{.items[0].metadata.name}') -- curl helloworld.sample:5000/hello
    {{< /text >}}

如果设置正确，到 `helloworld.sample` 服务的流量将在 `cluster1` 和 `cluster2` 实例之间进行分发，导致响应 body 中 `v1` 或 `v2` 都可能出现。

{{< text sh >}}
Hello version: v2, instance: helloworld-v2-758dd55874-6x4t8
{{< /text >}}

{{< text sh >}}
Hello version: v1, instance: helloworld-v1-86f77cd7bd-cpxhv
{{< /text >}}

您可以通过打印 `sleep` pod 的 `istio-proxy` 容器日志来验证访问的 endpoint 的 IP 地址。

{{< text bash >}}
$ kubectl logs --context=$CTX_CLUSTER1 -n sample $(kubectl get pod --context=$CTX_CLUSTER1 -n sample -l app=sleep -o jsonpath='{.items[0].metadata.name}') istio-proxy
[2018-11-25T12:37:52.077Z] "GET /hello HTTP/1.1" 200 - 0 60 190 189 "-" "curl/7.60.0" "6e096efe-f550-4dfa-8c8c-ba164baf4679" "helloworld.sample:5000" "192.23.120.32:15443" outbound|5000||helloworld.sample.svc.cluster.local - 10.20.194.146:5000 10.10.0.89:59496 -
[2018-11-25T12:38:06.745Z] "GET /hello HTTP/1.1" 200 - 0 60 171 170 "-" "curl/7.60.0" "6f93c9cc-d32a-4878-b56a-086a740045d2" "helloworld.sample:5000" "10.10.0.90:5000" outbound|5000||helloworld.sample.svc.cluster.local - 10.20.194.146:5000 10.10.0.89:59646 -
{{< /text >}}

v2 被调用时将记录 `cluster2` 网关 IP  `192.23.120.32:15443`，v1 被调用时将记录 `cluster1` 实例 IP `10.10.0.90:5000`。

## 清理

执行下列命令清理 demo 服务 __and__ Istio 组件。

清理 `cluster2` 集群：

{{< text bash >}}
$ kubectl delete --context=$CTX_CLUSTER2 -f istio-remote-auth.yaml
$ kubectl delete --context=$CTX_CLUSTER2 ns istio-system
$ kubectl delete --context=$CTX_CLUSTER2 ns sample
$ unset CTX_CLUSTER2 CLUSTER_NAME SERVER SECRET_NAME CA_DATA TOKEN INGRESS_HOST SECURE_INGRESS_PORT INGRESS_PORT
$ rm istio-remote-auth.yaml
{{< /text >}}

清理 `cluster1` 集群：

{{< text bash >}}
$ kubectl delete --context=$CTX_CLUSTER1 -f istio-auth.yaml
$ kubectl delete --context=$CTX_CLUSTER1 ns istio-system
$ for i in install/kubernetes/helm/istio-init/files/crd*yaml; do kubectl delete --context=$CTX_CLUSTER1 -f $i; done
$ kubectl delete --context=$CTX_CLUSTER1 ns sample
$ unset CTX_CLUSTER1
$ rm istio-auth.yaml n2-k8s-config
{{< /text >}}
