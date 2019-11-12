---
title: 控制平面副本集
description: 通过控制平面副本集实例，在多个 Kubernetes 集群上安装 Istio 网格。
weight: 2
aliases:
    - /zh/docs/setup/kubernetes/multicluster-install/gateways/
    - /zh/docs/examples/multicluster/gateways/
    - /zh/docs/tasks/multicluster/gateways/
    - /zh/docs/setup/kubernetes/install/multicluster/gateways/
keywords: [kubernetes,multicluster,gateway]
---

请参照本指南安装具有副本集 [控制平面](/zh/docs/setup/deployment-models/#control-plane-models) 实例的
Istio [多集群部署](/zh/docs/setup/deployment-models/#multiple-clusters)，并在每个群集中使用 gateway 来提供跨集群连接服务。

在此配置中，每个集群都使用它自己的 Istio 控制平面来完成安装，并管理自己的 endpoint，
而不是使用共享的 Istio 控制平面来管理网格。
出于以下目的，所有群集都在共同的管理控制下，执行策略与安全行为

通过共享服务副本及命名空间，并在所有群集中使用公共的根证书，可以在群集中实现一个 Istio 服务网格。
跨集群通信基于各个集群的 Istio gateway。

{{< image width="80%" link="./multicluster-with-gateways.svg" caption="使用 Istio Gateway 跨越多个基于 Kubernetes 集群的 Istio 网格并最终到达远端 pod" >}}

## 前提条件{#prerequisites}

* 两个以上 Kubernetes 集群，且版本为：{{< supported_kubernetes_versions >}}。

* 有权限在 **每个** Kubernetes 集群上，[部署 Istio 控制平面](/zh/docs/setup/install/istioctl/)。

* 每个集群 `istio-ingressgateway` 服务的 IP 地址，必须允许其它集群访问，最好使用 4 层负载均衡（NLB）。
  有些云服务商不支持负载均衡或者需要特别注明才能使用。所以，请查阅您的云服务商的文档，为负载均衡类型的服务对象启用 NLB。
  在不支持负载均衡的平台上部署时，可能需要修改健康检查，使得负载均衡对象可以注册为 ingress gateway。

* 一个 **根 CA**。跨集群的服务通信必须使用双向 TLS 连接。
  为了在集群之间使用双向 TLS 通信，每个集群的 Citadel 都将由共享的根 CA 生成中间 CA 凭据。
  为方便演示，您在安装 Istio 时，可以使用 `samples/certs` 目录下的一个根 CA 证书样本。

## 在每个集群中部署 Istio 控制平面{#deploy-the-Istio-control-plane-in-each-cluster}

1. 从组织的根 CA 为每个集群的 Citadel 生成中间 CA 证书。
   共享的根 CA 支持跨集群的双向 TLS 通信。

    为方便演示，后面两个集群的演示都将使用 Istio 样本目录下的证书。
    在实际部署中，一般会使用一个公共根 CA 为每个集群签发不同的 CA 证书。

1. 想要在 **每个集群** 上部署相同的 Istio 控制平面，请运行下面的命令：

    {{< tip >}}
    请确保当前用户拥有集群的管理员（`cluster-admin`）权限。
    如果没有权限，请授权给它。例如，在 GKE 平台下，可以使用以下命令授权：

    {{< text bash >}}
    $ kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin --user="$(gcloud config get-value core/account)"
    {{< /text >}}

    {{< /tip >}}

    * 使用类似于下面的命令，为生成的 CA 证书创建 Kubernetes secret。了解详情，请参见 [CA 证书](/zh/docs/tasks/security/plugin-ca-cert/#plugging-in-the-existing-certificate-and-key)。

        {{< warning >}}
        示例目录中的根证书和中间证书已被广泛分发和知道。
        **千万不要** 在生成环境中使用这些证书，这样集群就容易受到安全漏洞的威胁和破坏。
        {{< /warning >}}

        {{< text bash >}}
        $ kubectl create namespace istio-system
        $ kubectl create secret generic cacerts -n istio-system \
            --from-file=@samples/certs/ca-cert.pem@ \
            --from-file=@samples/certs/ca-key.pem@ \
            --from-file=@samples/certs/root-cert.pem@ \
            --from-file=@samples/certs/cert-chain.pem@
        {{< /text >}}

    * 安装 Istio:

        {{< text bash >}}
        $ istioctl manifest apply \
            -f install/kubernetes/operator/examples/multicluster/values-istio-multicluster-gateways.yaml
        {{< /text >}}

    想了解更多细节和自定义选项，请参考 [使用 Istioctl 安装](/zh/docs/setup/install/kubernetes/)。

## 配置 DNS{#setup-DNS}

应用一般需要通过他们的 DNS 解析服务名然后访问返回的 IP，为远端集群中的服务提供 DNS 解析，将允许已有的应用不做修改就可以正常运行。
Istio 本身不会为两个服务之间的请求使用 DNS。集群本地的服务共用一个通用的 DNS 后缀（例如，`svc.cluster.local`）。Kubernetes DNS 为这些服务提供了 DNS 解析。

要为远端集群的服务提供类似的配置，远端集群内的服务需要以 `<name>.<namespace>.global` 的格式命名。
Istio 还附带了一个名为 CoreDNS 的服务，它可以为这些服务提供 DNS 解析。
想要使用 CoreDNS，Kubernetes  DNS 的 `.global` 必须配置为 `stub a domain`。

{{< warning >}}
一些云提供商的 Kubernetes 服务可能有不同的、特殊的 `DNS domain stub` 程序和功能。
请参考云提供商的文档，以确定如何为不同环境的 `stub DNS domains`。
这个 bash 的目的是为 `53` 端口上的 `.global` 存根域引用或代理 Istio 的 service namespace 中的 `istiocoredns` 服务。
{{< /warning >}}

在每个要调用远端集群中服务的集群中（通常是所有集群），
选择并创建下面这些 ConfigMaps 中的一个，或直接使用现有的做修改。

{{< tabset cookie-name="platform" >}}
{{< tab name="KubeDNS" cookie-value="kube-dns" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: kube-dns
  namespace: kube-system
data:
  stubDomains: |
    {"global": ["$(kubectl get svc -n istio-system istiocoredns -o jsonpath={.spec.clusterIP})"]}
EOF
{{< /text >}}

{{< /tab >}}

{{< tab name="CoreDNS (< 1.4.0)" cookie-value="coredns-prev-1.4.0" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: coredns
  namespace: kube-system
data:
  Corefile: |
    .:53 {
        errors
        health
        kubernetes cluster.local in-addr.arpa ip6.arpa {
           pods insecure
           upstream
           fallthrough in-addr.arpa ip6.arpa
        }
        prometheus :9153
        proxy . /etc/resolv.conf
        cache 30
        loop
        reload
        loadbalance
    }
    global:53 {
        errors
        cache 30
        proxy . $(kubectl get svc -n istio-system istiocoredns -o jsonpath={.spec.clusterIP})
    }
EOF
{{< /text >}}

{{< /tab >}}

{{< tab name="CoreDNS (>= 1.4.0)" cookie-value="coredns-after-1.4.0" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: coredns
  namespace: kube-system
data:
  Corefile: |
    .:53 {
        errors
        health
        kubernetes cluster.local in-addr.arpa ip6.arpa {
           pods insecure
           upstream
           fallthrough in-addr.arpa ip6.arpa
        }
        prometheus :9153
        forward . /etc/resolv.conf
        cache 30
        loop
        reload
        loadbalance
    }
    global:53 {
        errors
        cache 30
        forward . $(kubectl get svc -n istio-system istiocoredns -o jsonpath={.spec.clusterIP})
    }
EOF
{{< /text >}}

{{< /tab >}}
{{< /tabset >}}

## 应用服务的配置{#configure-application-services}

一个集群中所有需要被其它远端集群访问的服务，都需要在远端集群中配置 `ServiceEntry`。
service entry 使用的 host 应该采用如下格式：`<name>.<namespace>.global`。
其中 name 和 namespace 分别对应服务名和命名空间。

为了演示跨集群访问，需要配置：
在第一个集群中运行的 [sleep service]({{<github_tree>}}/samples/sleep) 并调用
在第二个集群中运行的 [httpbin service]({{<github_tree>}}/samples/httpbin)。
开始之前：

* 选择两个 Istio 集群，分别称之为 `cluster1` 和 `cluster2`。

{{< boilerplate kubectl-multicluster-contexts >}}

### 示例服务的配置{#configure-the-example-services}

1. 在 `cluster1` 上部署 `sleep` 服务。

    {{< text bash >}}
    $ kubectl create --context=$CTX_CLUSTER1 namespace foo
    $ kubectl label --context=$CTX_CLUSTER1 namespace foo istio-injection=enabled
    $ kubectl apply --context=$CTX_CLUSTER1 -n foo -f @samples/sleep/sleep.yaml@
    $ export SLEEP_POD=$(kubectl get --context=$CTX_CLUSTER1 -n foo pod -l app=sleep -o jsonpath={.items..metadata.name})
    {{< /text >}}

1. 在 `cluster2` 上部署 `httpbin` 服务。

    {{< text bash >}}
    $ kubectl create --context=$CTX_CLUSTER2 namespace bar
    $ kubectl label --context=$CTX_CLUSTER2 namespace bar istio-injection=enabled
    $ kubectl apply --context=$CTX_CLUSTER2 -n bar -f @samples/httpbin/httpbin.yaml@
    {{< /text >}}

1. 暴露 `cluster2` 的 gateway 地址：

    {{< text bash >}}
    $ export CLUSTER2_GW_ADDR=$(kubectl get --context=$CTX_CLUSTER2 svc --selector=app=istio-ingressgateway \
        -n istio-system -o jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}')
    {{< /text >}}

    该命令使用了 gateway 的公网 IP，如果您有域名的话，您也可以直接使用域名。

    {{< tip >}}
    如果 `cluster2` 运行在一个不支持对外负载均衡的环境下，您需要使用 nodePort 访问 gateway。
    有关获取使用 IP 的说明，请参见教程：[Control Ingress Traffic](/zh/docs/tasks/traffic-management/ingress/ingress-control/#determining-the-ingress-ip-and-ports)。
    在后面的步骤中，您还需要将 service entry 的 endpoint 的端口从 15443 修改为其对应的 nodePort
    （例如，`kubectl --context=$CTX_CLUSTER2 get svc -n istio-system istio-ingressgateway -o=jsonpath='{.spec.ports[?(@.port==15443)].nodePort}'`）。

    {{< /tip >}}

1. 在 `cluster1` 中为 `httpbin` 服务创建一个 service entry。

    为了让 `cluster1` 中的 `sleep` 访问 `cluster2` 中的 `httpbin`，我们需要在 `cluster1` 中为 `httpbin` 服务创建一个 service entry。
    service entry 的 host 命名应采用 `<name>.<namespace>.global` 的格式。
    其中 name 和 namespace 分别与远端服务的 name 和 namespace 对应。

    为了让 DNS 解析 `*.global` 域下的服务，您需要给这些服务分配一个 IP 地址。

    {{< tip >}}
    每个（`.global` 域下的）服务都必须有一个在其所属集群内唯一的 IP 地址。
    {{< /tip >}}

    如果 global service 需要使用虚拟 IP，您可以使用，但除此之外，我们建议使用范围在 `240.0.0.0/4` 的 E 类 IP 地址。
    使用这类 IP 地址的应用的流量将被 sidecar 捕获，并路由至适当的远程服务。

    {{< warning >}}
    组播地址 (224.0.0.0 ~ 239.255.255.255) 不应该被使用，因为这些地址默认不会被路由。
    环路地址 (127.0.0.0/8) 不应该被使用，因为 sidecar 可能会将其重定向至 sidecar 的某个监听端口。
    {{< /warning >}}

    {{< text bash >}}
    $ kubectl apply --context=$CTX_CLUSTER1 -n foo -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: ServiceEntry
    metadata:
      name: httpbin-bar
    spec:
      hosts:
      # must be of form name.namespace.global
      - httpbin.bar.global
      # Treat remote cluster services as part of the service mesh
      # as all clusters in the service mesh share the same root of trust.
      location: MESH_INTERNAL
      ports:
      - name: http1
        number: 8000
        protocol: http
      resolution: DNS
      addresses:
      # the IP address to which httpbin.bar.global will resolve to
      # must be unique for each remote service, within a given cluster.
      # This address need not be routable. Traffic for this IP will be captured
      # by the sidecar and routed appropriately.
      - 240.0.0.2
      endpoints:
      # This is the routable address of the ingress gateway in cluster2 that
      # sits in front of sleep.foo service. Traffic from the sidecar will be
      # routed to this address.
      - address: ${CLUSTER2_GW_ADDR}
        ports:
          http1: 15443 # Do not change this port value
    EOF
    {{< /text >}}

    上面的配置会基于双向 TLS 连接，将 `cluster1` 中对 `httpbin.bar.global` 的 *任意端口* 的访问，路由至 `<IPofCluster2IngressGateway>:15443` endpoint。

    gateway 的 15443 端口是一个特殊的 SNI-aware Envoy，当您在集群中部署 Istio 控制平面时，它会自动安装。
    进入 15443 端口的流量会为目标集群内适当的服务的 pods 提供负载均衡（在这个例子中是，`cluster2` 集群中的 `httpbin.bar` 服务）。

    {{< warning >}}
    不要手动创建一个使用 15443 端口的 `Gateway`。
    {{< /warning >}}

1. 验证 `sleep` 是否可以访问 `httpbin`。

    {{< text bash >}}
    $ kubectl exec --context=$CTX_CLUSTER1 $SLEEP_POD -n foo -c sleep -- curl -I httpbin.bar.global:8000/headers
    {{< /text >}}

### 通过 egress gateway 发送远程流量{#send-remote-traffic-via-an-egress-gateway}

如果您想在 `cluster1` 中通过一个专用的 egress gateway 路由流量，而不是从 sidecars 直连。
使用下面的 service entry 替换前面一节对  `httpbin.bar`  使用的配置。

{{< tip >}}
该配置中使用的 egress gateway 依然不能处理其它的、非 inter-cluster 的 egress 流量。
{{< /tip >}}

如果 `$CLUSTER2_GW_ADDR` 是 IP 地址，请使用 `$CLUSTER2_GW_ADDR - IP address` 选项。如果 `$CLUSTER2_GW_ADDR` 是域名，请使用 `$CLUSTER2_GW_ADDR - hostname` 选项。

{{< tabset cookie-name="profile" >}}

{{< tab name="$CLUSTER2_GW_ADDR - IP address" cookie-value="option1" >}}
* 暴露 `cluster1` egress gateway 地址:

{{< text bash >}}
$ export CLUSTER1_EGW_ADDR=$(kubectl get --context=$CTX_CLUSTER1 svc --selector=app=istio-egressgateway \
    -n istio-system -o yaml -o jsonpath='{.items[0].spec.clusterIP}')
{{< /text >}}

* 使 httpbin-bar 服务的 entry 生效:

{{< text bash >}}
$ kubectl apply --context=$CTX_CLUSTER1 -n foo -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: httpbin-bar
spec:
  hosts:
  # must be of form name.namespace.global
  - httpbin.bar.global
  location: MESH_INTERNAL
  ports:
  - name: http1
    number: 8000
    protocol: http
  resolution: STATIC
  addresses:
  - 240.0.0.2
  endpoints:
  - address: ${CLUSTER2_GW_ADDR}
    network: external
    ports:
      http1: 15443 # Do not change this port value
  - address: ${CLUSTER1_EGW_ADDR}
    ports:
      http1: 15443
EOF
{{< /text >}}

{{< /tab >}}

{{< tab name="$CLUSTER2_GW_ADDR - hostname" cookie-value="option2" >}}
如果 `${CLUSTER2_GW_ADDR}` 是域名，您也可以使用 `resolution: DNS` 实现 endpoint 解析。

{{< text bash >}}
$ kubectl apply --context=$CTX_CLUSTER1 -n foo -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: httpbin-bar
spec:
  hosts:
  # must be of form name.namespace.global
  - httpbin.bar.global
  location: MESH_INTERNAL
  ports:
  - name: http1
    number: 8000
    protocol: http
  resolution: DNS
  addresses:
  - 240.0.0.2
  endpoints:
  - address: ${CLUSTER2_GW_ADDR}
    network: external
    ports:
      http1: 15443 # Do not change this port value
  - address: istio-egressgateway.istio-system.svc.cluster.local
    ports:
      http1: 15443
EOF
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

### 示例的清理{#cleanup-the-example}

运行下面的命令清理示例中的服务。

* 清理 `cluster1`：

    {{< text bash >}}
    $ kubectl delete --context=$CTX_CLUSTER1 -n foo -f @samples/sleep/sleep.yaml@
    $ kubectl delete --context=$CTX_CLUSTER1 -n foo serviceentry httpbin-bar
    $ kubectl delete --context=$CTX_CLUSTER1 ns foo
    {{< /text >}}

* 清理 `cluster2`：

    {{< text bash >}}
    $ kubectl delete --context=$CTX_CLUSTER2 -n bar -f @samples/httpbin/httpbin.yaml@
    $ kubectl delete --context=$CTX_CLUSTER2 ns bar
    {{< /text >}}

## Version-aware 路由到远端服务{#version-aware-routing-to-remote-services}

如果远端服务有多个版本，您可以为 service entry endpoint 添加标签。比如：

{{< text bash >}}
$ kubectl apply --context=$CTX_CLUSTER1 -n foo -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: httpbin-bar
spec:
  hosts:
  # must be of form name.namespace.global
  - httpbin.bar.global
  location: MESH_INTERNAL
  ports:
  - name: http1
    number: 8000
    protocol: http
  resolution: DNS
  addresses:
  # the IP address to which httpbin.bar.global will resolve to
  # must be unique for each service.
  - 240.0.0.2
  endpoints:
  - address: ${CLUSTER2_GW_ADDR}
    labels:
      cluster: cluster2
    ports:
      http1: 15443 # Do not change this port value
EOF
{{< /text >}}

然后您就可以使用适当的 gateway 标签选择器，创建虚拟服务和目标规则去定义 `httpbin.bar.global` 的子集。
这些指令与路由到本地服务使用的指令相同。
完整的例子，请参考 [multicluster version routing](/zh/blog/2019/multicluster-version-routing/)。

## 卸载{#uninstalling}

若要卸载 Istio，请在 **每个集群** 上执行下面的命令：

{{< text bash >}}
$ kubectl delete -f $HOME/istio.yaml
$ kubectl delete ns istio-system
{{< /text >}}

## 总结{#summary}

使用 Istio gateway、公共的根 CA 和 service entry，您可以配置一个跨多个 Kubernetes 集群的单 Istio 服务网格。
经过这种方式配置后，应用无需任何修改，即可将流量路由到远端的集群内。
尽管此方法需要手动配置一些访问远端服务的选项，但 service entry 的创建过程可以自动化。