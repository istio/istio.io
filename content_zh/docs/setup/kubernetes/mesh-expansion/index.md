---
title: 网格扩展
description: 部署在 Kubernetes 之中的 Istio 服务网格，将虚拟机和物理机集成进入到服务网格的方法。
weight: 60
keywords: [kubernetes,虚拟机]
---

部署在 Kubernetes 之中的 Istio 服务网格，将虚拟机和物理机集成进入到服务网格的方法。

## 先决条件

* 根据[安装指南](/zh/docs/setup/kubernetes/quick-start/)的步骤在 Kubernetes 上部署 Istio。
* 待接入服务器必须能够通过 IP 接入网格中的服务端点。通常这需要 VPN 或者 VPC 的支持，或者容器网络为服务端点提供直接路由（非 NAT 或者防火墙屏蔽）。该服务器无需访问 Kubernetes 指派的集群 IP 地址。
* Istio 控制平面服务（Pilot、Mixer、Citadel）以及 Kubernetes 的 DNS 服务器必须能够从虚拟机进行访问，通常会使用[内部负载均衡器](https://kubernetes.io/docs/concepts/services-networking/service/#internal-load-balancer)（也可以使用 NodePort）来满足这一要求，在虚拟机上运行 Istio 组件，或者使用自定义网络配置，相关的高级配置另有文档描述。

## 安装步骤

安装过程包含服务网格的扩展准备、扩展安装以及虚拟机的配置过程。

在发布包中有一个示例脚本：[`install/tools/setupMeshEx.sh`]({{< github_file >}}/install/tools/setupMeshEx.sh)，这个脚本用来协助 Kubernetes 中的设置，请查阅这个脚本，注意脚本的内容以及所需的环境变量（例如 `GCP_OPTS`）。

还有一个示例脚本是用来协助进行虚拟机配置的，这个脚本同样包含在发布包中：[`install/tools/setupIstioVM.sh`]({{< github_file >}}/install/tools/setupIstioVM.sh)。可以根据本地环境和 DNS 需求对这个脚本进行定制。

### 扩展准备工作：设置 Kubernetes

* 为 Kube DNS、Pilot、Mixer 以及 Citadel 设置内部负载均衡器。这个步骤跟云提供商有关，所以你可能需要编辑注解。如果用于演示目的，或者云供应商没有提供负载均衡支持，可以采用[基于 Keepalived 的 ILB](https://github.com/gyliu513/work/tree/master/k8s/charts/keepalived)。

    {{< text bash >}}
    $ kubectl apply -f @install/kubernetes/mesh-expansion.yaml@
    {{< /text >}}

* 生成 Istio 的 `cluster.env` 配置，用来在虚拟机上进行配置。这个文件包含了将要拦截的集群 IP 范围。

    {{< text bash >}}
    $ export GCP_OPTS="--zone MY_ZONE --project MY_PROJECT"
    $ @install/tools/setupMeshEx.sh@ generateClusterEnv MY_CLUSTER_NAME
    {{< /text >}}

    生成文件的示例：

    {{< text bash >}}
    $ cat cluster.env
    ISTIO_SERVICE_CIDR=10.63.240.0/20
    {{< /text >}}

* 为虚拟机生成 DNS 配置文件。这一步骤让虚拟机上的应用能够解析集群的服务名称，然后被 Sidecar 劫持和转发。

    {{< text bash >}}
    $ @install/tools/setupMeshEx.sh@ generateDnsmasq
    {{< /text >}}

    生成文件的示例：

    {{< text bash >}}
    $ cat kubedns
    server=/svc.cluster.local/10.150.0.7
    address=/istio-mixer/10.150.0.8
    address=/istio-pilot/10.150.0.6
    address=/istio-citadel/10.150.0.9
    address=/istio-mixer.istio-system/10.150.0.8
    address=/istio-pilot.istio-system/10.150.0.6
    address=/istio-citadel.istio-system/10.150.0.9
    {{< /text >}}

### 设置虚拟机

作为例子，可以使用下面的脚本来完成拷贝和安装：

{{< text bash >}}
$ export GCP_OPTS="--zone MY_ZONE --project MY_PROJECT"
$ export SERVICE_NAMESPACE=vm
{{< /text >}}

如果是在 GCE 虚拟机上，可以运行：

{{< text bash >}}
$ @install/tools/setupMeshEx.sh@ gceMachineSetup VM_NAME
{{< /text >}}

否则运行：

{{< text bash >}}
$ @install/tools/setupMeshEx.sh@ machineSetup VM_NAME
{{< /text >}}

这里 GCE 提供了更好的用户体验，这是因为 Node Agent 始终可以依赖 GCE metadata instance 文档来进行 Citadel 认证。其他的服务器，例如自部署的服务器或虚拟机，必须创建一个密钥/证书的组合来作为凭据，这种凭据通常是有寿命限制的。当证书过期，就只能重新运行一次了。

等价的手工操作：

------ 这里开始手工设置 ------

* 为每个加入集群的服务器拷贝配置文件以及 Istio 的 Debian 文件，分别保存为 `/etc/dnsmasq.d/kubedns` 以及 `/var/lib/istio/envoy/cluster.env`。

* 配置和校验 DNS 设置，需要安装 `dnsmasq`，并把这 DNS 服务设置加入 `/etc/resolv.conf` 或者通过 DHCP 脚本进行传播。要检查配置情况，只需检查虚拟机是否能够解析名称并连接到 Pilot 上，例如：

    在虚拟机/外部主机:

    {{< text bash >}}
    $ host istio-pilot.istio-system
    {{< /text >}}

    示例响应信息：

    {{< text plain >}}
    $ istio-pilot.istio-system has address 10.150.0.6
    {{< /text >}}

    检查是否可以解析集群 IP，实际地址可能会随不同的部署情况而不同。

    {{< text bash >}}
    $ host istio-pilot.istio-system.svc.cluster.local.
    {{< /text >}}

    示例响应信息：

    {{< text plain >}}
    istio-pilot.istio-system.svc.cluster.local has address 10.63.247.248
    {{< /text >}}

    用类似的方法检查 istio-ingress：

    {{< text bash >}}
    $ host istio-ingress.istio-system.svc.cluster.local.
    {{< /text >}}

    示例响应信息：

    {{< text plain >}}
    istio-ingress.istio-system.svc.cluster.local has address 10.63.243.30
    {{< /text >}}

* 检查虚拟机到 Pilot 或者端点的连接来验证连通性

    {{< text bash json >}}
    $ curl 'http://istio-pilot.istio-system:8080/v1/registration/istio-pilot.istio-system.svc.cluster.local|http-discovery'
    {
      "hosts": [
       {
        "ip_address": "10.60.1.4",
        "port": 8080
       }
      ]
    }
    {{< /text >}}

    在虚拟机上使用上面的地址。会直接连接到运行中的 istio-pilot pod 上。

    {{< text bash >}}
    $ curl 'http://10.60.1.4:8080/v1/registration/istio-pilot.istio-system.svc.cluster.local|http-discovery'
    {{< /text >}}

* 解开 Istio 的 Secret 对象，并复制到服务器上。包含 Citadel 的 Istio，即使没有启用自动的 双向 TLS 认证，也会生成 Istio secret（每个 Service account 都会生成 Secret，命名为 `istio.<serviceaccount>`）。这里建议进行这个操作，这样以后启用 双向 TLS 或者未来升级到缺省启用 双向 TLS 的版本会更加方便。

    `ACCOUNT` 缺省就是 `default`，或者 `SERVICE_ACCOUNT` 环境变量。
    `NAMESPACE` 缺省为当前命名空间，或者 `SERVICE_NAMESPACE` 环境变量（这一步骤通过 machineSetup 完成）在 Mac 上可使用 `brew install base64` 或者 `set BASE64_DECODE="/usr/bin/base64 -D"`。

    {{< text bash >}}
    $ @install/tools/setupMeshEx.sh@ machineCerts ACCOUNT NAMESPACE
    {{< /text >}}

    生成的几个文件 (`key.pem`, `root-cert.pem`, `cert-chain.pem`) 必须复制到每台服务器的 `/etc/certs`，让 istio proxy 访问。

* 安装 Istio Debian 文件，启动 `istio` 以及 `istio-auth-node-agent` 服务。从 [GitHub 发布页面](https://github.com/istio/istio/releases) 可以得到 Debian 文件，或者：

    {{< text bash >}}
    $ source istio.VERSION # 定义 URL 和版本变量
    $ curl -L ${PILOT_DEBIAN_URL}/istio-sidecar.deb > istio-sidecar.deb
    $ dpkg -i istio-sidecar.deb
    $ systemctl start istio
    $ systemctl start istio-auth-node-agent
    {{< /text >}}

------ 手工配置结束 ------

配置完成后，服务器就可以访问在 Kubernetes 集群上运行的服务，以及网格扩展之后包含的其他虚拟机。

{{< text bash >}}
$ curl productpage.bookinfo.svc.cluster.local:9080
... html content ...
{{< /text >}}

检查运行的进程：

{{< text bash >}}
$ ps aux |grep istio
root      6941  0.0  0.2  75392 16820 ?        Ssl  21:32   0:00 /usr/local/istio/bin/node_agent --logtostderr
root      6955  0.0  0.0  49344  3048 ?        Ss   21:32   0:00 su -s /bin/bash -c INSTANCE_IP=10.150.0.5 POD_NAME=demo-vm-1 POD_NAMESPACE=default exec /usr/local/bin/pilot-agent proxy > /var/log/istio/istio.log istio-proxy
istio-p+  7016  0.0  0.1 215172 12096 ?        Ssl  21:32   0:00 /usr/local/bin/pilot-agent proxy
istio-p+  7094  4.0  0.3  69540 24800 ?        Sl   21:32   0:37 /usr/local/bin/envoy -c /etc/istio/proxy/envoy-rev1.json --restart-epoch 1 --drain-time-s 2 --parent-shutdown-time-s 3 --service-cluster istio-proxy --service-node sidecar~10.150.0.5~demo-vm-1.default~default.svc.cluster.local
{{< /text >}}

Istio 认证使用的 Node Agent 健康运行：

{{< text bash >}}
$ sudo systemctl status istio-auth-node-agent
● istio-auth-node-agent.service - istio-auth-node-agent: The Istio auth node agent
   Loaded: loaded (/lib/systemd/system/istio-auth-node-agent.service; disabled; vendor preset: enabled)
   Active: active (running) since Fri 2017-10-13 21:32:29 UTC; 9s ago
     Docs: https://istio.io/
 Main PID: 6941 (node_agent)
    Tasks: 5
   Memory: 5.9M
      CPU: 92ms
   CGroup: /system.slice/istio-auth-node-agent.service
           └─6941 /usr/local/istio/bin/node_agent --logtostderr

Oct 13 21:32:29 demo-vm-1 systemd[1]: Started istio-auth-node-agent: The Istio auth node agent.
Oct 13 21:32:29 demo-vm-1 node_agent[6941]: I1013 21:32:29.469314    6941 main.go:66] Starting Node Agent
Oct 13 21:32:29 demo-vm-1 node_agent[6941]: I1013 21:32:29.469365    6941 nodeagent.go:96] Node Agent starts successfully.
Oct 13 21:32:29 demo-vm-1 node_agent[6941]: I1013 21:32:29.483324    6941 nodeagent.go:112] Sending CSR (retrial #0) ...
Oct 13 21:32:29 demo-vm-1 node_agent[6941]: I1013 21:32:29.862575    6941 nodeagent.go:128] CSR is approved successfully. Will renew cert in 29m59.137732603s
{{< /text >}}

## 在网格扩展服务器上运行服务

* 配置 Sidecar 来拦截端口，这一配置存在于 `/var/lib/istio/envoy/sidecar.env`，使用 `ISTIO_INBOUND_PORTS` 环境变量。

    示例 (在运行服务的虚拟机上):

    {{< text bash >}}
    $ echo "ISTIO_INBOUND_PORTS=3306,8080" > /var/lib/istio/envoy/sidecar.env
    $ systemctl restart istio
    {{< /text >}}

* 手工配置一个没有选择器的服务和端点，用来承载没有对应 Kubernetes Pod 的服务。

    例如在一个有权限的服务器上修改 Kubernetes 服务：

    {{< text bash >}}
    $ istioctl -n onprem register mysql 1.2.3.4 3306
    $ istioctl -n onprem register svc1 1.2.3.4 http:7000
    {{< /text >}}

经过这个步骤，Kubernetes Pod 和其他网格扩展包含的服务器就可以访问运行于这一服务器上的服务了。
