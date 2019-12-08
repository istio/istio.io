---
title: 单个网络网格中的虚拟机
description: 学习如何新增一个服务，使其运行在单网络 Istio 网格的虚拟机上。
weight: 20
keywords:
- kubernetes
- vms
- virtual-machines
aliases:
- /zh/docs/setup/kubernetes/additional-setup/mesh-expansion/
- /zh/docs/examples/mesh-expansion/single-network
- /zh/docs/tasks/virtual-machines/single-network
---

此示例显示如何将 VM 或者本地裸机集成到 Kubernetes 上部署的单网络 Istio 网格中。

## 准备环境{#prerequisites}

- 您已经在 Kubernetes 上部署了 Istio。如果尚未这样做，
  则可以在[安装指南](/zh/docs/setup/getting-started/) 中找到方法。

- 虚拟机（VM）必须具有网格中 endpoint 的 IP 连接。
  这通常需要 VPC 或者 VPN，以及需要提供直接（没有 NAT 或者防火墙拒绝访问）
   路由到 endpoint 的容器网络。虚拟机不需要访问 Kubernetes 分配的集群 IP 地址。

- VM 必须有权访问 DNS 服务， 将名称解析为集群 IP 地址。
  选项包括通过内部负载均衡器，使用 [Core DNS](https://coredns.io/) 服务公开的 Kubernetes DNS 服务器，或者在可从 VM 中访问的任何其他 DNS 服务器中配置 IP。

具有以下说明：

- 假设扩展 VM 运行在 GCE 上。
- 使用 Google 平台的特定命令执行某些步骤。

## 安装步骤{#installation-steps}

安装并配置每个虚拟机，设置准备用于扩展的网格。

### 为虚拟机准备 Kubernetes 集群{#preparing-the-Kubernetes-cluster-for-VMs}

当将非 Kubernetes 服务添加到 Istio 网格中时，首先配置 Istio 它自己的设施，并生成配置文件使 VM 连接网格。在具有集群管理员特权的计算机上，使用以下命令为 VM 准备集群：

1. 使用类似于以下的命令，为生成的 CA 证书创建 Kubernetes secret。请参阅[证书办法机构 (CA) 证书](/zh/docs/tasks/security/citadel-config/plugin-ca-cert/#plugging-in-the-existing-certificate-and-key) 获取更多的详细信息。

    {{< warning >}}
    样本目录中的 root 证书和中间证书已经大范围分发并被识别。
    **不能** 在生产环境中使用这些证书，否则您的集群容易受到安全漏洞和破坏的威胁。
    {{< /warning >}}

    {{< text bash >}}
    $ kubectl create namespace istio-system
    $ kubectl create secret generic cacerts -n istio-system \
        --from-file=@samples/certs/ca-cert.pem@ \
        --from-file=@samples/certs/ca-key.pem@ \
        --from-file=@samples/certs/root-cert.pem@ \
        --from-file=@samples/certs/cert-chain.pem@
    {{< /text >}}

1. 在集群中部署 Istio 控制平面：

        {{< text bash >}}
        $ istioctl manifest apply \
            -f install/kubernetes/operator/examples/vm/values-istio-meshexpansion.yaml
        {{< /text >}}

    有关更多的详细信息和自定义选项，请参阅
    [安装说明](/zh/docs/setup/install/istioctl/)。

1. 定义 VM 加入的命名空间。本示例使用 `SERVICE_NAMESPACE`
   环境变量存储命名空间。此变量的值必须与稍后在配置文件中使用的命名空间相匹配。

    {{< text bash >}}
    $ export SERVICE_NAMESPACE="default"
    {{< /text >}}

1. 确定并存储 Istio 入口网关的 IP 地址，因为 VMs 通过此 IP 地址访问 [Citadel](/zh/docs/concepts/security/) 和
   [Pilot](/zh/docs/ops/deployment/architecture/#pilot)。

    {{< text bash >}}
    $ export GWIP=$(kubectl get -n istio-system service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    $ echo $GWIP
    35.232.112.158
    {{< /text >}}

1. 在 VM 中生成 `cluster.env` 配置并部署。该文件包含 Kubernetes 集群 IP 地址范围，可
    通过 Envoy 进行拦截和重定向。当您安装 Kubernetes 时，可以指定 CIDR 的范围为 `servicesIpv4Cidr`。
    在安装后，按照以下示例的命令，使用适当的值替换 `$MY_ZONE` 和 `$MY_PROJECT`，
    以获取 CIDR：

    {{< text bash >}}
    $ ISTIO_SERVICE_CIDR=$(gcloud container clusters describe $K8S_CLUSTER --zone $MY_ZONE --project $MY_PROJECT --format "value(servicesIpv4Cidr)")
    $ echo -e "ISTIO_CP_AUTH=MUTUAL_TLS\nISTIO_SERVICE_CIDR=$ISTIO_SERVICE_CIDR\n" > cluster.env
    {{< /text >}}

1. 检查生成文件 `cluster.env` 的内容。其内容应该与以下示例类似：

    {{< text bash >}}
    $ cat cluster.env
    ISTIO_CP_AUTH=MUTUAL_TLS
    ISTIO_SERVICE_CIDR=10.55.240.0/20
    {{< /text >}}

1. 如果 VM 仅在网格中调用服务，您可以跳过这2一步骤。否则，使用以下命令为 VM 新增公开端口到 `cluster.env` 文件下。
    如有必要，您可以稍后更改端口。

    {{< text bash >}}
    $ echo "ISTIO_INBOUND_PORTS=3306,8080" >> cluster.env
    {{< /text >}}

1. 提取服务帐户需要在 VM 上使用的初始密钥。

    {{< text bash >}}
    $ kubectl -n $SERVICE_NAMESPACE get secret istio.default  \
        -o jsonpath='{.data.root-cert\.pem}' |base64 --decode > root-cert.pem
    $ kubectl -n $SERVICE_NAMESPACE get secret istio.default  \
        -o jsonpath='{.data.key\.pem}' |base64 --decode > key.pem
    $ kubectl -n $SERVICE_NAMESPACE get secret istio.default  \
          -o jsonpath='{.data.cert-chain\.pem}' |base64 --decode > cert-chain.pem
    {{< /text >}}

### 设置 VM{#setting-up-the-VM}

下一步，将要加入网格的每台机器上运行以下命令：

1.  将之前创建的 `cluster.env` 和 `*.pem` 文件复制到 VM 中。例如：

    {{< text bash >}}
    $ export GCE_NAME="your-gce-instance"
    $ gcloud compute scp --project=${MY_PROJECT} --zone=${MY_ZONE} {key.pem,cert-chain.pem,cluster.env,root-cert.pem} ${GCE_NAME}:~
    {{< /text >}}

1.  使用 Envoy sidecar 安装 Debian 软件包。

    {{< text bash >}}
    $ gcloud compute ssh --project=${MY_PROJECT} --zone=${MY_ZONE} "${GCE_NAME}"
    $ curl -L https://storage.googleapis.com/istio-release/releases/{{< istio_full_version >}}/deb/istio-sidecar.deb > istio-sidecar.deb
    $ sudo dpkg -i istio-sidecar.deb
    {{< /text >}}

1.  将 Istio 的网关 IP 地址添加到 `/etc/hosts`。重新访问 [集群准备](#preparing-the-Kubernetes-cluster-for-VMs) 部分以了解如何获取 IP 地址。
以下示例使用 Istio 网关地址修改 `/etc/hosts` 文件：

    {{< text bash >}}
    $ echo "35.232.112.158 istio-citadel istio-pilot istio-pilot.istio-system" | sudo tee -a /etc/hosts
    {{< /text >}}

1.  在 `/etc/certs/` 下安装 `root-cert.pem`，`key.pem` 和 `cert-chain.pem`。

    {{< text bash >}}
    $ sudo mkdir -p /etc/certs
    $ sudo cp {root-cert.pem,cert-chain.pem,key.pem} /etc/certs
    {{< /text >}}

1.  在 `/var/lib/istio/envoy/` 下安装 `cluster.env`。

    {{< text bash >}}
    $ sudo cp cluster.env /var/lib/istio/envoy
    {{< /text >}}

1.  将 `/etc/certs/` 和 `/var/lib/istio/envoy/` 中文件的所有权转交给 Istio proxy。

    {{< text bash >}}
    $ sudo chown -R istio-proxy /etc/certs /var/lib/istio/envoy
    {{< /text >}}

1.  验证节点上的 agent 是否正常工作：

    {{< text bash >}}
    $ sudo node_agent
    ....
    CSR is approved successfully. Will renew cert in 1079h59m59.84568493s
    {{< /text >}}

1.  使用 `systemctl` 启动 Istio：

    {{< text bash >}}
    $ sudo systemctl start istio-auth-node-agent
    $ sudo systemctl start istio
    {{< /text >}}

## 将来自 VM 工作负载的请求发送到 Kubernetes 服务{#send-requests-from-VM-workloads-to-Kubernetes-services}

设置完后，机器可以访问运行在 Kubernetes 集群上的服务，或者其他的 VM。

以下示例展示了使用 `/etc/hosts/` 如何从 VM 中访问 Kubernetes 集群上运行的服务，
这里使用 [Bookinfo 示例](/zh/docs/examples/bookinfo/) 中的服务。

1.  首先，在集群管理机器上获取服务的虚拟 IP 地址（`clusterIP`）：

    {{< text bash >}}
    $ kubectl get svc productpage -o jsonpath='{.spec.clusterIP}'
    10.55.246.247
    {{< /text >}}

1.  然后在新增的 VM 上，将服务名称和地址添加到其 `etc/hosts` 文件下。
    然后您可以从 VM 连接到集群服务，如以下示例：

    {{< text bash >}}
$ echo "10.55.246.247 productpage.default.svc.cluster.local" | sudo tee -a /etc/hosts
$ curl -v productpage.default.svc.cluster.local:9080
< HTTP/1.1 200 OK
< content-type: text/html; charset=utf-8
< content-length: 1836
< server: envoy
... html content ...
    {{< /text >}}

`server: envoy` 标头指示 sidecar 拦截了流量。

## 在添加的 VM 中运行服务{#running-services-on-the-added-VM}

1. 在 VM 实例上设置 HTTP 服务，以在端口 8080 上提供 HTTP 通信：

    {{< text bash >}}
    $ gcloud compute ssh ${GCE_NAME}
    $ python -m SimpleHTTPServer 8080
    {{< /text >}}

1. 定义 VM 实例的 IP 地址。例如，使用以下命令
    查找 GCE 实例的 IP 地址：

    {{< text bash >}}
    $ export GCE_IP=$(gcloud --format="value(networkInterfaces[0].networkIP)" compute instances describe ${GCE_NAME})
    $ echo ${GCE_IP}
    {{< /text >}}

1. 将 VM 服务添加到网格

    {{< text bash >}}
    $ istioctl experimental add-to-mesh external-service vmhttp ${VM_IP} http:8080 -n ${SERVICE_NAMESPACE}
    {{< /text >}}

    {{< tip >}}
    按照[下载页面](/zh/docs/setup/getting-started/#download)中的说明，确保已经将 `istioctl` 客户端添加到您的路径中。
    {{< /tip >}}

1. 在 Kubernetes 集群中部署一个 pod 运行 `sleep` 服务，然后等待其准备就绪：

    {{< text bash >}}
    $ kubectl apply -f @samples/sleep/sleep.yaml@
    $ kubectl get pod
    NAME                             READY     STATUS    RESTARTS   AGE
    sleep-88ddbcfdd-rm42k            2/2       Running   0          1s
    ...
    {{< /text >}}

1. 将 pod 中 `sleep` 服务的请求发送到 VM 的 HTTP 服务：

    {{< text bash >}}
    $ kubectl exec -it sleep-88ddbcfdd-rm42k -c sleep -- curl vmhttp.${SERVICE_NAMESPACE}.svc.cluster.local:8080
    {{< /text >}}

    您应该看到类似于以下输出的内容：

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

**恭喜你！** 您已经成功的配置了一个服务，使其运行在集群中的 pod 上，将其流量发送给集群之外在 VM 上运行的服务，并测试了配置是否有效。

## 清理{#cleanup}

运行以下命令，从网格的抽象模型中删除扩展 VM：

{{< text bash >}}
$ istioctl experimental remove-from-mesh -n ${SERVICE_NAMESPACE} vmhttp
Kubernetes Service "vmhttp.vm" has been deleted for external service "vmhttp"
Service Entry "mesh-expansion-vmhttp" has been deleted for external service "vmhttp"
{{< /text >}}

## 故障排除{#troubleshooting}

以下是一些常见的 VM 相关问题的基本故障排除步骤。

-    从 VM 向群集发出请求时，请确保不要以 `root` 或
    者 `istio-proxy` 用户的身份运行请求。默认情况下，Istio 将这两个用户都排除在拦截范围之外。

-    验证计算机是否可以达到集群中运行的所有工作负载的 IP。例如：

    {{< text bash >}}
    $ kubectl get endpoints productpage -o jsonpath='{.subsets[0].addresses[0].ip}'
    10.52.39.13
    {{< /text >}}

    {{< text bash >}}
    $ curl 10.52.39.13:9080
    html output
    {{< /text >}}

-    检查节点 agent 和 sidecar 的状态：

    {{< text bash >}}
    $ sudo systemctl status istio-auth-node-agent
    $ sudo systemctl status istio
    {{< /text >}}

-    检查进程是否正在运行。在 VM 上，您应该看到以下示例的进程，如果您运行了
     `ps` 过滤 `istio`：

    {{< text bash >}}
    $ ps aux | grep istio
    root      6941  0.0  0.2  75392 16820 ?        Ssl  21:32   0:00 /usr/local/istio/bin/node_agent --logtostderr
    root      6955  0.0  0.0  49344  3048 ?        Ss   21:32   0:00 su -s /bin/bash -c INSTANCE_IP=10.150.0.5 POD_NAME=demo-vm-1 POD_NAMESPACE=default exec /usr/local/bin/pilot-agent proxy > /var/log/istio/istio.log istio-proxy
    istio-p+  7016  0.0  0.1 215172 12096 ?        Ssl  21:32   0:00 /usr/local/bin/pilot-agent proxy
    istio-p+  7094  4.0  0.3  69540 24800 ?        Sl   21:32   0:37 /usr/local/bin/envoy -c /etc/istio/proxy/envoy-rev1.json --restart-epoch 1 --drain-time-s 2 --parent-shutdown-time-s 3 --service-cluster istio-proxy --service-node sidecar~10.150.0.5~demo-vm-1.default~default.svc.cluster.local
    {{< /text >}}

-    检查 Envoy 访问和错误日志：

    {{< text bash >}}
    $ tail /var/log/istio/istio.log
    $ tail /var/log/istio/istio.err.log
    {{< /text >}}
