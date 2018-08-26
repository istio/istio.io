---
title: Istio 多集群设置
description: 安装支持多集群的 Istio。
weight: 60
keywords: [kubernetes,多集群]
---

介绍 Istio 多集群的安装过程。

## 先决条件

* 两个或更多的 **1.9 以上版本** 的 Kubernetes 集群。
* 在 **一个** Kubernetes 上部署 [Istio 控制平面](/zh/docs/setup/kubernetes/quick-start/) 的能力。
* RFC 1918、VPN 或者其他更高级的网络技术，需完成下列要求：
    * 各集群的 Pod CIDR 范围和 Service CIDR 范围必须是唯一的，不允许相互重叠。
    * 每个集群中的所有的 Pod CIDR 需要能够互相路由。
    * 所有的 Kubernetes 控制平面 API Server 互相可路由。
* Helm **2.7.2 或者更新的版本**。Tiller 可选。

## 概要

多集群是在 Kubernetes 控制平面上运行远程配置，连接到 **同一个** Istio 控制平面。（主控）Istio 在连接了一个或多个 Kubernetes 集群之后，Envoy 就能和这个 Istio 控制平面进行通信，并生成一个跨越多个 Kubernetes 集群的网格网络。

本指南介绍如何通过使用 Istio 仓库里提供的清单和 Helm chart安装一个多集群 Istio 拓扑。

## 在本地部署 Istio 的控制平面

在 **一个** Kubernetes 集群上[安装 Istio 控制平面](/zh/docs/setup/kubernetes/quick-start/#安装步骤)

## 在每个远程集群上安装 Istio 远程组件

Istio-remote 组件必须在每个远程集群上分别部署。有两种安装方式：使用 Helm 结合 Tiller，或者用 Helm 配合 `kubectl`。

### 从 Istio 控制平面设置 Istio 远程组件所需的 Pod IP 环境变量

> 在进行本节操作之前，请等待 Istio 控制平面完成初始化。
> 这个操作必须在 Istio 控制平面所在集群上运行，以便于完成对 Pilot、Policy 以及 Pod IP 端点的抓取工作。
> 如果在每个远程集群上都使用了 Helm + Tiller 的组合，在使用 Helm 把远程机群和 Istio 控制平面连接起来之前，首先要把环境变量拷贝到各个 Node 上。

{{< text bash >}}
$ export PILOT_POD_IP=$(kubectl -n istio-system get pod -l istio=pilot -o jsonpath='{.items[0].status.podIP}')
$ export POLICY_POD_IP=$(kubectl -n istio-system get pod -l istio-mixer-type=policy -o jsonpath='{.items[0].status.podIP}')
$ export STATSD_POD_IP=$(kubectl -n istio-system get pod -l istio=statsd-prom-bridge -o jsonpath='{.items[0].status.podIP}')
$ export TELEMETRY_POD_IP=$(kubectl -n istio-system get pod -l istio-mixer-type=telemetry -o jsonpath='{.items[0].status.podIP}')
$ export ZIPKIN_POD_IP=$(kubectl -n istio-system get pod -l app=jaeger -o jsonpath='{.items[0].status.podIP}')
{{< /text >}}

接着选择以下选项的其中一个将会把远程集群连接到本地集群：

* 通过 [`kubectl` + Helm](#使用-helm-kubectl-把远程集群连接到本地)

* 通过 [Helm + Tiller](#使用-helm-tiller-进行远程集群的连接)

* 使用 *sidecar 注入。*  默认操作是在远程集群上启用自动 sidecar 注入，更多手动 sidecar 注入示例，详见[手动 sidecar 注入示例](#远程集群手动-sidecar-注入示例)

### 使用 Helm + `kubectl` 把远程集群连接到本地

1. 在远程集群上用 Helm template 命令来指定 Istio 控制平面的服务端点：

    {{< text bash >}}
    $ helm template install/kubernetes/helm/istio-remote --namespace istio-system \
    --name istio-remote \
    --set global.remotePilotAddress=${PILOT_POD_IP} \
    --set global.remotePolicyAddress=${POLICY_POD_IP} \
    --set global.remoteTelemetryAddress=${TELEMETRY_POD_IP} \
    --set global.proxy.envoyStatsd.enabled=true \
    --set global.proxy.envoyStatsd.host=${STATSD_POD_IP} \
    --set global.remoteZipkinAddress=${ZIPKIN_POD_IP} > $HOME/istio-remote.yaml
    {{< /text >}}

1. 为远程 Istio 创建一个 namespace。

    {{< text bash >}}
    $ kubectl create ns istio-system
    {{< /text >}}

1. 实例化远程集群并连接 Istio 控制平面：

    {{< text bash >}}
    $ kubectl create -f $HOME/istio-remote.yaml
    {{< /text >}}

1.  标记所有需要自动 sidecar 注入的远程集群的命名空间，以下示例标记了 `default` 命名空间。

    {{< text bash >}}
    $ kubectl label namespace default istio-injection=enabled
    {{< /text >}}

    在该操作上加以修改可以将任何其他的 kubernetes 命名空间设置自动 sidecar 注入。

### 使用 Helm + Tiller 进行远程集群的连接

1. 如果还没有给 Helm 设置 Service account，请执行：

    {{< text bash >}}
    $ kubectl create -f install/kubernetes/helm/helm-service-account.yaml
    {{< /text >}}

1. Helm 初始化：

    {{< text bash >}}
    $ helm init --service-account tiller
    {{< /text >}}

1. 安装 Helm Chart：

    {{< text bash >}}
    $ helm install install/kubernetes/helm/istio-remote --name istio-remote  --namespace istio-system --set global.remotePilotAddress=${PILOT_POD_IP} --set global.remotePolicyAddress=${POLICY_POD_IP} --set global.remoteTelemetryAddress=${TELEMETRY_POD_IP} --set global.proxy.envoyStatsd.enabled=true --set global.proxy.envoyStatsd.host=${STATSD_POD_IP} --set global.remoteZipkinAddress=${ZIPKIN_POD_IP}
    {{< /text >}}

### Helm 配置参数

为了使远程集群的 sidecar 与 Istio 控制平面进行交互，`pilot`、
`policy`、`telemetry`、`statsd` 和跟踪服务端点需要在 `istio-remote` Helm chart中配置。
该 chart 默认启用远程集群中的自动 sidecar 注入，但可以通过 chart 变量禁用。以下表格描述了
`istio-remote` Helm chart的配置参数。

| Helm 变量 | 可接受取值 | 默认 | 用途 |
| --- | --- | --- | --- |
| `global.remotePilotAddress` | 有效的 IP 地址或主机名 | None | 指定 Istio 控制平面辅助 Pod IP 地址或远程集群的 DNS 可解析主机名 |
| `global.remotePolicyAddress` | 有效的 IP 地址或主机名 | None | 指定 Istio 控制平面的策略 Pod IP 地址或远程集群 DNS 可解析主机名 |
| `global.remoteTelemetryAddress` | 有效的 IP 地址或主机名 | None | 指定 Istio 控制平面的遥测 Pod IP 地址或远程集群 DNS 可解析主机名 |
| `global.proxy.envoyStatsd.enabled` | true, false | false | 指定 Istio 控制平面是否启用了 Envoy Statsd |
| `global.proxy.envoyStatsd.host` | 有效的 IP 地址或主机名 | None | 指定 Istio 控制平面的 `statsd-prom-bridge` Pod IP 地址或远程集群 DNS 可解析主机名。如果 `global.proxy.envoyStatsd.enabled = false` 则忽略。 |
| `global.remoteZipkinAddress` | 有效的 IP 地址或主机名 | None | 指定 Istio 控制平面的跟踪应用程序 Pod IP 地址或远程集群 DNS 可解析主机名，例如 `zipkin` 或 `jaeger`。|
| `sidecarInjectorWebhook.enabled` | true, false | true | 指定是否在远程集群上启用自动 sidecar 注入 |
| `global.remotePilotCreateSvcEndpoint` | true, false | false | 如果设置，使用 `remotePilotAddress` IP `istio-pilot` 的无选择器服务和端点将会被创建，这将确保 `istio-pilot.<namespace>` 在远程集群中是 DNS 可解析的。|

## 为远程集群生成 `kubeconfigs`

Istio 控制平面需要访问网格中的所有集群才能发现服务、endpoint 和 pod 属性。 以下将描述如何生成一个 `kubeconfig` 文件用于 Istio 控制平面使用的远程集群。
在远程集群中，`istio-remote` Helm chart 创建了一个名字叫 `istio-multi` 的 Kubernetes service account，它用于最小的 RBAC 访问权限。以下使用 `istio-remote` Helm chart 生成一个 `kubeconfig` 文件给远程集群，用于创建 `istio-multi` service account 的证书。应在要添加到服务网格的每个远程集群上执行以下过程，该过程要求集群管理员用户访问远程集群。

1.  准备环境变量为 `ServiceAccount` `istio-multi` 构建 `kubeconfig` 文件：

    {{< text bash >}}
    $ export WORK_DIR=$(pwd)
    $ CLUSTER_NAME=$(kubectl config view --minify=true -o "jsonpath={.clusters[].name}")
    $ export KUBECFG_FILE=${WORK_DIR}/${CLUSTER_NAME}
    $ SERVER=$(kubectl config view --minify=true -o "jsonpath={.clusters[].cluster.server}")
    $ NAMESPACE=istio-system
    $ SERVICE_ACCOUNT=istio-multi
    $ SECRET_NAME=$(kubectl get sa ${SERVICE_ACCOUNT} -n ${NAMESPACE} -o jsonpath='{.secrets[].name}')
    $ CA_DATA=$(kubectl get secret ${SECRET_NAME} -n ${NAMESPACE} -o "jsonpath={.data['ca\.crt']}")
    $ TOKEN=$(kubectl get secret ${SECRET_NAME} -n ${NAMESPACE} -o "jsonpath={.data['token']}" | base64 --decode)
    {{< /text >}}

    __注意__: 在许多系统上， `base64 --decode` 的替代方案是 `openssl enc -d -base64 -A`。

1. 在工作目录为 `ServiceAccount` `istio-multi` 创建 `kubeconfig`：

    {{< text bash >}}
    $ cat <<EOF > ${KUBECFG_FILE}
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

1. _(可选)_  设置环境变量，创建文件以创建远程集群 secret：

    {{< text bash >}}
    $ cat <<EOF > remote_cluster_env_vars
    export CLUSTER_NAME=${CLUSTER_NAME}
    export KUBECFG_FILE=${KUBECFG_FILE}
    export NAMESPACE=${NAMESPACE}
    EOF
    {{< /text >}}

此时，远程集群的 `kubeconfig` 文件已在当前目录中创建，集群的文件名与原始的 `kubeconfig` 集群名称相同。

## 实例化每个远程集群的凭据

通过使用 `WORK_DIR`、`CLUSTER_NAME` 在运行 Istio 控制面板的集群上执行操作，`NAMESPACE` 环境变量设置在[为远程集群生成 kubeconfig](#为远程集群生成-kubeconfigs) 步骤.

* _(可选)_  获取为远程集群 secret 创建的环境变量文件：

    {{< text bash >}}
    $ source remote_cluster_env_vars
    {{< /text >}}

Istio 可以安装在除 istio-system 之外的其他命名空间中。

运行 Istio 控制平面的本地集群不需要存储和标记它的 secret。
本地节点始终知道其 Kubernetes 凭据，但本地节点不知道远程节点的凭据。

为每个远程集群创建一个 secret 并适当标记它：

{{< text bash >}}
$ kubectl create secret generic ${CLUSTER_NAME} --from-file ${KUBECFG_FILE} -n ${NAMESPACE}
$ kubectl label secret ${CLUSTER_NAME} istio/multiCluster=true -n ${NAMESPACE}
{{< /text >}}

{{< warning_icon >}}
Kubernetes secret 数据秘钥必须遵守 `DNS-1123 subdomain`
[格式](https://tools.ietf.org/html/rfc1123#page-13), 所以文件名不能有像下划线这样的符号。要解决任何问题，您只需更改文件名即可符合格式。

## 删除

> 删除方法必须和安装方法相匹配（`Helm + kubectl` 或者 `Helm + Tiller`）

### 使用 `kubectl` 删除 istio-remote

{{< text bash >}}
$ kubectl delete -f $HOME/istio-remote.yaml
{{< /text >}}

### 或者使用 Helm + Tiller 删除 istio-remote

{{< text bash >}}
$ helm delete --purge istio-remote
{{< /text >}}

## 远程集群手动 sidecar 注入示例

以下示例显示如何使用 `helm template` 命令为禁用自动 sidecar 注入的远程集群生成清单。
此外，该示例还指示如何使用远程集群的 configmaps 和 `istioctl kube-inject` 命令为远程集群生成任何应用程序清单。

将对远程集群执行以下过程。

> 端点 IP 环境变量需要像[上一节](#从-istio-控制平面设置-istio-远程组件所需的-pod-ip-环境变量)中那样设置

1.  在远程控制器上使用 `helm template` 命令指定 Istio 控制平面服务端点：

    {{< text bash >}}
    $ helm template install/kubernetes/helm/istio-remote --namespace istio-system --name istio-remote --set global.remotePilotAddress=${PILOT_POD_IP} --set global.remotePolicyAddress=${POLICY_POD_IP} --set global.remoteTelemetryAddress=${TELEMETRY_POD_IP} --set global.proxy.envoyStatsd.enabled=true --set global.proxy.envoyStatsd.host=${STATSD_POD_IP} --set global.remoteZipkinAddress=${ZIPKIN_POD_IP} --set sidecarInjectorWebhook.enabled=false > $HOME/istio-remote_noautoinj.yaml
    {{< /text >}}

1.  为远程 Istio 创建命名空间。

    {{< text bash >}}
    $ kubectl create ns istio-system
    {{< /text >}}

1.  实例化远程集群与 Istio 控制平面的连接：

    {{< text bash >}}
    $ kubectl apply -f $HOME/istio-remote_noautoinj.yaml
    {{< /text >}}

1.  [为远程集群生成 kubeconfig](#为远程集群生成-kubeconfigs)

1.  [实例化每个远程集群的凭据](#实例化每个远程集群的凭据)

### 手动将 sidecar 注入应用程序清单

以下是用于将 sidecar 注入应用程序清单的 `istioctl` 命令示例。 这些命令应该在 shell 中运行，并为远程集群设置 `kubeconfig` 上下文。

{{< text bash >}}
$ ORIGINAL_SVC_MANIFEST=mysvc-v1.yaml
$ istioctl kube-inject --injectConfigMapName istio-sidecar-injector --meshConfigMapName istio -f ${ORIGINAL_SVC_MANIFEST} | kubectl apply -f -
{{< /text >}}

## 从不同集群访问服务

Kubernetes 在集群基础上解析DNS。 由于 DNS 解析与集群相关联，因此无论服务端点的位置如何，都必须在运行客户端的每个集群中定义服务对象。
为确保这种情况，请使用 `kubectl` 将服务对象复制到每个集群，复制可确保 Kubernetes 可以解析任何集群中的服务名称。由于服务对象是在命名空间中定义的，因此必须定义命名空间（如果该命名空间不存在），并将其包含在所有集群的服务定义中。

## 部署注意事项

上述过程提供了部署多集群环境的简单分步指南，生产环境可能需要其他步骤或更复杂的部署选项。该过程收集 Istio 服务的端点 IP 并使用它们来调用 Helm，这将在远程集群上创建 Istio 服务。
作为在远程集群中创建这些服务和端点的一部分，Kubernetes 会将 DNS 条目添加到 kube-dns 中。这允许远程集群中的 kube-dns 解析这些远程集群中所有 envoy sidecar 的 Istio 服务名称。
由于 Kubernetes pod 没有固定的 IP，因此重新启动控制平面集群中的任何 Istio 服务 pod 将导致其端点发生更改。因此，从远程集群到该端点的任何连接都将被破坏，这在 [Istio issue #4822](https://github.com/istio/istio/issues/4822) 中有记录。

有许多方法可以避免或解决这种情况，本节提供了这些选项的高级概述。

* 更新 DNS 条目
* 使用负载均衡器服务类型
* 通过网关发布 Istio 服务

### 更新 DNS 条目

在任何故障或 pod 重启时，可以使用 Istio 服务正确的映射端点，更新远程集群上的 kube-dns。
有很多方法可以做到这一点，最明显的是在控制平面集群上的 Istio 服务重新启动后重新运行远程集群中的 Helm 安装。

### 使用负载均衡器服务类型

在 Kubernetes 中，您可以声明服务类型为 [`LoadBalancer`](https://kubernetes.io/docs/concepts/services-networking/service/#publishing-services-service-types)。
pod 重启问题的一个简单解决方案是为 Istio 服务使用负载平衡器。
然后，您可以使用负载均衡器 IP 作为 Istio 服务的端点 IP 来配置远程集群。
您可能需要这些 Istio 服务的平衡器 IP：`istio-pilot，istio-telemetry，istio-policy，istio-statsd-prom-bridge，zipkin`

目前，Istio 安装不提供为 Istio 服务指定服务类型的选项。 但您可以自己修改 Istio Helm chart 或 Istio 清单。

### 通过网关发布 Istio 服务

该操作使用了 Istio Ingress 网关功能，远程集群拥有 `istio-pilot，istio-telemetry，istio-policy，istio-statsd-prom-bridge，zipkin` 服务，他们指向了 Istio ingress 的负载均衡 IP。所有服务都可以指向相同的 IP，向 ingress 网关提供目的地规则以在主集群中到达适当的 Istio 服务。

在此选项中有 2 个子选项。 一种是重新使用默认 Istio ingress 网关提供的清单或 Helm chart，另一种选择是专门为多集群创建另一个 Istio ingress 网关。

## 安全

Istio 支持在控制平面组件之间以及在 sidecar 注入的应用程序 pod 之间部署双向 TLS。

### 控制平面安全

启用控制平面安全的步骤如下：

1.  部署了 Istio 控制平面的集群
    1.  启用控制平面安全
    1.  禁用自制 `citadel` 证书
    1.  在 Istio 控制平面中带有 [CA 证书](/zh/docs/tasks/security/plugin-ca-cert/#插入现有密钥和证书)并名为 `cacerts` 的 secret

1.  部署了 Istio 的远程集群
    1.  启用控制平面安全
    1.  禁用自制 `citadel` 证书
    1.  在 Istio 控制平面中带有 [CA 证书](/zh/docs/tasks/security/plugin-ca-cert/#插入现有密钥和证书)并名为 `cacerts` 的 secret
        1.  远程集群的 CA 证书需要由与主集群相同的 CA 或根 CA 签名。
    1.  Istio 试验服务主机名可通过 DNS 解析
        1.  此项操作是必须的，因为 Istio 使用 `istio-pilot.<namespace>` 名称格式配置 sidecar 以验证证书使用者名称。
    1.  设置控制平面的 IP 或可解析的主机名

### 应用程序 pod 之间的双向 TLS

为所有应用程序 pod 启用双向 TLS 的步骤如下：

1.  部署了 Istio 控制平面的集群
    1.  开启全局双向 TLS
    1.  禁用自制 `citadel` 证书
    1.  在 Istio 控制平面中带有 [CA 证书](/zh/docs/tasks/security/plugin-ca-cert/#插入现有密钥和证书)并名为 `cacerts` 的 secret

1.  部署了 Istio 的远程集群
    1.  开启全局双向 TLS
    1.  禁用自制 `citadel` 证书
    1.  在 Istio 控制平面中带有 [CA 证书](/zh/docs/tasks/security/plugin-ca-cert/#插入现有密钥和证书)并名为 `cacerts` 的 secret
        1.  远程集群的 CA 证书需要由与主集群相同的CA或根CA签名。

> 对于控制平面安全和应用程序 pod 安全步骤而言，CA 证书步骤是相同的。

### 部署示例

以下是安装 Istio 的示例过程，同时启用了控制平面双向 TLS 和应用程序 pod 双向 TLS。该示例设置了一个远程集群，该集群具有无选择器服务和 `istio-pilot` 端点，允许远程 sidecar 通过其本地 Kubernetes DNS 解析`istio-pilot.istio-system` 主机名。

1.  *主集群*  部署 Istio 控制平面集群

    1.  从 `istio-system` 命名空间中的 Istio 示例证书创建 `cacerts` secret：

        {{< text bash >}}
        $ kubectl create ns istio-system
        $ kubectl create secret generic cacerts -n istio-system --from-file=samples/certs/ca-cert.pem --from-file=samples/certs/ca-key.pem --from-file=samples/certs/root-cert.pem --from-file=samples/certs/cert-chain.pem
        {{< /text >}}

    1.  部署 Istio 控制平面，启用控制平面和应用程序 pod 安全

        {{< text bash >}}
        $ helm template --namespace=istio-system \
          --values install/kubernetes/helm/istio/values.yaml \
          --set global.mtls.enabled=true \
          --set security.selfSigned=false \
          --set global.controlPlaneSecurityEnabled=true \
          install/kubernetes/helm/istio > ${HOME}/istio-auth.yaml
        $ kubectl apply -f ${HOME}/istio-auth.yaml
        {{< /text >}}

1.  *远程集群*  部署远程集群 istio 组件

    1.  从 `istio-system` 命名空间中的 Istio 示例证书创建 `cacerts` secret：

        {{< text bash >}}
        $ kubectl create ns istio-system
        $ kubectl create secret generic cacerts -n istio-system --from-file=samples/certs/ca-cert.pem --from-file=samples/certs/ca-key.pem --from-file=samples/certs/root-cert.pem --from-file=samples/certs/cert-chain.pem
        {{< /text >}}

    1.  设置端点 IP 环境变量，参考[设置环境变量](#从-istio-控制平面设置-istio-远程组件所需的-pod-ip-环境变量)部分

    1.  在启用控制平面和应用程序 pod 安全的情况下部署远程集群组件。 此外，还可以创建 `istio-pilot` 无选择器服务和端点，以在远程集群中获取 DNS 条目。

        {{< text bash >}}
        $ helm template install/kubernetes/helm/istio-remote \
          --name istio-remote \
          --namespace=istio-system \
          --set global.mtls.enabled=true \
          --set security.selfSigned=false \
          --set global.controlPlaneSecurityEnabled=true \
          --set global.remotePilotCreateSvcEndpoint=true \
          --set global.remotePilotAddress=${PILOT_POD_IP} \
          --set global.remotePolicyAddress=${POLICY_POD_IP} \
          --set global.remoteTelemetryAddress=${TELEMETRY_POD_IP} \
          --set global.proxy.envoyStatsd.enabled=true \
          --set global.proxy.envoyStatsd.host=${STATSD_POD_IP} > ${HOME}/istio-remote-auth.yaml
        $ kubectl apply -f ${HOME}/istio-remote-auth.yaml
        {{< /text >}}

    1.  [为远程集群生成 kubeconfig](#为远程集群生成-kubeconfigs)

1.  *主集群*  [实例化每个远程集群的凭据](#实例化每个远程集群的凭据)

此时，在应用程序 sidecar 和控制平面组件之间以及其他应用程序 sidecar 之间，两个集群中的所有 Istio 组件都配置了双向 TLS。
