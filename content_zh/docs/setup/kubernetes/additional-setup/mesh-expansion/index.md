---
title: 网格扩展
description: 部署在 Kubernetes 之中的 Istio 服务网格，将虚拟机和物理机集成进入到服务网格的方法。
weight: 95
keywords: [kubernetes,vms]
---

本指南提供了将 VM 和裸机主机集成到 Kubernetes 上部署的 Istio 网格中的说明。

## 先决条件{#prerequisites}

* 已经在 Kubernetes 上建立了 Istio。如果还没有这样做，可以在[安装指南](/zh/docs/setup/kubernetes/install/kubernetes/)中找到方法。

* 待接入服务器必须能够通过 IP 接入网格中的服务端点。通常这需要 VPN 或者 VPC 的支持，或者容器网络为服务端点提供直接路由（非 NAT 或者防火墙屏蔽）。该服务器无需访问 Kubernetes 指派的集群 IP 地址。

* Istio 控制平面服务（Pilot、Mixer、Citadel）以及 Kubernetes 的 DNS 服务器必须能够从虚拟机进行访问，通常会使用[内部负载均衡器](https://kubernetes.io/docs/concepts/services-networking/service/#internal-load-balancer)（也可以使用 `NodePort`）来满足这一要求，在虚拟机上运行 Istio 组件，或者使用自定义网络配置，相关的高级配置另有文档描述。

* 如果您[在使用 Helm 安装时](/zh/docs/setup/kubernetes/install/helm/)尚未启用网格扩展。您需要 [Helm 客户端](https://docs.helm.sh/using_helm/)来为集群启用网格扩展。

## 安装步骤{#installation-steps}

安装过程包含服务网格的扩展准备、扩展安装以及虚拟机的配置过程。

### 扩展准备工作：设置 Kubernetes{#preparing-the-Kubernetes-cluster-for-expansion}

将非 Kubernetes 服务添加到 Istio 网格的第一步是安装配置 Istio，并生成允许网格扩展 VM 连接到网格的配置文件。要准备集群以进行网格扩展，请在具有集群管理员权限的计算机上运行以下命令：

1.  确保为集群启用了网格扩展。如果在安装时没有使用 Helm 指定 `--set global.meshExpansion=true`，则有两个选项可用于启用网格扩展，具体取决于您最初在集群上安装 Istio 的方式：

    *   如果您使用 Helm 和 Tiller 安装了 Istio，请使用新选项运行 `helm upgrade`：

    {{< text bash >}}
    $ cd install/kubernetes/helm/istio
    $ helm upgrade --set global.meshExpansion=true istio-system .
    $ cd -
    {{< /text >}}

    *   如果您没有使用 Helm 和 Tiller 安装 Istio，请使用 `helm template` 通过该选项更新您的配置并使用 `kubectl` 重新应用配置：

    {{< text bash >}}
    $ cd install/kubernetes/helm/istio
    $ helm template --set global.meshExpansion=true --namespace istio-system . > istio.yaml
    $ kubectl apply -f istio.yaml
    $ cd -
    {{< /text >}}

    {{< tip >}}
    使用 Helm 更新配置时，您可以在命令行上设置选项，如我们的示例中所示，或者添加
    它到一个 `.yaml` 配置文件，并通过 `--values` 的命令应用这些配置，这是管理具有多个配置选项时的推荐做法。您
    可以在你的 Istio 安装目录 `install/kubernetes/helm/istio` 中看到一些示例值文件并找出
    有关在[Helm 文档](https://docs.helm.sh/using_helm/#using-helm)中自定义 Helm 图表的更多信息。
    {{< /tip >}}

1.  找到 Istio ingress 网关的 IP 地址，因为网格扩展机器将访问 [Citadel](/zh/docs/concepts/security/) 和 [Pilot](/zh/docs/concepts/traffic-management/#Pilot-和-Envoy)。

    {{< text bash >}}
    $ GWIP=$(kubectl get -n istio-system service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    $ echo $GWIP
    35.232.112.158
    {{< /text >}}

1.  生成 `cluster.env` 配置以在 VM 中部署。此文件包含 Kubernetes 集群 IP 地址范围
    通过 envoy 拦截和重定向。将 Kubernetes 安装为 `servicesIpv4Cidr` 时指定 CIDR 范围。
    使用适当的值替换以下示例命令中的 `$MY_ZONE` 和 `$MY_PROJECT` 以获取 CIDR
    安装后：

    {{< text bash >}}
    $ ISTIO_SERVICE_CIDR=$(gcloud container clusters describe $K8S_CLUSTER --zone $MY_ZONE --project $MY_PROJECT --format "value(servicesIpv4Cidr)")
    $ echo -e "ISTIO_CP_AUTH=MUTUAL_TLS\nISTIO_SERVICE_CIDR=$ISTIO_SERVICE_CIDR\n" > cluster.env
    {{< /text >}}

1.  检查生成的 `cluster.env` 文件的内容。它应该类似于以下示例：

    {{< text bash >}}
    $ cat cluster.env
    ISTIO_CP_AUTH=MUTUAL_TLS
    ISTIO_SERVICE_CIDR=10.55.240.0/20
    {{< /text >}}

1.  （可选）如果 VM 仅调用网格中的服务，则可以跳过此步骤。否则，添加 VM 公开的端口
    使用以下命令到 `cluster.env` 文件。如有必要，您可以稍后更改端口。

    {{< text bash >}}
    $ echo "ISTIO_INBOUND_PORTS=3306,8080" >> cluster.env
    {{< /text >}}

1.  提取要在 VM 上使用的服务帐户的初始密钥。

    {{< text bash >}}
    $ kubectl -n $SERVICE_NAMESPACE get secret istio.default  \
        -o jsonpath='{.data.root-cert\.pem}' |base64 --decode > root-cert.pem
    $ kubectl -n $SERVICE_NAMESPACE get secret istio.default  \
        -o jsonpath='{.data.key\.pem}' |base64 --decode > key.pem
    $ kubectl -n $SERVICE_NAMESPACE get secret istio.default  \
          -o jsonpath='{.data.cert-chain\.pem}' |base64 --decode > cert-chain.pem
    {{< /text >}}

### 设置虚拟机{#setting-up-the-machines}

接下来，在要添加到网格的每台计算机上运行以下命令：

1.  使用 Envoy sidecar 安装 Debian 软件包：

    {{< text bash >}}
    $ curl -L https://storage.googleapis.com/istio-release/releases/1.0.0/deb/istio-sidecar.deb > istio-sidecar.deb
    $ dpkg -i istio-sidecar.deb
    {{< /text >}}

1.  将您在上一节中创建的 `cluster.env` 和 `*.pem` 文件复制到 VM。

1.  添加 Istio 网关的 IP 地址（我们在[上一节](#preparing-the-kubernetes-cluster-for-expansion)中找到了）
    到 `/etc/hosts` 或者
    DNS 服务器。在我们的示例中，我们将使用 `/etc/hosts`，因为它是使事情正常工作的最简单方法。以下是
    使用 Istio 网关地址更新 `/etc/hosts` 文件的示例：

    {{< text bash >}}
    $ echo "35.232.112.158 istio-citadel istio-pilot istio-pilot.istio-system" >> /etc/hosts
    {{< /text >}}

1.  在 `/etc/certs/` 下安装 `root-cert.pem`、`key.pem` 和 `cert-chain.pem`。

    {{< text bash >}}
    $ sudo mkdir /etc/certs
    $ sudo cp {root-cert.pem,cert-chain.pem,key.pem} /etc/certs
    {{< /text >}}

1.  在 `/var/lib/istio/envoy/` 下安装 `cluster.env`。

    {{< text bash >}}
    $ sudo cp cluster.env /var/lib/istio/envoy
    {{< /text >}}

1.  将 `/etc/certs/` 和 `/var/lib/istio/envoy/` 中的文件的所有权转移给 Istio 代理。

    {{< text bash >}}
    $ sudo chown -R istio-proxy /etc/certs /var/lib/istio/envoy
    {{< /text >}}

1.  验证节点代理是否有效：

    {{< text bash >}}
    $ sudo node_agent
    ....
    CSR 成功获得批准。将在 1079h59m59.84568493s 续订证书
    {{< /text >}}

1.  使用 `systemctl` 启动 Istio。

    {{< text bash >}}
    $ sudo systemctl start istio-auth-node-agent
    $ sudo systemctl start istio
    {{< /text >}}

设置完成后，计算机可以访问 Kubernetes 集群中运行的服务
或在其他网格扩展机器上。

以下示例显示使用网格扩展 VM 访问 Kubernetes 集群中运行的服务
`/etc/hosts/`，在这种情况下使用 [Bookinfo 示例](/zh/docs/examples/bookinfo/)中的服务。

1.  首先，在集群管理员机器上获取服务的虚拟 IP 地址（`clusterIP`）：

    {{< text bash >}}
$ kubectl -n bookinfo get svc productpage -o jsonpath='{.spec.clusterIP}'
10.55.246.247
    {{< /text >}}

1.  然后在网格扩展机器上，将服务名称和地址添加到其 `etc/hosts` 文件中。然后你可以连接到
    来自 VM 的集群服务，如下例所示：

    {{< text bash >}}
$ sudo echo "10.55.246.247 productpage.bookinfo.svc.cluster.local" >> /etc/hosts
$ curl productpage.bookinfo.svc.cluster.local:9080
... html content ...
    {{< /text >}}

## 在网格扩展机器上运行服务{#running-services-on-a-mesh-expansion-machine}

通过配置 [`ServiceEntry`](/docs/reference/config/networking/v1alpha3/service-entry/) 可以将 VM 服务添加到网格中。
您可以手动向 Istio 的网格模型添加其他服务，以便其他服务可以找到并引导流量到它们。每个
`ServiceEntry` 配置包含暴露特定服务的所有 VM 的 IP 地址，端口和标签（如果适用），
如下例所示。

{{< text bash yaml >}}
$ kubectl -n test apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: vm1
spec:
   hosts:
   - vm1.test.svc.cluster.local
   ports:
   - number: 80
     name: http
     protocol: HTTP
   resolution: STATIC
   endpoints:
    - address: 10.128.0.17
      ports:
        http: 8080
      labels:
        app: vm1
        version: 1
EOF
{{< /text >}}

## 故障排除{#troubleshooting}

以下是常见网格扩展问题的一些基本故障排除步骤。

*    在从 VM 发出请求到集群时，请确保不以 `root` 或 `istio-proxy` 用户身份运行请求。默认情况下，Istio 将两个用户排除在拦截之外。

*    验证计算机是否可以访问集群中运行的所有工作负载的 IP。例如：

    {{< text bash >}}
    $ kubectl get endpoints -n bookinfo productpage -o jsonpath='{.subsets[0].addresses[0].ip}'
    10.52.39.13
    {{< /text >}}

    {{< text bash >}}
    $ curl 10.52.39.13:9080
    html output
    {{< /text >}}

*    检查节点代理和 sidecar 的状态：

    {{< text bash >}}
    $ sudo systemctl status istio-auth-node-agent
    $ sudo systemctl status istio
    {{< /text >}}

*    检查进程是否正在运行。以下是您在 VM 上看到的进程示例，如果您运行 `ps`，过滤为 `istio`：

    {{< text bash >}}
    $ ps aux | grep istio
    root      6941  0.0  0.2  75392 16820 ?        Ssl  21:32   0:00 /usr/local/istio/bin/node_agent --logtostderr
    root      6955  0.0  0.0  49344  3048 ?        Ss   21:32   0:00 su -s /bin/bash -c INSTANCE_IP=10.150.0.5 POD_NAME=demo-vm-1 POD_NAMESPACE=default exec /usr/local/bin/pilot-agent proxy > /var/log/istio/istio.log istio-proxy
    istio-p+  7016  0.0  0.1 215172 12096 ?        Ssl  21:32   0:00 /usr/local/bin/pilot-agent proxy
    istio-p+  7094  4.0  0.3  69540 24800 ?        Sl   21:32   0:37 /usr/local/bin/envoy -c /etc/istio/proxy/envoy-rev1.json --restart-epoch 1 --drain-time-s 2 --parent-shutdown-time-s 3 --service-cluster istio-proxy --service-node sidecar~10.150.0.5~demo-vm-1.default~default.svc.cluster.local
    {{< /text >}}

*    检查 Envoy 访问和错误日​​志：

    {{< text bash >}}
    $ tail /var/log/istio/istio.log
    $ tail /var/log/istio/istio.err.log
    {{< /text >}}
