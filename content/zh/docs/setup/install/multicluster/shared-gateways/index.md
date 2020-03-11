---
title: 共享的控制平面（多网络）
description: 跨多个 Kubernetes 集群安装一个 Istio 网格，使互不联通的集群网络共享同一个控制平面。
weight: 85
keywords: [kubernetes,multicluster]
aliases:
    - /zh/docs/examples/multicluster/split-horizon-eds/
    - /zh/docs/tasks/multicluster/split-horizon-eds/
    - /zh/docs/setup/kubernetes/install/multicluster/shared-gateways/
---

遵循本指南配置一个多集群网格，使用共享的
[控制平面](/zh/docs/ops/deployment/deployment-models/#control-plane-models)，并通过网关连通彼此网络隔离的集群。
Istio 位置感知的服务路由特性，可以根据请求源所在的位置将请求路由至不同的 endpoints。

遵循本指南中的说明，将安装一个两集群网格，如下图所示：

  {{< image width="80%"
  link="./diagram.svg"
  caption="Shared Istio control plane topology spanning multiple Kubernetes clusters using gateways" >}}

主集群 `cluster1` 运行全部的 Istio 控制平面组件集，而 `cluster2` 只运行 Istio Citadel、Sidecar 注入器以及 Ingress 网关。
不同集群的工作负载之间既不要求 VPN 连接也不要求直接网络访问。

## 前提条件{#prerequisites}

* 两个或多个 Kubernetes 集群，版本为： {{< supported_kubernetes_versions >}}。

* 有权限[部署 Istio 控制平面](/zh/docs/setup/install/istioctl/)

* 两个 Kubernetes 集群（称为 `cluster1` 和 `cluster2`）。

    {{< warning >}}
    为了运行本配置，`cluster1` 必须能够访问 `cluster2` 的 Kubernetes API server。
    {{< /warning >}}

{{< boilerplate kubectl-multicluster-contexts >}}

## 安装多集群网格{#setup-the-multicluster-mesh}

在本配置中，安装 Istio 时同时开启控制平面和应用 pods 的双向 TLS。
对于共享的根 CA，使用 Istio 示例目录下相同的 Istio 证书，在 `cluster1` 和 `cluster2` 中都创建相同的 `cacerts` secret。

下文命令安装 `cluster2` 时，创建一个无 selector 的服务，并为 `istio-pilot.istio-system` 创建一个 endpoint，其地址为 `cluster1` 的 Istio ingress gateway。
它们用于通过 ingress gateway 安全地访问 `cluster1` 中的 pilot，无需双向 TLS 终端。

### 安装集群 1（主集群）{#setup-cluster-1-primary}

1. 在 `cluster1` 中部署 Istio：

    {{< warning >}}
    当启用多集群所需的附加组件时，Istio 控制平面的资源占用量可能会增长，甚至超过 Kubernetes 集群安装[平台安装](/zh/docs/setup/platform-setup/)步骤中的默认容量。
    如果因 CPU 或内存资源不足导致 Istio 服务无法调度，可以考虑在集群中添加更多节点，或按需升级为更大内存容量的实例。
    {{< /warning >}}

    {{< text bash >}}
    $ kubectl create --context=$CTX_CLUSTER1 ns istio-system
    $ kubectl create --context=$CTX_CLUSTER1 secret generic cacerts -n istio-system --from-file=samples/certs/ca-cert.pem --from-file=samples/certs/ca-key.pem --from-file=samples/certs/root-cert.pem --from-file=samples/certs/cert-chain.pem
    $ istioctl manifest apply --context=$CTX_CLUSTER1 \
      -f install/kubernetes/operator/examples/multicluster/values-istio-multicluster-primary.yaml
    {{< /text >}}

    {{< warning >}}
    注意网关地址设置为 `0.0.0.0`。这些是临时的占位值，在下文章节集群部署后，将被更新为 `cluster1` 和 `cluster2` 的网关公网 IP。
    {{< /warning >}}

    等待 `cluster1` 中的 Istio pods 就绪：

    {{< text bash >}}
    $ kubectl get pods --context=$CTX_CLUSTER1 -n istio-system
    NAME                                      READY   STATUS    RESTARTS   AGE
    istio-citadel-55d8b59798-6hnx4            1/1     Running   0          83s
    istio-galley-c74b77787-lrtr5              2/2     Running   0          82s
    istio-ingressgateway-684f5df677-shzhm     1/1     Running   0          83s
    istio-pilot-5495bc8885-2rgmf              2/2     Running   0          82s
    istio-policy-69cdf5db4c-x4sct             2/2     Running   2          83s
    istio-sidecar-injector-5749cf7cfc-pgd95   1/1     Running   0          82s
    istio-telemetry-646db5ddbd-gvp6l          2/2     Running   1          83s
    prometheus-685585888b-4tvf7               1/1     Running   0          83s
    {{< /text >}}

1. 创建一个 ingress 网关访问 `cluster2` 中的服务：

    {{< text bash >}}
    $ kubectl apply --context=$CTX_CLUSTER1 -f - <<EOF
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

    本例 `Gateway` 配置 443 端口来将流经的入口流量导向请求 SNI 头中指明的目标服务，其中 SNI 的顶级域名为 _local_（譬如： [Kubernetes DNS 域名](https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/)）。
    从源至目标 sidecar，始终使用双向 TLS 连接。

    尽管应用于 `cluster1`，该网关实例也会影响 `cluster2`，因为两个集群通过同一个 Pilot 通信。

1.  确定 `cluster1` 的 ingress IP 和端口。

    1.   设置 `kubectl` 的当前上下文为 `CTX_CLUSTER1`

        {{< text bash >}}
        $ export ORIGINAL_CONTEXT=$(kubectl config current-context)
        $ kubectl config use-context $CTX_CLUSTER1
        {{< /text >}}

    1.   按照[确定 ingress IP 和端口](/zh/docs/tasks/traffic-management/ingress/ingress-control/#determining-the-ingress-i-p-and-ports)中的说明，设置环境变量 `INGRESS_HOST` 及 `SECURE_INGRESS_PORT`。

    1.  恢复之前的 `kubectl` 上下文：

        {{< text bash >}}
        $ kubectl config use-context $ORIGINAL_CONTEXT
        $ unset ORIGINAL_CONTEXT
        {{< /text >}}

    1.  打印 `INGRESS_HOST` 及 `SECURE_INGRESS_PORT`：

        {{< text bash >}}
        $ echo The ingress gateway of cluster1: address=$INGRESS_HOST, port=$SECURE_INGRESS_PORT
        {{< /text >}}

1.  更新网格网络配置中的网关地址。编辑 `istio` `ConfigMap`：

    {{< text bash >}}
    $ kubectl edit cm -n istio-system --context=$CTX_CLUSTER1 istio
    {{< /text >}}

    将网关地址和 `network1` 的端口分别更新为 `cluster1` 的 ingress 主机和端口，然后保存并退出。注意该地址在配置文件中出现两次，第二次位于 `values.yaml:` 下方。

    一旦保存，Pilot 将自动读取更新后的网络配置。

### 安装集群 2{#setup-cluster-2}

1. 输出 `cluster1` 的网关地址：

    {{< text bash >}}
    $ export LOCAL_GW_ADDR=$(kubectl get --context=$CTX_CLUSTER1 svc --selector=app=istio-ingressgateway \
        -n istio-system -o jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}') && echo ${LOCAL_GW_ADDR}
    {{< /text >}}

    该命令将网关地址设置为网关的公共 IP 并显示。

    {{< warning >}}
    若负载均衡配置没有设置 IP 地址，命令将执行失败。DNS 域名支持尚未实现，亟待解决。
    {{< /warning >}}

1. 在 `cluster2` 中部署 Istio：

    {{< text bash >}}
    $ kubectl create --context=$CTX_CLUSTER2 ns istio-system
    $ kubectl create --context=$CTX_CLUSTER2 secret generic cacerts -n istio-system --from-file=samples/certs/ca-cert.pem --from-file=samples/certs/ca-key.pem --from-file=samples/certs/root-cert.pem --from-file=samples/certs/cert-chain.pem
    $ CLUSTER_NAME=$(kubectl --context=$CTX_CLUSTER2 config view --minify=true -o jsonpath='{.clusters[].name}')
    $ istioctl manifest apply --context=$CTX_CLUSTER2 \
      --set profile=remote \
      --set values.global.mtls.enabled=true \
      --set values.gateways.enabled=true \
      --set values.security.selfSigned=false \
      --set values.global.createRemoteSvcEndpoints=true \
      --set values.global.remotePilotCreateSvcEndpoint=true \
      --set values.global.remotePilotAddress=${LOCAL_GW_ADDR} \
      --set values.global.remotePolicyAddress=${LOCAL_GW_ADDR} \
      --set values.global.remoteTelemetryAddress=${LOCAL_GW_ADDR} \
      --set values.gateways.istio-ingressgateway.env.ISTIO_META_NETWORK="network2" \
      --set values.global.network="network2" \
      --set values.global.multiCluster.clusterName=${CLUSTER_NAME} \
      --set autoInjection.enabled=true
    {{< /text >}}

    等待 `cluster2` 中的 Istio pods 就绪，`istio-ingressgateway` 除外。

    {{< text bash >}}
    $ kubectl get pods --context=$CTX_CLUSTER2 -n istio-system -l istio!=ingressgateway
    NAME                                      READY   STATUS    RESTARTS   AGE
    istio-citadel-55d8b59798-nlk2z            1/1     Running   0          26s
    istio-sidecar-injector-5749cf7cfc-s6r7p   1/1     Running   0          25s
    {{< /text >}}

    {{< warning >}}
    `istio-ingressgateway` 无法就绪，直到在 `cluster1` 的 Istio 控制面板中配置好 watch `cluster2`。下一节执行该操作。
    {{< /warning >}}

1.  确定 `cluster2` 的 ingress IP 和口。

    1.   设置 `kubectl` 的当前上下文为 `CTX_CLUSTER2`

        {{< text bash >}}
        $ export ORIGINAL_CONTEXT=$(kubectl config current-context)
        $ kubectl config use-context $CTX_CLUSTER2
        {{< /text >}}

    1.   按照[确定 ingress IP 和端口](/zh/docs/tasks/traffic-management/ingress/ingress-control/#determining-the-ingress-i-p-and-ports)中的说明，设置环境变量 `INGRESS_HOST` 和 `SECURE_INGRESS_PORT`。

    1.  恢复之前的 `kubectl` 上下文：

        {{< text bash >}}
        $ kubectl config use-context $ORIGINAL_CONTEXT
        $ unset ORIGINAL_CONTEXT
        {{< /text >}}

    1.  打印 `INGRESS_HOST` 和 `SECURE_INGRESS_PORT`：

        {{< text bash >}}
        $ echo The ingress gateway of cluster2: address=$INGRESS_HOST, port=$SECURE_INGRESS_PORT
        {{< /text >}}

1.  更新网格网络配置中的网关地址。 编辑 `istio` `ConfigMap`：

    {{< text bash >}}
    $ kubectl edit cm -n istio-system --context=$CTX_CLUSTER1 istio
    {{< /text >}}

    将 `network2` 的网关地址和端口分别更新为 `cluster2` 的 ingress 主机和端口，然后保存并退出。注意该地址在配置文件中出现两次，第二次位于 `values.yaml:` 下方。

    一旦保存，Pilot 将自动读取更新后的网络配置。

1. 准备环境变量，构建服务账户 `istio-reader-service-account` 的配置文件 `n2-k8s-config`：

    {{< text bash >}}
    $ CLUSTER_NAME=$(kubectl --context=$CTX_CLUSTER2 config view --minify=true -o jsonpath='{.clusters[].name}')
    $ SERVER=$(kubectl --context=$CTX_CLUSTER2 config view --minify=true -o jsonpath='{.clusters[].cluster.server}')
    $ SECRET_NAME=$(kubectl --context=$CTX_CLUSTER2 get sa istio-reader-service-account -n istio-system -o jsonpath='{.secrets[].name}')
    $ CA_DATA=$(kubectl get --context=$CTX_CLUSTER2 secret ${SECRET_NAME} -n istio-system -o jsonpath="{.data['ca\.crt']}")
    $ TOKEN=$(kubectl get --context=$CTX_CLUSTER2 secret ${SECRET_NAME} -n istio-system -o jsonpath="{.data['token']}" | base64 --decode)
    {{< /text >}}

    {{< idea >}}
    在许多系统中，`base64 --decode` 可以替换为 `openssl enc -d -base64 -A`。
    {{< /idea >}}

1. 在工作目录中创建文件 `n2-k8s-config`：

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

### 启动 watching 集群 2{start-watching-cluster-2}

1.  执行下面命令，添加并标记 Kubernetes `cluster2` 的 secret。
    执行完这些命令，`cluster1` 中的 Istio Pilot 将开始 watching `cluster2` 的服务和实例，如同对待 `cluster1` 一样。

    {{< text bash >}}
    $ kubectl create --context=$CTX_CLUSTER1 secret generic n2-k8s-secret --from-file n2-k8s-config -n istio-system
    $ kubectl label --context=$CTX_CLUSTER1 secret n2-k8s-secret istio/multiCluster=true -n istio-system
    {{< /text >}}

1.  等待 `istio-ingressgateway` 就绪：

    {{< text bash >}}
    $ kubectl get pods --context=$CTX_CLUSTER2 -n istio-system -l istio=ingressgateway
    NAME                                    READY     STATUS    RESTARTS   AGE
    istio-ingressgateway-5c667f4f84-bscff   1/1       Running   0          16m
    {{< /text >}}

现在，`cluster1` 和 `cluster2` 均已安装完成，可以部署一个案例服务。

## 部署案例服务{#deploy-example-service}

如上图所示，部署两个 `helloworld` 服务，一个运行在 `cluster1` 中，另一个运行在 `cluster2` 中。
二者的区别是 `helloworld` 镜像的版本不同。

### 在集群 2 中部署 helloworld v2{#deploy-helloworld-v2-in-cluster-2}

1. 创建一个 `sample` 命名空间，用 label 标识开启 sidecar 自动注入：

    {{< text bash >}}
    $ kubectl create --context=$CTX_CLUSTER2 ns sample
    $ kubectl label --context=$CTX_CLUSTER2 namespace sample istio-injection=enabled
    {{< /text >}}

1. 部署 `helloworld v2`：

    {{< text bash >}}
    $ kubectl create --context=$CTX_CLUSTER2 -f @samples/helloworld/helloworld.yaml@ -l app=helloworld -n sample
    $ kubectl create --context=$CTX_CLUSTER2 -f @samples/helloworld/helloworld.yaml@ -l version=v2 -n sample
    {{< /text >}}

1. 确认 `helloworld v2` 正在运行：

    {{< text bash >}}
    $ kubectl get po --context=$CTX_CLUSTER2 -n sample
    NAME                             READY     STATUS    RESTARTS   AGE
    helloworld-v2-7dd57c44c4-f56gq   2/2       Running   0          35s
    {{< /text >}}

### 在集群 1 中部署 helloworld v1{#deploy-helloworld-v1-in-cluster-1}

1. 创建一个 `sample` 命名空间，用 label 标识开启 sidecar 自动注入：

    {{< text bash >}}
    $ kubectl create --context=$CTX_CLUSTER1 ns sample
    $ kubectl label --context=$CTX_CLUSTER1 namespace sample istio-injection=enabled
    {{< /text >}}

1. 部署 `helloworld v1`：

    {{< text bash >}}
    $ kubectl create --context=$CTX_CLUSTER1 -f @samples/helloworld/helloworld.yaml@ -l app=helloworld -n sample
    $ kubectl create --context=$CTX_CLUSTER1 -f @samples/helloworld/helloworld.yaml@ -l version=v1 -n sample
    {{< /text >}}

1. 确认 `helloworld v1` 正在运行：

    {{< text bash >}}
    $ kubectl get po --context=$CTX_CLUSTER1 -n sample
    NAME                            READY     STATUS    RESTARTS   AGE
    helloworld-v1-d4557d97b-pv2hr   2/2       Running   0          40s
    {{< /text >}}

### 跨集群路由实践{#cross-cluster-routing-in-action}

为了演示访问 `helloworld` 服务的流量如何跨两个集群进行分发，我们从网格内的另一个 `sleep` 服务请求 `helloworld` 服务。

1. 在两个集群中均部署 `sleep` 服务：

    {{< text bash >}}
    $ kubectl apply --context=$CTX_CLUSTER1 -f @samples/sleep/sleep.yaml@ -n sample
    $ kubectl apply --context=$CTX_CLUSTER2 -f @samples/sleep/sleep.yaml@ -n sample
    {{< /text >}}

1. 等待 `sleep` 服务启动：

    {{< text bash >}}
    $ kubectl get po --context=$CTX_CLUSTER1 -n sample -l app=sleep
    sleep-754684654f-n6bzf           2/2     Running   0          5s
    {{< /text >}}

    {{< text bash >}}
    $ kubectl get po --context=$CTX_CLUSTER2 -n sample -l app=sleep
    sleep-754684654f-dzl9j           2/2     Running   0          5s
    {{< /text >}}

1. 从 `cluster1` 请求 `helloworld.sample` 服务若干次：

    {{< text bash >}}
    $ kubectl exec --context=$CTX_CLUSTER1 -it -n sample -c sleep $(kubectl get pod --context=$CTX_CLUSTER1 -n sample -l app=sleep -o jsonpath='{.items[0].metadata.name}') -- curl helloworld.sample:5000/hello
    {{< /text >}}

1. 从 `cluster2` 请求 `helloworld.sample` 服务若干次：

    {{< text bash >}}
    $ kubectl exec --context=$CTX_CLUSTER2 -it -n sample -c sleep $(kubectl get pod --context=$CTX_CLUSTER2 -n sample -l app=sleep -o jsonpath='{.items[0].metadata.name}') -- curl helloworld.sample:5000/hello
    {{< /text >}}

如果设置正确，访问 `helloworld.sample` 的流量将在 `cluster1` 和 `cluster2` 之间分发，返回的响应结果或者为 `v1` 或者为 `v2`：

{{< text plain >}}
Hello version: v2, instance: helloworld-v2-758dd55874-6x4t8
Hello version: v1, instance: helloworld-v1-86f77cd7bd-cpxhv
{{< /text >}}

也可以通过打印 sleep 的 `istio-proxy` 容器日志，验证访问 endpoints 的 IP 地址。

{{< text bash >}}
$ kubectl logs --context=$CTX_CLUSTER1 -n sample $(kubectl get pod --context=$CTX_CLUSTER1 -n sample -l app=sleep -o jsonpath='{.items[0].metadata.name}') istio-proxy
[2018-11-25T12:37:52.077Z] "GET /hello HTTP/1.1" 200 - 0 60 190 189 "-" "curl/7.60.0" "6e096efe-f550-4dfa-8c8c-ba164baf4679" "helloworld.sample:5000" "192.23.120.32:15443" outbound|5000||helloworld.sample.svc.cluster.local - 10.20.194.146:5000 10.10.0.89:59496 -
[2018-11-25T12:38:06.745Z] "GET /hello HTTP/1.1" 200 - 0 60 171 170 "-" "curl/7.60.0" "6f93c9cc-d32a-4878-b56a-086a740045d2" "helloworld.sample:5000" "10.10.0.90:5000" outbound|5000||helloworld.sample.svc.cluster.local - 10.20.194.146:5000 10.10.0.89:59646 -
{{< /text >}}

在 `cluster1` 中，当请求分发给 v2 时，`cluster2` 的网关 IP（`192.23.120.32:15443`）被记录，当请求分发给 v1 时，`cluster1` 的实例 IP（`10.10.0.90:5000`）被记录。

{{< text bash >}}
$ kubectl logs --context=$CTX_CLUSTER2 -n sample $(kubectl get pod --context=$CTX_CLUSTER2 -n sample -l app=sleep -o jsonpath='{.items[0].metadata.name}') istio-proxy
[2019-05-25T08:06:11.468Z] "GET /hello HTTP/1.1" 200 - "-" 0 60 177 176 "-" "curl/7.60.0" "58cfb92b-b217-4602-af67-7de8f63543d8" "helloworld.sample:5000" "192.168.1.246:15443" outbound|5000||helloworld.sample.svc.cluster.local - 10.107.117.235:5000 10.32.0.10:36840 -
[2019-05-25T08:06:12.834Z] "GET /hello HTTP/1.1" 200 - "-" 0 60 181 180 "-" "curl/7.60.0" "ce480b56-fafd-468b-9996-9fea5257cb1e" "helloworld.sample:5000" "10.32.0.9:5000" outbound|5000||helloworld.sample.svc.cluster.local - 10.107.117.235:5000 10.32.0.10:36886 -
{{< /text >}}

在 `cluster2` 中，当请求分发给 v1 时，`cluster1` 的网关 IP （`192.168.1.246:15443`）被记录，当请求分发给 v2 时，`cluster2` 的网关 IP（`10.32.0.9:5000`）被记录。

## 清除{#cleanup}

执行如下命令清除示例服务__以及__ Istio 组件。

清除集群 `cluster2`：

{{< text bash >}}
$ istioctl manifest generate --context=$CTX_CLUSTER2 \
  --set profile=remote \
  --set values.global.mtls.enabled=true \
  --set values.gateways.enabled=true \
  --set values.security.selfSigned=false \
  --set values.global.createRemoteSvcEndpoints=true \
  --set values.global.remotePilotCreateSvcEndpoint=true \
  --set values.global.remotePilotAddress=${LOCAL_GW_ADDR} \
  --set values.global.remotePolicyAddress=${LOCAL_GW_ADDR} \
  --set values.global.remoteTelemetryAddress=${LOCAL_GW_ADDR} \
  --set values.gateways.istio-ingressgateway.env.ISTIO_META_NETWORK="network2" \
  --set values.global.network="network2" \
  --set autoInjection.enabled=true | kubectl --context=$CTX_CLUSTER2 delete -f -
$ kubectl delete --context=$CTX_CLUSTER2 ns sample
$ rm n2-k8s-config
$ unset CTX_CLUSTER2 CLUSTER_NAME SERVER SECRET_NAME CA_DATA TOKEN INGRESS_HOST SECURE_INGRESS_PORT INGRESS_PORT LOCAL_GW_ADDR
{{< /text >}}

清除集群 `cluster1`：

{{< text bash >}}
$ istioctl manifest generate --context=$CTX_CLUSTER1 \
  -f install/kubernetes/operator/examples/multicluster/values-istio-multicluster-primary.yaml | kubectl --context=$CTX_CLUSTER1 delete -f -
$ kubectl delete --context=$CTX_CLUSTER1 ns sample
$ unset CTX_CLUSTER1
$ rm n2-k8s-config
{{< /text >}}
