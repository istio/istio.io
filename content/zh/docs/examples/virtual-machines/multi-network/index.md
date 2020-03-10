---
title: 多网络网格中的虚拟机
description: 学习怎样添加运行在虚拟机上的服务到您的多网络 Istio 网格中。
weight: 30
keywords:
- kubernetes
- virtual-machine
- gateways
- vms
aliases:
- /zh/docs/examples/mesh-expansion/multi-network
- /zh/docs/tasks/virtual-machines/multi-network
---

本示例演示如何利用网关整合一个 VM 或一个裸机到部署在 Kubernetes 上的多网络 Istio 网格中。这种方式不要求 VM，裸机和集群之间可以通过 VPN 连通或者直接的网络访问。

## 前提条件{#prerequisites}

- 一个或者多个 Kubernetes 集群，支持版本为：{{< supported_kubernetes_versions >}}。
- 虚拟机（VMs）必须可以通过 IP 连接网格中的 Ingress 网关。

## 安装步骤{#installation-steps}

设置内容包括准备网格用于扩展，安装和配置各个 VM 。

### 集群上定制化安装 Istio {#customized-installation-of-Istio-on-the-cluster}

当添加非 Kubernetes 的服务到 Istio 网格时，第一步是 Istio 本身的安装配置，并生成让 VMs 连接到网格的配置文件。为 VM 准备集群需要使用集群管理员权限在一台机器上执行如下命令：

1. 为您的生成的 CA 证书创建 Kubernetes secret，使用如下命令。查看 [Certificate Authority (CA) certificates](/zh/docs/tasks/security/citadel-config/plugin-ca-cert/#plugging-in-the-existing-certificate-and-key) 获取更多细节。

    {{< warning >}}
    样本目录中的 root 证书和中间证书已经大范围分发并被识别。**不能** 在生产环境中使用这些证书，否则您的集群容易受到安全漏洞和破坏的威胁。
    {{< /warning >}}

    {{< text bash >}}
    $ kubectl create namespace istio-system
    $ kubectl create secret generic cacerts -n istio-system \
        --from-file=@samples/certs/ca-cert.pem@ \
        --from-file=@samples/certs/ca-key.pem@ \
        --from-file=@samples/certs/root-cert.pem@ \
        --from-file=@samples/certs/cert-chain.pem@
    {{< /text >}}

1. 集群中部署 Istio 控制平面

        {{< text bash >}}
        $ istioctl manifest apply \
            -f install/kubernetes/operator/examples/vm/values-istio-meshexpansion-gateways.yaml \
            --set coreDNS.enabled=true
        {{< /text >}}

    更多细节和定制选项，参考 [installation instructions](/zh/docs/setup/install/istioctl/)。

1. 为 VM 的服务创建 `vm` 命名空间

    {{< text bash >}}
    $ kubectl create ns vm
    {{< /text >}}

1. 定义命名空间，供 VM 加入。本示例使用 `SERVICE_NAMESPACE` 环境变量保存命名空间。这个环境变量的值必须与您后面在配置文件中使用的命名空间匹配。

    {{< text bash >}}
    $ export SERVICE_NAMESPACE="vm"
    {{< /text >}}

1. 取得初始密钥，服务账户需要在 VMs 上使用。

    {{< text bash >}}
    $ kubectl -n $SERVICE_NAMESPACE get secret istio.default  \
        -o jsonpath='{.data.root-cert\.pem}' | base64 --decode > root-cert.pem
    $ kubectl -n $SERVICE_NAMESPACE get secret istio.default  \
        -o jsonpath='{.data.key\.pem}' | base64 --decode > key.pem
    $ kubectl -n $SERVICE_NAMESPACE get secret istio.default  \
          -o jsonpath='{.data.cert-chain\.pem}' | base64 --decode > cert-chain.pem
    {{< /text >}}

1. 确定并保存 Istio Ingress gateway 的 IP 地址，VMs 会通过这个 IP 地址访问 [Citadel](/zh/docs/concepts/security/) ，
   [Pilot](/zh/docs/ops/deployment/architecture/#pilot) 和集群中的工作负载。

    {{< text bash >}}
    $ export GWIP=$(kubectl get -n istio-system service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    $ echo $GWIP
    35.232.112.158
    {{< /text >}}

1. 生成一个 `cluster.env` 配置并部署到 VMs 中。这个文件包含会被 Envoy 拦截和转发 Kubernetes 集群 IP 地址段。

    {{< text bash >}}
    $ echo -e "ISTIO_CP_AUTH=MUTUAL_TLS\nISTIO_SERVICE_CIDR=$ISTIO_SERVICE_CIDR\n" > cluster.env
    {{< /text >}}

1. 检查生成的 `cluster.env` 文件内容。它应该和下面示例类似：

    {{< text bash >}}
    $ cat cluster.env
    ISTIO_CP_AUTH=MUTUAL_TLS
    ISTIO_SERVICE_CIDR=172.21.0.0/16
    {{< /text >}}

1. 如果 VM 只是调用网格中的服务，您可以跳过这一步。否则，通过如下命令添加 VM 暴露的端口到 `cluster.env` 文件中。如果有必要，您后面还能修改这些端口。

    {{< text bash >}}
    $ echo "ISTIO_INBOUND_PORTS=8888" >> cluster.env
    {{< /text >}}

### 设置 DNS {#setup-DNS}

参考 [Setup DNS](/zh/docs/setup/install/multicluster/gateways/#setup-DNS) 设置集群 DNS 。

### 设置 VM {#setting-up-the-VM}

下一步，在每台您想要添加到网格中的机器上执行如下命令：

1. 拷贝之前创建的 `cluster.env` 和 `*.pem` 到 VM 中。

1. 安装 Envoy sidecar 的 Debian 包。

    {{< text bash >}}
    $ curl -L https://storage.googleapis.com/istio-release/releases/{{< istio_full_version >}}/deb/istio-sidecar.deb > istio-sidecar.deb
    $ sudo dpkg -i istio-sidecar.deb
    {{< /text >}}

1. 添加 Istio gateway 的 IP 地址到 `/etc/hosts` 中。重新查看[集群上定制化安装 Istio](#customized-installation-of-Istio-on-the-cluster) 部分学习怎样获取 IP 地址。
下面的示例演示更新 `/etc/hosts` 文件中的 Istio gateway 地址：

    {{< text bash >}}
    $ echo "35.232.112.158 istio-citadel istio-pilot istio-pilot.istio-system" | sudo tee -a /etc/hosts
    {{< /text >}}

1. 安装 `root-cert.pem`, `key.pem` 和 `cert-chain.pem` 到 `/etc/certs/` 下。

    {{< text bash >}}
    $ sudo mkdir -p /etc/certs
    $ sudo cp {root-cert.pem,cert-chain.pem,key.pem} /etc/certs
    {{< /text >}}

1. 安装 `cluster.env` 到 `/var/lib/istio/envoy/` 下。

    {{< text bash >}}
    $ sudo cp cluster.env /var/lib/istio/envoy
    {{< /text >}}

1. 移交 `/etc/certs/` 和 `/var/lib/istio/envoy/` 下的文件所有权给 Istio proxy 。

    {{< text bash >}}
    $ sudo chown -R istio-proxy /etc/certs /var/lib/istio/envoy
    {{< /text >}}

1. 使用 `systemctl` 启动 Istio 。

    {{< text bash >}}
    $ sudo systemctl start istio-auth-node-agent
    $ sudo systemctl start istio
    {{< /text >}}

## 添加 Istio 资源{#added-Istio-resources}

下面的 Istio 资源结合 gateways 一起对添加 VMs 到网格中做支持。这些资源让 VM 和 集群摆脱了扁平网络的要求。

| 资源类型| 资源名字 | 功能 |
| ----------------------------       |---------------------------       | -----------------                          |
| `configmap`                          | `coredns`                          | Send *.global request to `istiocordns` service |
| `service`                            | `istiocoredns`                     | Resolve *.global to Istio Ingress gateway    |
| `gateway.networking.istio.io`        | `meshexpansion-gateway`           | Open port for Pilot, Citadel and Mixer       |
| `gateway.networking.istio.io`        | `istio-multicluster-ingressgateway`| Open port 15443 for inbound *.global traffic |
| `envoyfilter.networking.istio.io`    | `istio-multicluster-ingressgateway`| Transform `*.global` to `*. svc.cluster.local`   |
| `destinationrule.networking.istio.io`| `istio-multicluster-destinationrule`| Set traffic policy for 15443 traffic         |
| `destinationrule.networking.istio.io`| `meshexpansion-dr-pilot`           | Set traffic policy for `istio-pilot`         |
| `destinationrule.networking.istio.io`| `istio-policy`                     | Set traffic policy for `istio-policy`        |
| `destinationrule.networking.istio.io`| `istio-telemetry`                  | Set traffic policy for `istio-telemetry`     |
| `virtualservice.networking.istio.io` | `meshexpansion-vs-pilot`           | Set route info for `istio-pilot`             |
| `virtualservice.networking.istio.io` | `meshexpansion-vs-citadel`         | Set route info for `istio-citadel`           |

## 暴露在集群上运行的服务到 VMs {#expose-service-running-on-cluster-to-VMs}

集群中每个需要被 VM 访问到的服务必须在集群中添加一个 service entry 配置。Service entry 中的 host 要求格式为 `<name>.<namespace>.global`，其中 name 和 namespace 分别对应服务中的名字和命名空间。

在集群中配置 [httpbin service]({{< github_tree >}}/samples/httpbin) ，演示 VM 怎样访问集群中的服务。

1. 在集群中部署 `httpbin` 。

    {{< text bash >}}
    $ kubectl create namespace bar
    $ kubectl label namespace bar istio-injection=enabled
    $ kubectl apply -n bar -f @samples/httpbin/httpbin.yaml@
    {{< /text >}}

1. 在集群中为 `httpbin` 服务创建 service entry 。

    为了 VM 中的服务能够访问到集群中的 `httpbin` ，我们需要为它创建一个 service entry。Service entry 中的 host 值要求格式为 `<name>.<namespace>.global`，其中 name 和 namespace 分别对应远程服务中的名字和命名空间。

    因为 DNS 解析 `*.global` 域上的服务，您需要为这些服务分配一个 IP 地址。

    {{< tip >}}
    各个服务（ `*.global` DNS 域中）必须在集群中有一个唯一的 IP。
    {{< /tip >}}

    如果全局服务已经有真正的 VIPs，您可以使用它们，否则我们建议使用来自回环段 `127.0.0.0/8` 的还未分配的 IPs 。这些 IPs 在 pod 外不能路由。

    本示例中我们使用 `127.255.0.0/16` 中的 IPs 避免和常用的 IPs 例如 `127.0.0.1` (`localhost`) 产生冲突。

    使用这些 IPs 的应用流量将被 sidecar 捕获并路由到合适的远程服务上。

    {{< text bash >}}
    $ kubectl apply  -n bar -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: ServiceEntry
    metadata:
      name: httpbin.bar.forvms
    spec:
      hosts:
      # 格式要求必须为 name.namespace.global
      - httpbin.bar.global
      location: MESH_INTERNAL
      ports:
      - name: http1
        number: 8000
        protocol: http
      resolution: DNS
      addresses:
      #  httpbin.bar.global 将会被解析至这个 IP 地址，它对于给定集群中的各个服务必须是唯一的。
      # 这个地址不需要可路由。这个 IP 的流量将会被 sidecar 捕获并路由到合适的地方。
      # 同时这个地址也会被添加到 VM 的 /etc/hosts 中
      - 127.255.0.3
      endpoints:
      # 这是集群中 ingress gateway 的可路由地址。
      # 来自 VMs 的流量将被路由到这个地址。
      - address: ${CLUSTER_GW_ADDR}
        ports:
          http1: 15443 # Do not change this port value
    EOF
    {{< /text >}}

    上述配置会让来自 VMs 的 地址为 `httpbin.bar.global` 的 *any port* 的所有流量通过双向 TLS 连接被路由到指定 endpoint `<IPofClusterIngressGateway>:15443` 。

    端口为 15443 的 gateway 是一个特殊的 SNI-aware Envoy，作为结合 gateway 的网格扩张的部分在 Istio 安装部署步骤部分做了配置和安装。进入端口 15443 的流量会在目标集群中合适的内部服务的 pods 上做负载均衡（本例子，是集群中的 `httpbin.bar`）。

    {{< warning >}}
    禁止为端口 15443 创建 `Gateway` 配置。
    {{< /warning >}}

## 从 VM 发送请求到 Kubernetes 中的服务{#send-requests-from-VM-to-Kubernetes-services}

机器在安装以后，就能访问运行在 Kubernetes 集群中的服务。

下面的示例演示一个使用 `/etc/hosts/` 的 VM 访问运行在 Kubernetes 集群中的服务。这个服务来自 [httpbin service]({{<github_tree>}}/samples/httpbin)。

1. 在添加的 VM 上，添加服务名字和地址到它的 `/etc/hosts` 文件中。您就可以从该 VM 连接集群上的服务了，例子如下：

    {{< text bash >}}
$ echo "127.255.0.3 httpbin.bar.global" | sudo tee -a /etc/hosts
$ curl -v httpbin.bar.global:8000
< HTTP/1.1 200 OK
< server: envoy
< content-type: text/html; charset=utf-8
< content-length: 9593

... html content ...
    {{< /text >}}

`server: envoy` header 表示 sidecar 拦截了这个流量。

## 在添加的 VM 上运行服务{#running-services-on-the-added-VM}

1. 在 VM 实例上安装一个 HTTP 服务器处理来自端口 8888 的 HTTP 流量：

    {{< text bash >}}
    $ python -m SimpleHTTPServer 8888
    {{< /text >}}

1. 指定 VM 实例的 IP 地址。

1. 添加 VM 服务到网格中

    {{< text bash >}}
    $ istioctl experimental add-to-mesh external-service vmhttp ${VM_IP} http:8888 -n ${SERVICE_NAMESPACE}
    {{< /text >}}

    {{< tip >}}
    确认您已经将 `istioctl` 客户端添加到您的路径下，这在 [download page](/zh/docs/setup/getting-started/#download) 有讲到。
    {{< /tip >}}

1. 在 Kubernetes 集群中部署一个运行 `sleep` 服务的 pod，并等待它的状态变为 ready：

    {{< text bash >}}
    $ kubectl apply -f @samples/sleep/sleep.yaml@
    $ kubectl get pod
    NAME                             READY     STATUS    RESTARTS   AGE
    sleep-88ddbcfdd-rm42k            2/2       Running   0          1s
    ...
    {{< /text >}}

1. 从运行在 pod 上的 `sleep` 服务发送请求给 VM 的 HTTP 服务：

    {{< text bash >}}
    $ kubectl exec -it sleep-88ddbcfdd-rm42k -c sleep -- curl vmhttp.${SERVICE_NAMESPACE}.svc.cluster.local:8888
    {{< /text >}}

    如果配置正确，您将会看到如下类似输出：

    {{< text html >}}
    <!DOCTYPE html PUBLIC "-//W3C//DTD HTML 3.2 Final//EN"><html>
    <title>Directory listing for /</title>
    <body>
    <h2>Directory listing for /</h2>
    <hr>
    <ul>
    <li><a href=".bashrc">.bashrc</a></li>
    <li><a href=".ssh/">.ssh/</a></li>
    ...
    </body>
    {{< /text >}}

**恭喜！** 您成功配置一个运行在集群 pod 上的服务，发送流量给运行在一个集群外的 VM 上的服务并测试配置是否生效。

## 清除{#cleanup}

执行如下命令从网格的抽象模型中移除扩展的 VM。

{{< text bash >}}
$ istioctl experimental remove-from-mesh -n ${SERVICE_NAMESPACE} vmhttp
Kubernetes Service "vmhttp.vm" has been deleted for external service "vmhttp"
Service Entry "mesh-expansion-vmhttp" has been deleted for external service "vmhttp"
{{< /text >}}
