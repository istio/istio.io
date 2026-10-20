---
title: 虚拟机安装
description: 部署 Istio，接入虚拟机中运行的工作负载。
weight: 60
keywords:
- kubernetes
- virtual-machine
- gateways
- vms
owner: istio/wg-environments-maintainers
test: yes
---

请遵循本指南部署 Istio，并接入虚拟机。

## 先决条件 {#prerequisites}

1. [下载 Istio 发行版](/zh/docs/setup/additional-setup/download-istio-release/)
1. 执行必要的[平台安装](/zh/docs/setup/platform-setup/)
1. 检查 [Pod 和 Service 的要求](/zh/docs/ops/deployment/application-requirements/)
1. 虚拟机必须 IP 连通到目标网格的入口网关，如果有更高的性能需求，也可通过三层网络连通网格中的每个 Pod。
1. 阅读[虚拟机架构](/zh/docs/ops/deployment/vm-architecture/)来理解 Istio 虚拟机集成的高级架构。

## 准备指导环境  {#prepare-the-guide-environment}

1. 创建虚拟机
1. 在集群的计算机上设置环境变量 `VM_APP`、`WORK_DIR`、`VM_NAMESPACE` 和 `SERVICE_ACCOUNT`
   （例如：`WORK_DIR="${HOME}/vmintegration"`）：

    {{< tabset category-name="network-mode" >}}

    {{< tab name="单一网络" category-value="single" >}}

    {{< text bash >}}
    $ VM_APP="<将在这台虚机上运行的应用名>"
    $ VM_NAMESPACE="<您的服务所在的命名空间>"
    $ WORK_DIR="<证书工作目录>"
    $ SERVICE_ACCOUNT="<为这台虚机提供的 Kubernetes 的服务账号名称>"
    $ CLUSTER_NETWORK=""
    $ VM_NETWORK=""
    {{< /text >}}

    {{< /tab >}}

    {{< tab name="聚合网络" category-value="multiple" >}}

    {{< text bash >}}
    $ VM_APP="<将在这台虚机上运行的应用名>"
    $ VM_NAMESPACE="<您的服务所在的命名空间>"
    $ WORK_DIR="<证书工作目录>"
    $ SERVICE_ACCOUNT="<为这台虚机提供的 Kubernetes 的服务账号名称>"
    $ # 根据需要自定义网络名称
    $ CLUSTER_NETWORK="kube-network"
    $ VM_NETWORK="vm-network"
    {{< /text >}}

    {{< /tab >}}

    {{< /tabset >}}

1. 创建工作目录：

    {{< text syntax=bash snip_id=setup_wd >}}
    $ mkdir -p "${WORK_DIR}"
    {{< /text >}}

## 安装 Istio 控制平面 {#install-control-plane}

如果您的集群已经有一个 Istio 控制平面，您可以跳过安装步骤，但是仍然需要为虚拟机访问公开控制平面。

安装 Istio，打开控制平面的对外访问，以便您的虚拟机可以访问它。

1. 创建用于安装 Istio 的 `IstioOperator`。

    {{< text syntax="bash yaml" snip_id=setup_iop >}}
    $ cat <<EOF > ./vm-cluster.yaml
    apiVersion: install.istio.io/v1alpha1
    kind: IstioOperator
    metadata:
      name: istio
    spec:
      values:
        global:
          network: "${CLUSTER_NETWORK}"
    EOF
    {{< /text >}}

1. 安装 Istio。

    {{< text syntax=bash snip_id=install_istio >}}
    $ istioctl install -f vm-cluster.yaml
    {{< /text >}}

1. 部署东西向网关：

    {{< warning >}}
    如果控制平面安装的是一个修正版本，请将参数 `--revision rev` 添加到 `gen-eastwest-gateway.sh` 命令。
    {{< /warning >}}

    {{< tabset category-name="network-mode" >}}

    {{< tab name="单一网络" category-value="single" >}}

    {{< text syntax=bash snip_id=install_eastwest >}}
    $ @samples/multicluster/gen-eastwest-gateway.sh@ --single-cluster | istioctl install -y -f -
    {{< /text >}}

    {{< /tab >}}

    {{< tab name="聚合网络" category-value="multiple" >}}

    {{< text bash >}}
    $ @samples/multicluster/gen-eastwest-gateway.sh@ \
    --network "${CLUSTER_NETWORK}" | \
    istioctl install -y -f -
    {{< /text >}}

    {{< /tab >}}

    {{< /tabset >}}

1. 使用东西向网关暴露集群内部服务：

    {{< tabset category-name="network-mode" >}}

    {{< tab name="单一网络" category-value="single" >}}

    暴露控制平面：

    {{< text syntax=bash snip_id=expose_istio >}}
    $ kubectl apply -f @samples/multicluster/expose-istiod.yaml@
    {{< /text >}}

    {{< /tab >}}

    {{< tab name="聚合网络" category-value="multiple" >}}

    暴露控制平面：

    {{< text bash >}}
    $ kubectl apply -f @samples/multicluster/expose-istiod.yaml@
    {{< /text >}}

    暴露集群服务：

    {{< text bash >}}
    $ kubectl apply -n istio-system -f @samples/multicluster/expose-services.yaml@
    {{< /text >}}

    确保使用定义的集群网络为 istio-system 命名空间打标签：

    {{< text bash >}}
    $ kubectl label namespace istio-system topology.istio.io/network="${CLUSTER_NETWORK}"
    {{< /text >}}

    {{< /tab >}}

    {{< /tabset >}}

## 配置虚拟机的命名空间 {#configure-the-virtual-machine-namespace}

1. 创建用于托管虚拟机的命名空间：

    {{< text syntax=bash snip_id=install_namespace >}}
    $ kubectl create namespace "${VM_NAMESPACE}"
    {{< /text >}}

1. 为虚拟机创建 ServiceAccount：

    {{< text syntax=bash snip_id=install_sa >}}
    $ kubectl create serviceaccount "${SERVICE_ACCOUNT}" -n "${VM_NAMESPACE}"
    {{< /text >}}

## 创建要传输到虚拟机的文件 {#create-files-to-transfer-to-the-virtual-machine}

首先，为虚拟机创建 `WorkloadGroup` 模板：

{{< text syntax=bash snip_id=create_wg >}}
$ cat <<EOF > workloadgroup.yaml
apiVersion: networking.istio.io/v1
kind: WorkloadGroup
metadata:
  name: "${VM_APP}"
  namespace: "${VM_NAMESPACE}"
spec:
  metadata:
    labels:
      app: "${VM_APP}"
  template:
    serviceAccount: "${SERVICE_ACCOUNT}"
    network: "${VM_NETWORK}"
EOF
{{< /text >}}

然后，为了支持自动创建 `WorkloadEntry`，将 `WorkloadGroup` 推送到集群中：

{{< text syntax=bash snip_id=apply_wg >}}
$ kubectl --namespace "${VM_NAMESPACE}" apply -f workloadgroup.yaml
{{< /text >}}

{{< tip >}}
还可以进行应用程序健康检查，其 API 和行为与
[Kubernetes 就绪探针](https://kubernetes.io/zh-cn/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)相同。
只需在 `WorkloadGroup` 的 spec 中添加 `probe`，例如探测应用程序的 `/ready` 端点：

{{< text yaml >}}
spec:
  probe:
    periodSeconds: 5
    initialDelaySeconds: 1
    httpGet:
      port: 8080
      path: /ready
{{< /text >}}

通过这个配置，自动生成的 `WorkloadEntry` 在探针成功之前不会被标记为 "Ready"。
{{< /tip >}}

接下来，使用 `istioctl x workload entry` 命令来生成：

* `cluster.env`：包含用来识别命名空间、服务帐户、网络 CIDR、和入站端口（可选）的元数据。
* `istio-token`：用来从 CA 获取证书的 Kubernetes 令牌。
* `mesh.yaml`：提供 `ProxyConfig` 来配置 `discoveryAddress`、健康检查以及一些认证操作。
* `root-cert.pem`：用于认证的根证书。
* `hosts`：`/etc/hosts` 的补充，代理将使用该补充从 Istiod 获取 xDS.*。

{{< idea >}}
一个复杂的选项涉及在虚拟机中配置 DNS 以引用外部 DNS 服务器。
此选项超出了本指南的范围。
{{< /idea >}}

{{< tabset category-name="registration-mode" >}}

{{< tab name="默认" category-value="default" >}}

{{< text bash >}}
$ istioctl x workload entry configure \
    -f workloadgroup.yaml \
    -o "${WORK_DIR}" \
    --ingressService istio-eastwestgateway
{{< /text >}}

{{< /tab >}}

{{< tab name="自动化 WorkloadEntry 创建" category-value="autoreg" >}}

{{< boilerplate alpha >}}

{{< text syntax=bash snip_id=configure_wg >}}
$ istioctl x workload entry configure \
    -f workloadgroup.yaml \
    -o "${WORK_DIR}" \
    --ingressService istio-eastwestgateway \
    --autoregister
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

{{< tip >}}
生成的 `hosts` 文件会将 istiod 的主机名映射到东西向网关的 IP 地址，
该命令会从 `--ingressService` 所指定 `Service` 的负载均衡器或外部 IP 中读取这个地址。

如果该地址无法解析为 IP（无论是因为找不到该 `Service`，还是因为负载均衡器只能通过主机名访问），
生成的 `hosts` 文件都将为空，虚拟机也将无法访问 istiod。
此时可以通过 `--ingressIP` 传入网关地址来显式设置。

或者，您也可以使用虚拟机已经能够解析的 DNS 名称来暴露 istiod，从而完全跳过 `/etc/hosts` 这一步。
这需要在安装控制平面时将 `values.pilot.env.ISTIOD_CUSTOM_HOST` 设置为该名称，
以便 istiod 为该名称签发服务证书；同时将 `mesh.yaml` 中的 `defaultConfig.discoveryAddress`
替换为 `<custom-host>:15012`，并将 `cluster.env` 中的 `CA_ADDR` 设置为相同的地址。
{{< /tip >}}

## 配置虚拟机 {#configure-the-virtual-machine}

在要添加到 Istio 网格的虚拟机上，运行以下命令：

1. 将文件从 `"${WORK_DIR}"` 安全上传到虚拟机。如何安全的传输这些文件，
   这需要考虑到您的信息安全策略。本指南为方便起见，将所有必备文件上传到虚拟机中的
   `"${HOME}"` 目录。

1. 将根证书安装到目录 `/etc/certs`：

    {{< text bash >}}
    $ sudo mkdir -p /etc/certs
    $ sudo cp "${HOME}"/root-cert.pem /etc/certs/root-cert.pem
    {{< /text >}}

1. 将令牌安装到目录 `/var/run/secrets/tokens`：

    {{< text bash >}}
    $ sudo  mkdir -p /var/run/secrets/tokens
    $ sudo cp "${HOME}"/istio-token /var/run/secrets/tokens/istio-token
    {{< /text >}}

1. 安装包含 Istio 虚拟机集成运行时（runtime）的包：

    {{< tabset category-name="vm-os" >}}

    {{< tab name="Debian" category-value="debian" >}}

    {{< text bash >}}
    $ curl -LO https://blob.istio.io/istio-release/releases/{{< istio_full_version >}}/deb/istio-sidecar.deb
    $ sudo dpkg -i istio-sidecar.deb
    {{< /text >}}

    {{< /tab >}}

    {{< tab name="CentOS" category-value="centos" >}}

    注意：目前仅支持 CentOS 8。

    {{< text bash >}}
    $ curl -LO https://blob.istio.io/istio-release/releases/{{< istio_full_version >}}/rpm/istio-sidecar.rpm
    $ sudo rpm -i istio-sidecar.rpm
    {{< /text >}}

    {{< /tab >}}

    {{< /tabset >}}

1. 将 `cluster.env` 安装到目录 `/var/lib/istio/envoy/` 中：

    {{< text bash >}}
    $ sudo cp "${HOME}"/cluster.env /var/lib/istio/envoy/cluster.env
    {{< /text >}}

1. 将网格配置文件 [Mesh Config](/zh/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig)
   安装到目录 `/etc/istio/config/mesh`：

    {{< text bash >}}
    $ sudo cp "${HOME}"/mesh.yaml /etc/istio/config/mesh
    {{< /text >}}

1. 将 istiod 主机添加到 `/etc/hosts`：

    {{< text bash >}}
    $ sudo sh -c 'cat $(eval echo ~$SUDO_USER)/hosts >> /etc/hosts'
    {{< /text >}}

1. 把文件 `/etc/certs/` 和 `/var/lib/istio/envoy/` 的所有权转移给 Istio 代理：

    {{< text bash >}}
    $ sudo mkdir -p /etc/istio/proxy
    $ sudo chown -R istio-proxy /var/lib/istio /etc/certs /etc/istio/proxy /etc/istio/config /var/run/secrets /etc/certs/root-cert.pem
    {{< /text >}}

## 在虚拟机中启动 Istio {#start-within-the-virtual-machine}

1. 启动 Istio 代理：

    {{< text bash >}}
    $ sudo systemctl start istio
    {{< /text >}}

## 验证 Istio 是否成功工作 {#verify-works-successfully}

1. 检查 `/var/log/istio/istio.log` 中的日志，您应该能看到类似于以下的内容：

    {{< text bash >}}
    $ 2020-08-21T01:32:17.748413Z info sds resource:default pushed key/cert pair to proxy
    $ 2020-08-21T01:32:20.270073Z info sds resource:ROOTCA new connection
    $ 2020-08-21T01:32:20.270142Z info sds Skipping waiting for gateway secret
    $ 2020-08-21T01:32:20.270279Z info cache adding watcher for file ./etc/certs/root-cert.pem
    $ 2020-08-21T01:32:20.270347Z info cache GenerateSecret from file ROOTCA
    $ 2020-08-21T01:32:20.270494Z info sds resource:ROOTCA pushed root cert to proxy
    $ 2020-08-21T01:32:20.270734Z info sds resource:default new connection
    $ 2020-08-21T01:32:20.270763Z info sds Skipping waiting for gateway secret
    $ 2020-08-21T01:32:20.695478Z info cache GenerateSecret default
    $ 2020-08-21T01:32:20.695595Z info sds resource:default pushed key/cert pair to proxy
    {{< /text >}}

1. 创建命名空间，用以部署基于 Pod 的服务：

    {{< text bash >}}
    $ kubectl create namespace sample
    $ kubectl label namespace sample istio-injection=enabled
    {{< /text >}}

1. 部署 `HelloWorld` 服务：

    {{< text bash >}}
    $ kubectl apply -f @samples/helloworld/helloworld.yaml@
    {{< /text >}}

1. 从虚拟机向服务发送请求：

    {{< text bash >}}
    $ curl helloworld.sample.svc:5000/hello
    Hello version: v1, instance: helloworld-v1-578dd69f69-fxwwk
    {{< /text >}}

## 下一步 {#next-step}

更多关于虚拟机的信息：

* [调试虚拟机](/zh/docs/ops/diagnostic-tools/virtual-machines/)解决虚拟机问题。
* [部署在虚拟机上的 Bookinfo](/zh/docs/examples/virtual-machines/) 设置虚拟机的示例部署。

## 卸载 {#uninstall}

在虚拟机中停止 Istio：

{{< text bash >}}
$ sudo systemctl stop istio
{{< /text >}}

然后，删除 Istio-sidecar 的发行包：

{{< tabset category-name="vm-os" >}}

{{< tab name="Debian" category-value="debian" >}}

{{< text bash >}}
$ sudo dpkg -r istio-sidecar
$ dpkg -s istio-sidecar
{{< /text >}}

{{< /tab >}}

{{< tab name="CentOS" category-value="centos" >}}

{{< text bash >}}
$ sudo rpm -e istio-sidecar
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

要卸载 Istio，请运行以下命令：

{{< text bash >}}
$ kubectl delete -f @samples/multicluster/expose-istiod.yaml@
$ istioctl uninstall -y --purge
{{< /text >}}

默认情况下，控制平面的命名空间（比如：`istio-system`）并不会被删除。
如果确认不再使用，使用下面命令删除：

{{< text bash >}}
$ kubectl delete namespace istio-system
{{< /text >}}
