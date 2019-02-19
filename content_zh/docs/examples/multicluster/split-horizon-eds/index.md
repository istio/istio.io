---
title: 集群感知的服务路由
description: 利用 Istio 的水平分割 EDS 来创建多集群网格。
weight: 85
keywords: [kubernetes,multicluster]
---

这个示例展示了如何使用[单一控制平面拓扑](/zh/docs/concepts/multicluster-deployments/#单一控制平面拓扑)配置一个多集群网格，并使用 Istio 的`水平分割 EDS（Endpoints Discovery Service，Endpoint 发现服务）`特性（在 Istio 1.1 中引入），通过 ingress gateway 将服务请求路由到 remote 集群。水平分割 EDS 使 Istio 可以基于请求来源的位置，将其路由到不同的 endpoint。

按照此示例中的说明，您将设置一个两集群网格，如下图所示：

  {{< image width="80%" ratio="36.01%"
  link="/docs/examples/multicluster/split-horizon-eds/diagram.svg"
  caption="单个 Istio 控制平面配置水平分割 EDS，跨越多个 Kubernetes 集群" >}}

 `local` 集群将运行 Istio Pilot 和其它 Istio 控制平面组件，而 `remote` 集群仅运行 Istio Citadel、Sidecar Injector 和 Ingress gateway。不需要 VPN 连接，不同集群中的工作负载之间也无需直接网络访问。

## 开始之前

除了安装 Istio 的先决条件之外，此示例还需要以下条件：

* 两个 Kubernetes 集群（称之为 `local` 和 `remote`）。

    {{< warning >}}
    为了运行此配置，要求必须可以从 `local` 集群访问 `remote` 集群的 Kubernetes API server。
    {{< /warning >}}

* `kubectl` 命令使用 `--context` 参数，同时访问 `local` 和 `remote` 集群。请使用下列命令列出您的 context：

    {{< text bash >}}
    $ kubectl config get-contexts
    CURRENT   NAME       CLUSTER    AUTHINFO       NAMESPACE
              cluster1   cluster1   user@foo.com   default
              cluster2   cluster2   user@foo.com   default
    {{< /text >}}

* 使用配置的 context 名称导出以下环境变量:

    {{< text bash >}}
    $ export CTX_LOCAL=<KUBECONFIG_LOCAL_CONTEXT_NAME>
    $ export CTX_REMOTE=<KUBECONFIG_REMOTE_CONTEXT_NAME>
    {{< /text >}}

## 多集群设置示例

在此示例中，您将安装对控制平面和应用程序 pod 都启用了双向 TLS 的 Istio。为了共享根 CA，您将使用同一个来自 Istio 示例目录的证书，在 `local` 和 `remote` 集群上创建一个相同的 `cacerts` secret。

下面的说明还设置了 `remote` 集群，包含一个无 selector 的 service 和具有 `local` Istio ingress gateway 地址的 `istio-pilot.istio-system` endpoint。这将用于通过 ingress gateway 安全地访问 `local` pilot，而无需双向 TLS 终止。

### 配置 local 集群

1. 定义网格网络：

    默认情况下 Istio 的 `global.meshNetworks` 值为空，但是您需要对其进行修改以为 `remote` 集群上的 endpoint 定义一个新的网络。修改 `install/kubernetes/helm/istio/values.yaml` 并添加一个 `network2` 定义：

    {{< text yaml >}}
    meshNetworks:
      network2:
        endpoints:
        - fromRegistry: remote_kubecfg
        gateways:
        - address: 0.0.0.0
          port: 443
    {{< /text >}}

    请注意，gateway address 被设置为 `0.0.0.0`。这是一个临时占位符，稍后将被更新为 `remote` 集群 gateway 的公共 IP 地址，此 gateway 将在下一小节中部署。

1. 使用 Helm 创建 Istio `local` deployment YAML：

    {{< text bash >}}
    $ helm template --namespace=istio-system \
    --values install/kubernetes/helm/istio/values.yaml \
    --set global.mtls.enabled=true \
    --set global.enableTracing=false \
    --set security.selfSigned=false \
    --set mixer.telemetry.enabled=false \
    --set mixer.policy.enabled=false \
    --set global.useMCP=false \
    --set global.controlPlaneSecurityEnabled=true \
    --set gateways.istio-egressgateway.enabled=false \
    --set global.meshExpansion.enabled=true \
    install/kubernetes/helm/istio > istio-auth.yaml
    {{< /text >}}

1. 部署 Istio 到 `local` 集群：

    {{< text bash >}}
    $ kubectl create --context=$CTX_LOCAL ns istio-system
    $ kubectl create --context=$CTX_LOCAL secret generic cacerts -n istio-system --from-file=samples/certs/ca-cert.pem --from-file=samples/certs/ca-key.pem --from-file=samples/certs/root-cert.pem --from-file=samples/certs/cert-chain.pem
    $ for i in install/kubernetes/helm/istio-init/files/crd*yaml; do kubectl apply --context=$CTX_LOCAL -f $i; done
    $ kubectl create --context=$CTX_LOCAL -f istio-auth.yaml
    {{< /text >}}

    通过检查 `local` pod 的状态等待其被拉起：

    {{< text bash >}}
    $ kubectl get pods --context=$CTX_LOCAL -n istio-system
    {{< /text >}}

### 设置 remote 集群

1. 导出 `local` gateway 地址：

    {{< text bash >}}
    $ export LOCAL_GW_ADDR=$(kubectl get --context=$CTX_LOCAL svc --selector=app=istio-ingressgateway \
        -n istio-system -o jsonpath="{.items[0].status.loadBalancer.ingress[0].ip}")
    {{< /text >}}

    此命令将值设置为 gateway 的公共 IP，但请注意，您也可以将其设置为一个 DNS 名称（如果有）。

1. 使用 Helm 创建 Istio `remote` deployment YAML：

    {{< text bash >}}
    $ helm template install/kubernetes/helm/istio-remote \
      --name istio-remote \
      --namespace=istio-system \
      --set global.mtls.enabled=true \
      --set global.enableTracing=false \
      --set gateways.enabled=true \
      --set gateways.istio-egressgateway.enabled=false \
      --set gateways.istio-ingressgateway.enabled=true \
      --set security.selfSigned=false \
      --set global.controlPlaneSecurityEnabled=true \
      --set global.createRemoteSvcEndpoints=true \
      --set global.remotePilotCreateSvcEndpoint=true \
      --set global.remotePilotAddress=${LOCAL_GW_ADDR} \
      --set global.disablePolicyChecks=true \
      --set global.policyCheckFailOpen=true \
      --set gateways.istio-ingressgateway.env.ISTIO_META_NETWORK="network2" \
      --set global.network="network2" > istio-remote-auth.yaml
    {{< /text >}}

1. 部署 Istio 到 `remote` 集群：

    {{< text bash >}}
    $ kubectl create --context=$CTX_REMOTE ns istio-system
    $ kubectl create --context=$CTX_REMOTE secret generic cacerts -n istio-system --from-file=samples/certs/ca-cert.pem --from-file=samples/certs/ca-key.pem --from-file=samples/certs/root-cert.pem --from-file=samples/certs/cert-chain.pem
    $ kubectl create --context=$CTX_REMOTE -f istio-remote-auth.yaml
    {{< /text >}}

    通过检查 `remote` pod 的状态等待其被拉起：

    {{< text bash >}}
    $ kubectl get pods --context=$CTX_REMOTE -n istio-system
    {{< /text >}}

1. 更新网格网络配置中的 gateway 地址：

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

1. 准备环境变量以构建 service account `istio-multi` 的 `remote_kubecfg` 文件：

    {{< text bash >}}
    $ CLUSTER_NAME=$(kubectl --context=$CTX_REMOTE config view --minify=true -o "jsonpath={.clusters[].name}")
    $ SERVER=$(kubectl --context=$CTX_REMOTE config view --minify=true -o "jsonpath={.clusters[].cluster.server}")
    $ SECRET_NAME=$(kubectl --context=$CTX_REMOTE get sa istio-multi -n istio-system -o jsonpath='{.secrets[].name}')
    $ CA_DATA=$(kubectl get --context=$CTX_REMOTE secret ${SECRET_NAME} -n istio-system -o "jsonpath={.data['ca\.crt']}")
    $ TOKEN=$(kubectl get --context=$CTX_REMOTE secret ${SECRET_NAME} -n istio-system -o "jsonpath={.data['token']}" | base64 --decode)
    {{< /text >}}

    {{< idea >}}
    许多系统上使用 `openssl enc -d -base64 -A` 替代 `base64 --decode`。
    {{< /idea >}}

1. 在工作目录创建 `remote_kubecfg` 文件：

    {{< text bash >}}
    $ cat <<EOF > remote_kubecfg
    apiVersion: v1
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
    kind: Config
    preferences: {}
    users:
      - name: ${CLUSTER_NAME}
        user:
          token: ${TOKEN}
    EOF
    {{< /text >}}

### 开始监听 remote 集群

执行下列命令，添加并标记 `remote` Kubernetes 的 secret。执行这些命令之后，local Istio Pilot 将开始监听 `remote` 集群的 service 和 instance，就像在 `local` 集群中一样。

{{< text bash >}}
$ kubectl create --context=$CTX_LOCAL secret generic iks --from-file remote_kubecfg -n istio-system
$ kubectl label --context=$CTX_LOCAL secret iks istio/multiCluster=true -n istio-system
{{< /text >}}

现在您已经设置了 `local` 和 `remote` 集群，可以开始部署示例 service。

## 示例 service

在这个实例中，您将了解到一个 service 的流量是如何被分发到 local endpoint 和 remote gateway。如上图所示，您将为 `helloworld` service 部署两个实例，一个在 `local` 集群，另一个在 `remote` 集群。两个实例的区别在于其 `helloworld` 镜像的版本。

### 在 remote 集群部署 helloworld v2

1. 使用 sidecar 自动注入标签创建一个 `sample` namespace：

    {{< text bash >}}
    $ kubectl create --context=$CTX_REMOTE ns sample
    $ kubectl label --context=$CTX_REMOTE namespace sample istio-injection=enabled
    {{< /text >}}

1. 使用以下内容创建 `helloworld-v2.yaml` 文件：

    {{< text yaml >}}
    apiVersion: v1
    kind: Service
    metadata:
      name: helloworld
      labels:
        app: helloworld
    spec:
      ports:
      - port: 5000
        name: http
      selector:
        app: helloworld
    ---
    apiVersion: extensions/v1beta1
    kind: Deployment
    metadata:
      name: helloworld-v2
    spec:
      replicas: 1
      template:
        metadata:
          labels:
            app: helloworld
            version: v2
        spec:
          containers:
          - name: helloworld
            image: istio/examples-helloworld-v2
            imagePullPolicy: IfNotPresent
            ports:
            - containerPort: 5000
    {{< /text >}}

1. 部署此文件：

    {{< text bash >}}
    $ kubectl create --context=$CTX_REMOTE -f helloworld-v2.yaml -n sample
    {{< /text >}}

### 在 local 集群部署 helloworld v1

1. 使用 sidecar 自动注入标签创建一个 `sample` namespace：

    {{< text bash >}}
    $ kubectl create --context=$CTX_LOCAL ns sample
    $ kubectl label --context=$CTX_LOCAL namespace sample istio-injection=enabled
    {{< /text >}}

1. 使用以下内容创建 `helloworld-v1.yaml` 文件：

    {{< text yaml >}}
    apiVersion: v1
    kind: Service
    metadata:
      name: helloworld
      labels:
        app: helloworld
    spec:
      ports:
      - port: 5000
        name: http
      selector:
        app: helloworld
    ---
    apiVersion: extensions/v1beta1
    kind: Deployment
    metadata:
      name: helloworld-v1
    spec:
      replicas: 1
      template:
        metadata:
          labels:
            app: helloworld
            version: v1
        spec:
          containers:
          - name: helloworld
            image: istio/examples-helloworld-v1
            imagePullPolicy: IfNotPresent
            ports:
            - containerPort: 5000
    {{< /text >}}

1. 使用下列内容创建 `helloworld-gateway.yaml` 文件：

    {{< text yaml >}}
    apiVersion: networking.istio.io/v1alpha3
    kind: Gateway
    metadata:
      name: helloworld-gateway
      namespace: sample
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
        - "*"
    {{< /text >}}

    虽然是本地部署，这个 Gateway 实例仍然会影响 `remote` 集群，方法是将其配置为允许相关 remote service（基于 SNI）通过，但保持从源到目标 sidecar 的双向 TLS。

1. 部署此文件：

    {{< text bash >}}
    $ kubectl create --context=$CTX_LOCAL -f helloworld-v1.yaml -n sample
    $ kubectl create --context=$CTX_LOCAL -f helloworld-gateway.yaml -n sample
    {{< /text >}}

### 横向分割 EDS 实战

我们将从另一个集群中 `sleep` service 请求 `helloworld.sample` service。

1. 部署 `sleep` service：

    {{< text bash >}}
    $ kubectl create --context=$CTX_LOCAL -f samples/sleep/sleep.yaml -n sample
    {{< /text >}}

1. 多次请求 `helloworld.sample` service：

    {{< text bash >}}
    $ kubectl exec --context=$CTX_LOCAL -it -n sample $(kubectl get pod --context=$CTX_LOCAL -n sample -l app=sleep -o jsonpath={.items[0].metadata.name}) -- curl helloworld.sample:5000/hello
    {{< /text >}}

如果设置正确，到 `helloworld.sample` service 的流量将在 local 和 remote 实例之间进行分发，导致响应 body 中 `v1` 或 `v2` 都可能出现。

{{< text bash >}}
$ kubectl exec --context=$CTX_LOCAL -it -n sample $(kubectl get pod --context=$CTX_LOCAL -n sample -l app=sleep -o jsonpath={.items[0].metadata.name}) -- curl helloworld.sample:5000/hello
Defaulting container name to sleep.
Use 'kubectl describe pod/sleep-57f9d6fd6b-q4k4h -n sample' to see all of the containers in this pod.
Hello version: v2, instance: helloworld-v2-758dd55874-6x4t8
{{< /text >}}

{{< text bash >}}
$ kubectl exec --context=$CTX_LOCAL -it -n sample $(kubectl get pod --context=$CTX_LOCAL -n sample -l app=sleep -o jsonpath={.items[0].metadata.name}) -- curl helloworld.sample:5000/hello
Defaulting container name to sleep.
Use 'kubectl describe pod/sleep-57f9d6fd6b-q4k4h -n sample' to see all of the containers in this pod.
Hello version: v1, instance: helloworld-v1-86f77cd7bd-cpxhv
{{< /text >}}

您可以通过打印 sleep pod 的 `istio-proxy` 容器日志来验证访问的 endpoint 的 IP 地址。

{{< text bash >}}
$ kubectl logs --context=$CTX_LOCAL -n sample $(kubectl get pod --context=$CTX_LOCAL -n sample -l app=sleep -o jsonpath={.items[0].metadata.name}) istio-proxy
[2018-11-25T12:37:52.077Z] "GET /hello HTTP/1.1" 200 - 0 60 190 189 "-" "curl/7.60.0" "6e096efe-f550-4dfa-8c8c-ba164baf4679" "helloworld.sample:5000" "192.23.120.32:443" outbound|5000||helloworld.sample.svc.cluster.local - 10.20.194.146:5000 10.10.0.89:59496 -
[2018-11-25T12:38:06.745Z] "GET /hello HTTP/1.1" 200 - 0 60 171 170 "-" "curl/7.60.0" "6f93c9cc-d32a-4878-b56a-086a740045d2" "helloworld.sample:5000" "10.10.0.90:5000" outbound|5000||helloworld.sample.svc.cluster.local - 10.20.194.146:5000 10.10.0.89:59646 -
{{< /text >}}

v2 被调用时将记录 remote gateway IP  `192.23.120.32:443`，v1 被调用时将记录 local 实例 IP `10.10.0.90:5000`。

## 清理

执行下列命令清理 demo service __和__ Istio 组件。

清理 `remote` 集群：

{{< text bash >}}
$ kubectl delete --context=$CTX_REMOTE -f istio-remote-auth.yaml
$ kubectl delete --context=$CTX_REMOTE ns istio-system
$ kubectl delete --context=$CTX_REMOTE -f helloworld-v2.yaml -n sample
$ kubectl delete --context=$CTX_REMOTE ns sample
{{< /text >}}

清理 `local` 集群：

{{< text bash >}}
$ kubectl delete --context=$CTX_LOCAL -f istio-auth.yaml
$ kubectl delete --context=$CTX_LOCAL ns istio-system
$ helm delete --purge --kube-context=$CTX_LOCAL istio-init
$ kubectl delete --context=$CTX_LOCAL -f helloworld-v1.yaml -n sample
$ kubectl delete --context=$CTX_LOCAL -f samples/sleep/sleep.yaml -n sample
$ kubectl delete --context=$CTX_LOCAL ns sample
{{< /text >}}
