---
title: Gateway 连接
description: 使用 Istio Gateway 跨越多个 Kubernetes 集群安装 Istio 网格以访问远程 pod。
weight: 2
keywords: [kubernetes,multicluster,federation,gateway]
---

安装 Istio [多集群网格](/zh/docs/concepts/multicluster-deployments/)的介绍。这种情况下，Kubernetes 集群服务和每个集群中的应用都只能使用网关 IP 进行远程通信。

此配置中，每个集群都安装了一个**完全相同的** Istio 控制平面，用于管理自己的网格，而不是使用一个中心 Istio。 出于策略应用和安全的考虑，每个集群都处于共享管理控制之下。

为了实现跨集群部署单一 Istio 服务网格，需要在所有集群中复制共享的服务和命名空间，并使用公共的根证书。
跨集群通信发生在相应集群的 Istio Gateway 上。

{{< image width="80%"
    link="/docs/setup/install/multicluster/gateways/multicluster-with-gateways.svg"
    caption="Istio 网格使用 Istio Gateway 跨越多个 Kubernetes 集群访问远程 Pod"
    >}}

## 先决条件

* 两个或以上安装 **1.10 或更新**版本的 Kubernetes 集群。

* 在**每个** Kubernetes 集群上都有[使用 Helm 部署 Istio 控制平面](/zh/docs/setup/kubernetes/install/helm/)的权限。

* `istio-ingressgateway` 服务的 IP 地址必须能够从其它集群中进行访问。

* 一个 **Root CA**。跨集群通信需要在服务之间使用双向 TLS 连接。为了启用跨集群的双向 TLS 通信，每个集群的 Citadel 都将被配置使用共享根证书所生成的中间 CA 凭证。出于演示目的，我们将使用 `samples/certs` 目录下的简单 root CA 证书，该证书作为 Istio 安装的一部分提供。

## 在每个集群中部署 Istio 控制平面

1. 从您的组织 root CA 生成每个集群 Citadel 使用的中间证书。使用共享的 root CA 启用跨越不同集群的双向 TLS 通信。

    {{< tip >}}
    处于演示目的，下面的介绍中会在不同的集群中使用来自 Istio sample 目录中的同样的证书。在真实部署中，建议为不同集群使用不同的 CA，所有 CA 都从同样的根 CA 签发。
    {{< /tip >}}

1. 使用 `helm` 生成多网关的 Istio 配置：

    {{< warning >}}
    如果不清楚你的 `helm` 依赖是否过期，在开始之前可以使用 [Helm 安装步骤](/zh/docs/setup/kubernetes/install/helm/#安装步骤)中的命令进行更新。
    {{< /warning >}}

    {{< text bash >}}
    $ helm template install/kubernetes/helm/istio --name istio --namespace istio-system \
        -f @install/kubernetes/helm/istio/example-values/values-istio-multicluster-gateways.yaml@ > $HOME/istio.yaml
    {{< /text >}}

    要了解更多细节以及参数定制方法，请阅读：[用 Helm 进行安装](/zh/docs/setup/kubernetes/install/helm)。

1. 在**每个集群**中运行下面的命令，从而为所有集群生成一致的 Istio 控制面部署配置。

    * 使用如下命令，用新生成的 CA 证书，创建一个 Kubernetes Secret，阅读 [CA 证书](/zh/docs/tasks/security/plugin-ca-cert/#插入现有密钥和证书)一节，其中有更多的相关细节。

        {{< text bash >}}
        $ kubectl create namespace istio-system
        $ kubectl create secret generic cacerts -n istio-system \
            --from-file=@samples/certs/ca-cert.pem@ \
            --from-file=@samples/certs/ca-key.pem@ \
            --from-file=@samples/certs/root-cert.pem@ \
            --from-file=@samples/certs/cert-chain.pem@
        {{< /text >}}

    * 依照 [Helm 安装步骤](/zh/docs/setup/kubernetes/install/helm/#安装步骤)中的介绍完成 Istio 的安装。必须使用参数 `--values install/kubernetes/helm/istio/example-values/values-istio-multicluster-gateways.yaml`，来启用正确的多集群设置。例如：

        {{< text bash >}}
        $ helm install istio --name istio --namespace istio-system --values @install/kubernetes/helm/istio/example-values/values-istio-multicluster-gateways.yaml@
        {{< /text >}}

## 配置 DNS

应用通常会使用 DNS 名称来获取 IP，然后进行访问，如果在远程集群中为服务提供 DNS 解析，就能让现存应用保持原样。Istio 在完成服务之间的请求路由的过程中，并不会使用 DNS。集群本地的服务会使用一个通用的 DNS 后缀（例如 `svc.cluster.local`）。Kubernetes DNS 为这些服务提供了 DNS 解析能力。

为了给远程集群提供一个类似的配置，我们给远端集群的服务用 `<name>.<namespace>.global` 的形式进行命名。Istio 提供了一个 CoreDNS 服务器，用来给这些服务提供 DNS 解析。为了使用这个 DNS 服务，需要对 Kubernetes 的 DNS 进行配置，要求使用这一 CoreDNS 服务器来为 `.global` DNS 域提供解析。

在每个需要调用远端服务的集群中，创建下列 ConfigMap 中的一个，如果已经存在，就进行更新。

使用 `kube-dns` 的集群：

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

使用 CoreDNS 的集群：

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

## 配置应用服务

如果一个集群中的服务需要访问远端集群中的服务，就需要创建一个 `ServiceEntry`。`ServiceEntry` 中的主机名应该是 `<name>.<namespace>.global` 的格式，其中的 `name` 和 `namespace` 需要根据服务名称和命名空间进行替换。

为了检查多集群配置是否生效，可以参考示例[通过网关进行多集群连接](/zh/docs/tasks/multicluster/gateways/)来进行测试。

## 清理

在**每个集群**上运行下面的命令，删除 Istio：

{{< text bash >}}
$ kubectl delete -f $HOME/istio.yaml
$ kubectl delete ns istio-system
{{< /text >}}

## 总结

使用 Istio 网关，结合一个通用根证书以及 `ServiceEntry`，就能够让单一的 Istio 服务网格跨越多个 Kubernetes 集群。使用这种配置，无需对应用进行任何改动，流量就能够透明的路由到远端集群。虽然这种方式需要一部分的手工操作来配置远程的服务访问，但是 `ServiceEntry` 的创建过程也是可以自动化的。
