---
title: Gateway 连接
description: 使用 Istio Gateway 跨越多个 Kubernetes 集群安装 Istio 网格以访问远程 pod。
weight: 2
keywords: [kubernetes,multicluster,federation,gateway]
---

跨越多个集群安装 Istio 网格的说明，每个集群中的 pod 均只能访问远程 gateway IP。

此配置中，每个集群都安装了一个**完全相同的** Istio 控制平面，用于管理自己的 endpoint，而不是使用一个中心 Istio 控制平面来管理网格。 出于策略应用和安全的考虑，每个集群都处于共享管理控制之下。

为了实现跨集群部署单一 Istio 服务网格，需要在所有集群中复制共享的 service 和 namespace，并使用公共的 root CA。
跨集群通信发生在相应集群的 Istio Gateway 上。

{{< image width="80%"
    link="/docs/setup/kubernetes/multicluster/gateways/multicluster-with-gateways.svg"
    caption="Istio 网格使用 Istio Gateway 跨越多个 Kubernetes 集群访问远程 pod"
    >}}

## 先决条件

* 两个或以上安装 **1.10 或更新**版本的 Kubernetes 集群。

* 在**每个** Kubernetes 集群上授权[使用 Helm 部署 Istio 控制平面](/zh/docs/setup/kubernetes/install/helm/)。

* 一个 **Root CA**。跨集群通信需要在 service 之间使用 mutual TLS 连接。为了启用跨集群 mutual TLS 通信，每个集群的 Citadel
 都将被配置使用共享 root CA 生成的中间 CA 凭证。出于演示目的，我们将使用 `samples/certs` 目录下的简单 root CA
  证书，该证书作为 Istio 安装的一部分提供。

## 在每个集群中部署 Istio 控制平面

1. 从您的组织 root CA 生成每个集群 Citadel 使用的中间证书。使用共享的 root CA 启用跨越不同集群的 mutual TLS 通信。
   出于演示目的，我们将使用相同的简单 root 证书作为中间证书。

1. 在每个集群中，使用类似如下的命令，为您生成的 CA 证书创建一个 Kubernetes secret：

    {{< text bash >}}
    $ kubectl create namespace istio-system
    $ kubectl create secret generic cacerts -n istio-system \
        --from-file=samples/certs/ca-cert.pem \
        --from-file=samples/certs/ca-key.pem \
        --from-file=samples/certs/root-cert.pem \
        --from-file=samples/certs/cert-chain.pem
    {{< /text >}}

1. 使用以下命令在每个集群中安装 Istio 控制平面：

    {{< text bash >}}
    $ helm template install/kubernetes/helm/istio --name istio --namespace istio-system \
        -f install/kubernetes/helm/istio/example-values/values-istio-multicluster-gateways.yaml > $HOME/istio.yaml
    $ kubectl create namespace istio-system
    $ kubectl apply -f $HOME/istio.yaml
    {{< /text >}}

更多细节和自定义选项请参考[使用 Helm 安装](/zh/docs/setup/kubernetes/install/helm/)的说明。

## 配置 DNS

为远程集群中的 service 提供 DNS 解析，可以使现有的应用程序不经修改便能继续运行，因为应用程序通常通过解析 service
的 DNS 名称并按结果 IP 地址访问。Istio 本身并不使用 DNS 路由 service 间的请求。属于同一个集群的 service
共享相同的 DNS 后缀（例如 `svc.cluster.local`）。Kubernetes 为这些 service 提供 DNS 解析。

为了给远程集群中的 service 提供相似的设置，我们将远程集群中的 service 以 `<name>.<namespace>.global`
的格式命名。Istio 还附带了一个 CoreDNS 服务器，该服务器将为这些 service 提供 DNS 解析。为了利用这个 DNS，
需要配置 Kubernetes 的 DNS 指向 CoreDNS，该 CoreDNS 将作为 `.global` DNS domain 的 DNS 服务器。请创建
以下 ConfigMap（或更新现有的）：

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

## 添加其它集群的 service

从给定集群访问远程集群中的每个 service 都需要一个 `ServiceEntry` 配置。service entry 中使用的
 host 应该具有 `<name>.<namespace>.global` 的形式，其中 name 和 namespace 分别对应远程 service 的
 name 和 namespace。为了给 `*.global` domain 下的 service 提供 DNS 解析，您需要为这些 service 分配
 一个 IP 地址。我们假设从 127.255.0.0/16 子网分配。这些 IP 在 pod 外是不可路由的。这些 IP 的应用流量将被
 sidecar 捕获并路由到恰当的远程 service。

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: bar-ns2
spec:
  hosts:
  # 必须为 name.namespace.global 的格式
  - bar.ns2.global
  # 将远程集群 service 视为服务网格的一部分
  # 因为服务网格中的所有集群共享相同的信任根（root of trust）。
  location: MESH_INTERNAL
  ports:
  - name: http1
    number: 8080
    protocol: http
  - name: tcp2
    number: 9999
    protocol: tcp
  resolution: DNS
  addresses:
  # 在给定的集群中，bar.ns2.global 解析为的 IP 地址对每个远程 service 都必须唯一。
  # 这些地址需要不能被路由到。到此 IP 的流量将被 sidecar 捕获并恰当的路由。
  - 127.255.0.2
  endpoints:
  # 这是 cluster2 中可路由的 ingerss gateway 地址，位于 bar.ns2 service 前端。
  # 从 sidecar 而来的流量将被路由到此地址。
  - address: <IPofCluster2IngressGateway>
    ports:
      http1: 15443 # Do not change this port value
      tcp2: 15443 # Do not change this port value
{{< /text >}}

如果您希望通过专用的 egress gateway 路由所有从 `cluster1` 过来的 egress 流量，请为 `bar.ns2`
 使用如下 service entry:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: bar-ns2
spec:
  hosts:
  # must be of form name.namespace.global
  - bar.ns2.global
  location: MESH_INTERNAL
  ports:
  - name: http1
    number: 8080
    protocol: http
  - name: tcp2
    number: 9999
    protocol: tcp
  resolution: DNS
  addresses:
  - 127.255.0.2
  endpoints:
  - address: <IPofCluster2IngressGateway>
    network: external
    ports:
      http1: 15443 # Do not change this port value
      tcp2: 15443 # Do not change this port value
  - address: istio-egressgateway.istio-system.svc.cluster.local
    ports:
      http1: 15443
      tcp2: 15443
{{< /text >}}

为了验证设置，请尝试从 `cluster1` 上的任意 pod 访问 `bar.ns2.global` 或 `bar.ns2`。
两个 DNS 名称都应该被解析到 127.255.0.2 这个在 service entry 配置中使用的地址。

以上配置将使得 `cluster1` 中所有到 `bar.ns2.global` 和*任意端口*的流量通过 mutual TLS 连接路由到
 endpoint `<IPofCluster2IngressGateway>:15443`。

端口 15443 的 gateway 是一个特殊的 SNI 感知 Envoy，它已经预先进行了配置，并作为前提条件中描述的 Istio
安装步骤的一部分进行了安装。进入 15443 端口的流量将在目标集群中恰当的内部 service pod 中进行负载均衡。

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: bar-ns2
spec:
  hosts:
  # 必须为 name.namespace.global 的形式
  - bar.ns2.global
  location: MESH_INTERNAL
  ports:
  - name: http1
    number: 8080
    protocol: http
  - name: tcp2
    number: 9999
    protocol: tcp
  resolution: DNS
  addresses:
  # bar.ns2.global 解析为的 IP 地址对每个 service 必须唯一。
  - 127.255.0.2
  endpoints:
  - address: <IPofCluster2IngressGateway>
    labels:
      version: beta
      some: thing
      foo: bar
    ports:
      http1: 15443 # 不要修改此端口值
      tcp2: 15443 # 不要修改此端口值
{{< /text >}}

使用 destination rule 为具有适当 label selector 的 `bar.ns2` service 创建子集。
要遵循的步骤与用于本地 service 的步骤完全相同。

## 总结

通过使用 Istio gateway、一个通用 root CA 以及 service entry，您可以跨越多个 Kubernetes
集群配置单一的 Istio 服务网格。虽然上诉过程包含了一定的手动操作，整个过程可以通过为系统中每个 service
创建 service entry（从 127.255.0.0/16 子网分配一个唯一 IP 地址） 实现自动化。一旦这样配置，流量就可以被透明的路由到远程集群，无需任何（其它）应用介入。
