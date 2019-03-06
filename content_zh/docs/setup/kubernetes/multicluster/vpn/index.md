---
title: VPN 连接
description: 通过直连远程 pods 实现多 Kubernetes 集群安装 Istio 网格。
weight: 5
keywords: [kubernetes,multicluster,federation,vpn]
aliases:
    - /zh/docs/setup/kubernetes/multicluster
---

这是一个关于当每个集群中的 pod 可以直连访问其他集群中的 pod 时，可以跨多个集群安装 Istio 网格的说明。

在此配置中，运行远程配置的多个 Kubernetes 控制平面将连接到**单个** Istio 控制平面。一旦一个或多个远程 Kubernetes 集群连接到 Istio 控制平面，Envoy 就可以与单个控制平面通信并形成跨多个集群的服务网格。

{{< image width="80%"
    link="/docs/setup/kubernetes/install/multicluster/vpn/multicluster-with-vpn.svg"
    caption="通过 VPN 直连远程 pod 的多 Kubernetes 集群 Istio 网格"
    >}}

## 先决条件

* 两个以上运行 **Kubernetes 1.9 或更高版本**的集群。

*  能够在其中**一个**集群上部署 [Istio 控制平面](/zh/docs/setup/kubernetes/install/kubernetes/)的能力。

* RFC1918 网络、VPN或是满足以下可选条件的更高级的网络技术：

    * 单集群 Pod 和服务的 CIDR 范围在多集群环境中必须唯一，最好不要重叠。

    * 每个集群中的所有 Pod CIDR 必须的相互可达的。

    * 所有 Kubernetes 控制平面 API 服务必须是相互可达的。

* Helm **2.7.2 或更高版本**。 也可选择使用 Tiller 。

本指南将介绍如何使用 Istio 仓库中提供的清单和 Helm charts 安装一个多集群的 Istio 拓扑。

## 部署本地控制平面

在**一个** Kubernetes 集群中安装 [Istio 控制平面](/zh/docs/setup/kubernetes/install/kubernetes/#安装步骤)。

## 安装 Istio 远程组件

你必须将 `istio-remote` 组件部署到每一个远程 Kubernetes
集群中。 你可以通过以下两种方式之一安装组件：

{{< tabset cookie-name="install-istio-remote" >}}

{{% tab name="Helm+kubectl" cookie-value="Helm+kubectl" %}}
[使用 Helm 和 `kubectl` 安装并管理远程集群](#helm-k)
{{% /tab %}}
{{% tab name="Helm+Tiller" cookie-value="Helm+Tiller" %}}
[使用 Helm 和 Tiller 安装并管理远程集群](#tiller)
{{% /tab %}}
{{< /tabset >}}

### 设置环境变量 {#environment}

等待 Istio 控制平面完成初始化，然后再执行本节中的步骤。

你必须在 Istio 控制平面上运行这些操作以捕获 Istio 控制平面服务端点，如：Pilot、Policy 端点。

如果你在每个远程组件上使用 Helm 和 Tiller，你必须将环境变量复制到每个节点，然后再使用 Helm 将远程集群连接到 Istio 控制平面。

通过以下命令设置环境变量：

{{< text bash >}}
$ export PILOT_POD_IP=$(kubectl -n istio-system get pod -l istio=pilot -o jsonpath='{.items[0].status.podIP}')
$ export POLICY_POD_IP=$(kubectl -n istio-system get pod -l istio-mixer-type=policy -o jsonpath='{.items[0].status.podIP}')
$ export TELEMETRY_POD_IP=$(kubectl -n istio-system get pod -l istio-mixer-type=telemetry -o jsonpath='{.items[0].status.podIP}')
$ export ZIPKIN_POD_IP=$(kubectl -n istio-system get pod -l app=jaeger -o jsonpath='{range .items[*]}{.status.podIP}{end}')
{{< /text >}}

接着，你必须将远程集群与本地集群连接。

继续你先前的选项：

* 通过 [`kubectl` + Helm](#helm-k)

* 通过 [Helm + Tiller](#tiller)

通常，需要启动远程 sidecar 注入。如果需要执行手动 sidecar 注入，请参阅[手动 sidecar 注入示例](#manual-sidecar)。

### 安装并管理远程集群

{{< tabset cookie-name="install-istio-remote" >}}

{{% tab name="Helm+kubectl" cookie-value="Helm+kubectl" %}}

#### 通过 Helm 和 `kubectl` {#helm-k}

1. 通过以下 `helm template` 命令在远程集群中指定 Istio 控制平面服务端点：

{{< text bash >}}
$ helm template install/kubernetes/helm/istio-remote --namespace istio-system \
   --name istio-remote \
   --set global.remotePilotAddress=${PILOT_POD_IP} \
   --set global.remotePolicyAddress=${POLICY_POD_IP} \
   --set global.remoteTelemetryAddress=${TELEMETRY_POD_IP} \
   --set global.remoteZipkinAddress=${ZIPKIN_POD_IP} > $HOME/istio-remote.yaml
{{< /text >}}

1. 通过以下命令给远程 Istio 创建一个 `istio-system` 命名空间：

    {{< text bash >}}
    $ kubectl create ns istio-system
    {{< /text >}}

    {{< tip >}}
    所有集群必须有相同的 Istio 组件命名空间。只要命名空间对有所有集群中的 Istio 组件都相同，就可以覆盖住集群上的 `istio-system` 名称。
    {{< /tip >}}

1. 通过以下命令实例化远程集群与 Istio 控制平面的连接：

    {{< text bash >}}
    $ kubectl apply -f $HOME/istio-remote.yaml
    {{< /text >}}

1. 使用以下示例命令标记 `default` 命名空间。使用相似命令标记所有需要自动 sidecar 注入的远程集群命名空间。

    {{< text bash >}}
    $ kubectl label namespace default istio-injection=enabled
    {{< /text >}}

   对需要设置 sidecar 注入的所有 Kubernetes 命名空间需要重复此操作。

{{% /tab %}}

{{% tab name="Helm+Tiller" cookie-value="Helm+Tiller" %}}

#### 通过 Helm 和 Tiller {#tiller}

1. 如果你尚未给 Helm 设置一个 service account ，请使用以下命令安装一个：

    {{< text bash >}}
    $ kubectl apply -f install/kubernetes/helm/helm-service-account.yaml
    {{< /text >}}

1. 通过以下命令初始化 Helm：

    {{< text bash >}}
    $ helm init --service-account tiller
    {{< /text >}}

1. 通过以下命令来为  `istio-remote`  安装 Helm chart：

    {{< text bash >}}
    $ helm install install/kubernetes/helm/istio-remote --name istio-remote  --namespace istio-system --set global.remotePilotAddress=${PILOT_POD_IP} --set global.remotePolicyAddress=${POLICY_POD_IP} --set global.remoteTelemetryAddress=${TELEMETRY_POD_IP} --set global.remoteZipkinAddress=${ZIPKIN_POD_IP}
    {{< /text >}}

{{% /tab %}}

{{< /tabset >}}

### Helm chart 配置参数

你必须配置远程集群的 sidecar 与 Istio 控制平面的交互，包括  `istio-remote` 的 Helm chart：
`pilot`, `policy`, `telemetry`, `statsd` 和 追踪服务。

该 chart 默认启动自动 sidecar 注入。你可以通过 chart 变量来禁用该功能。

下表显示了已通过的 `istio-remote` Helm chart 配置变量：

| Helm 变量 | 可选值 | 默认 | 用途 |
| --- | --- | --- | --- |
| `global.remotePilotAddress` | 一个合法的 IP 地址或主机名 | None | 指定 Istio 控制平面的 pilot Pod IP 地址或远程集群 DNS 可解析的主机名。 |
| `global.remotePolicyAddress` | 一个合法的 IP 地址或主机名 | None | 指定 Istio 控制平面的 policy Pod IP 地址或远程集群 DNS 可解析的主机名。 |
| `global.remoteTelemetryAddress` | 一个合法的 IP 地址或主机名 | None | 指定 Istio 控制平面的 telemetry Pod IP 地址或远程集群 DNS 可解析的主机名。 |
| `global.remoteZipkinAddress` | 一个合法的 IP 地址或主机名 | None | 指定 Istio 控制平面追踪应用的 Pod IP 地址或远程集群 DNS 可解析的主机名。例如：`zipkin` 或 `jaeger`。 |
| `sidecarInjectorWebhook.enabled` | true, false | true | 指定是否在远程集群中启用了自动 sidecar 注入 |
| `global.remotePilotCreateSvcEndpoint` | true, false | false | 如果设置该项，一个无选择器服务和端点将以`remotePilotAddress` IP的形式被创建给 `istio-pilot.<namespace>`是远程集群 DNS 可解析的。 |

## 为远程集群生成配置文件 {#kubeconfig}

Istio 控制平面需要服务所有集群中的网格来发现服务、端点和 pod 属性。

以下步骤描述了如何生成一个 `kubeconfig` 配置文件给 Istio 控制面板以使用远程集群。

`istio-remote` Helm chart 在远程集群中创建了一个叫 `istio-multi` 的 Kubernetes service account 用于最小化 RBAC 访问请求。
此过程通过使用先前所述的 `istio-multi` service account 凭证生成了一个远程集群的 `kubeconfig` 配置文件。

每个远程集群上执行此过程以将集群添加到服务网格。此过程需要 `cluster-admin` 用户访问远程集群的权限。

1. 通过以下命令为 `istio-multi` service account 设置所需环境变量构建 `kubeconfig` 文件：

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

    {{< tip >}}
    许多系统对 `base64 --decode` 都有 `openssl enc -d -base64 -A` 这样的替代方案。
    {{< /tip >}}

1. 通过以下命令为 `istio-multi` service account 在工作目录创建一个 `kubeconfig`  文件：

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

1. _(可选)_  使用环境变量创建文件以创建远程集群的密钥：

    {{< text bash >}}
    $ cat <<EOF > remote_cluster_env_vars
    export CLUSTER_NAME=${CLUSTER_NAME}
    export KUBECFG_FILE=${KUBECFG_FILE}
    export NAMESPACE=${NAMESPACE}
    EOF
    {{< /text >}}

此时，你在当前目录创建了远程集群的 `kubeconfig` 文件。

文件名为 `kubeconfig` 的文件与原始集群名称相同。

## 实例化凭据 {#credentials}

在运行了 Istio 控制平面的机器上执行以下过程。
该过程使用的 `WORK_DIR`、`CLUSTER_NAME` 和 `NAMESPACE` 环境变量都存在于[上一节](#kubeconfig)为远程集群创建的配置文件中。
如果你为远程集群的 secret 创建了环境变量文件，请通过以下命令获取该文件：

    {{< text bash >}}
    $ source remote_cluster_env_vars
    {{< /text >}}

你可以在不同的命名空间中安装 Istio。该过程需要使用 `istio-system` 命名空间。

{{< warning >}}
不要存储和标记运行了 Istio 控制平面的本地集群的 secret。Istio 始终了解本地集群的 Kubernetes 凭据。
{{< /warning >}}

为每个集群创建一个正确的 secret 和 标记：

{{< text bash >}}
$ kubectl create secret generic ${CLUSTER_NAME} --from-file ${KUBECFG_FILE} -n ${NAMESPACE}
$ kubectl label secret ${CLUSTER_NAME} istio/multiCluster=true -n ${NAMESPACE}
{{< /text >}}

{{< warning >}}
Kubernetes secret 数据秘钥必须符合 `DNS-1123 subdomain` [格式](https://tools.ietf.org/html/rfc1123#page-13)。例如，文件名不能有下划线。只需更改文件名以符合格式，即可解决文件名的任何问题。
{{< /warning >}}

## 卸载远程集群

你必须使用与他们安装相同的方法卸载远程集群。

通过 `kubectl + Helm` 或 `Tiller + Helm` 合理卸载他们。

{{< tabset cookie-name="uninstall-istio-remote" >}}

{{% tab name="kubectl" cookie-value="kubectl" %}}

### 通过 `kubectl`

要卸载集群，你必须移除 `istio-remote.yaml`文件进行的配置。
通过以下命令卸载：

{{< text bash >}}
$ kubectl delete -f $HOME/istio-remote.yaml
{{< /text >}}

{{% /tab %}}

{{% tab name="Tiller" cookie-value="Tiller" %}}

### 通过 Tiller

要卸载集群，你必须移除 `istio-remote.yaml` 文件进行的配置。
通过以下命令卸载：

{{< text bash >}}
$ helm delete --purge istio-remote
{{< /text >}}

{{% /tab %}}

{{< /tabset >}}

## 手动 sidecar 注入示例 {#manual-sidecar}

以下示例将展示如何使用 `helm template` 命令生成清单以禁用集群的自动 sidecar 注入。此外，示例将展示如何使用远程集群的  `configmaps` ，通过 `istioctl kube-inject`  命令为远程集群生成任何应用的清单。

对远程集群执行以下过程：

在开始之前，请按照[设置环境变量部分](#environment)设置端点 IP 环境变量

1. 在远程集群使用 `helm template` 命令指定 Istio
   控制平面的 service 端点：

    {{< text bash >}}
    $ helm template install/kubernetes/helm/istio-remote --namespace istio-system --name istio-remote --set global.remotePilotAddress=${PILOT_POD_IP} --set global.remotePolicyAddress=${POLICY_POD_IP} --set global.remoteTelemetryAddress=${TELEMETRY_POD_IP} --set global.remoteZipkinAddress=${ZIPKIN_POD_IP} --set sidecarInjectorWebhook.enabled=false > $HOME/istio-remote_noautoinj.yaml
    {{< /text >}}

1. 为远程 Istio 创建 `istio-system` 命名空间：

    {{< text bash >}}
    $ kubectl create ns istio-system
    {{< /text >}}

1. 实例化远程集群与 Istio 控制平面的连接：

    {{< text bash >}}
    $ kubectl apply -f $HOME/istio-remote_noautoinj.yaml
    {{< /text >}}

1. 为每个远程集群[生成](#kubeconfig) `kubeconfig` 配置文件。

1. 为每个集群[实例化凭证](#credentials)。

### 手动将 sidecars 注入到应用清单中

以下示例通过 `istioctl` 命令将 sidecar 注入到应用清单。

 在终端中运行以下命令，通过 `kubeconfig` 为远程集群设置上下文。

{{< text bash >}}
$ ORIGINAL_SVC_MANIFEST=mysvc-v1.yaml
$ istioctl kube-inject --injectConfigMapName istio-sidecar-injector --meshConfigMapName istio -f ${ORIGINAL_SVC_MANIFEST} | kubectl apply -f -
{{< /text >}}

## 访问来自不同集群的服务

Kubernetes 在集群的基础上解析 DNS。由于 DNS解析与集群相关联，因此无论服务端点的位置如何，你都必须在每个运行客户端的集群中定义服务对象。

为了确保这种情况，在每个集群中使用 `kubectl` 复制服务对象。副本确保了 Kubernetes 可以解析任何集群中的服务名称。由于服务对象被定义在命名空间中，你必须自己定义命名空间（如果命名空间不存在）并且将其囊括在所有集群的服务定义中。

## 部署注意事项

前面的过程提供了部署多集群环境的简单分步指南。生产环境可能需要其他步骤或更复杂的部署选项。该过程收集 Istio 服务端点的 IP 地址并用他们来调用 Helm。
这个过程在远程集群创建了 Istio 服务。作为在远程集群创建这些服务和端点的一部分，Kubernetes 将 DNS 条目加入到了 `kube-dns` 配置对象中。
这将允许在远程集群中 `kube-dns` 配置对象将解析 Istio 服务名给所有 Envoy sidecar。
由于 Kubernetes pods 没有固定的 IP 地址，在控制平面中重启任何 Istio 服务 pod 都会导致它端点的改变。
因此，任何从远程集群到任何端点的连接都会中断。[Istio issue #4822](https://github.com/istio/istio/issues/4822)详细记录了该问题。

要避免或解决此问题，有多个选项可供选择。本节提供了以下选项的高级概述：

* 更新 DNS 条目
* 切换负载均衡服务类型
* 通过网关暴露 Istio 服务

### 更新 DNS 条目

在发生任何故障或 pod 重启时，在远程集群重启 `kube-dns` 可以为 Istio 服务正确更新端点的映射关系。
有很多方法可以做到这点。常规做法是在远程节点重新运行 Helm 安装，之后 Istio 服务便会在控制平面上重启。

### 切换负载均衡类型

在 Kubernetes 中，你可以以 `LoadBalancer` 类型声明服务。
更多内容详见 Kubernetes 的[服务类型](https://kubernetes.io/docs/concepts/services-networking/service/#publishing-services-service-types)。

pod 重启的一个简单的解决方案是给 Istio 服务使用负载均衡器。

接着，你可以使用负载均衡器的 IP 地址作为 Istio 服务端点的 IP 地址以配置远程集群。你或许需要这些 Istio 服务的负载均衡器：

* `istio-pilot`
* `istio-telemetry`
* `istio-policy`
* `zipkin`

目前，Istio 安装不提供为 Istio 服务指定服务类型的选项。 您可以在 Istio Helm chart 或 Istio 清单中手动指定服务类型。

### 通过网关暴露 Istio 服务

此方法使用了 Istio ingress 网关的功能。远程集群有 `istio-pilot`、`istio-telemetry`、 `istio-policy`、
和 `zipkin` 服务，它们指向了 Istio ingress 网关的负载均衡 IP 地址。然后，所有的服务均指向相同的 IP 地址。你必须创建目标规则以在主集群的 ingress 网关中获得正确的 Istio 服务。

以下两种方案可供选择：

* 重新使用清单或 Helm charts 提供安装的默认 Istio ingress 网关。您只需添加正确的目标规则。

* 专门为集群创建另一个 Istio ingress 网关。

## 安装

Istio 支持在控制平面组件之间以及在 sidecar 注入的应用 pod 之间部署双向 TLS。

### 控制平面安全

要启用控制平面安全性，请遵循以下常规步骤：

1. 部署 Istio 控制平面集群：

    * 控制平面安全已启用。

    * 该 `citadel` 证书自签署禁用。

    * `cacerts` 的 secret 通过[证书颁发机构 (CA) 证书](/zh/docs/tasks/security/plugin-ca-cert/#插入现有密钥和证书)下发在Istio 控制平面命名空间中。

1. 部署 Istio 远程集群：

    * 控制平面安全已启用。

    * 该 `citadel` 证书自签署禁用。

    * `cacerts` 的 secret 通过[(CA) 证书](/zh/docs/tasks/security/plugin-ca-cert/#插入现有密钥和证书)下发在Istio 控制平面命名空间中。

     主集群的证书颁发机构（CA）或根 CA 也必须为远程群集签署 CA 证书。

    * Istio pilot 服务主机名必须通过DNS解析。DNS解析是必需的，因为Istio 需要配置 sidecar 以使用 `istio-pilot.<namespace>` 主题名称格式验证证书主题名称。

    * 设置控制平面IP或可解析的主机名。

### 应用 Pod 之间的双向 TLS

为了确保应用 Pod 之间的双向 TLS，请按照以下常规步骤操作：

1.  部署Istio控制平面集群：

    * 全局启用了相互TLS。

    * Citadel 证书自签名禁用。

    * `cacerts` 的 secret 通过[(CA) 证书](/zh/docs/tasks/security/plugin-ca-cert/#插入现有密钥和证书)下发在Istio 控制平面命名空间中。

1.  部署Istio远程集群：

    * 全局启用了相互TLS。

    * Citadel 证书自签名禁用。

    * `cacerts` 的 secret 通过[(CA) 证书](/zh/docs/tasks/security/plugin-ca-cert/#插入现有密钥和证书)下发在Istio 控制平面命名空间中。
      主集群的 CA 或根 CA 也必须为远程集群签署CA证书。

{{< tip >}}
对于控制平面安全性和应用 pod 安全性步骤，CA 证书步骤是相同的。
{{< /tip >}}

### 部署示例

此示例为安装 Istio 的过程，同时启用控制平面双向 TLS 和 应用 pod 双向 TLS。该过程
使用无选择器服务和端点设置远程集群。Istio Pilot 使用服务和端点允许远程 sidecar 通过 Istio 的本地 Kubernetes DNS 解析主机名。

#### 主集群: 部署控制平面集群

1. 通过在 `istio-system` 命名空间中的 Istio 证书示例创建 `cacerts` secret：

    {{< text bash >}}
    $ kubectl create ns istio-system
    $ kubectl create secret generic cacerts -n istio-system --from-file=samples/certs/ca-cert.pem --from-file=samples/certs/ca-key.pem --from-file=samples/certs/root-cert.pem --from-file=samples/certs/cert-chain.pem
    {{< /text >}}

1. 部署 Istio 控制平面，并为控制平面和应用 pod 启用安全：

    {{< text bash >}}
    $ helm template --namespace=istio-system \
      --values install/kubernetes/helm/istio/values.yaml \
      --set global.mtls.enabled=true \
      --set security.selfSigned=false \
      --set global.controlPlaneSecurityEnabled=true \
      install/kubernetes/helm/istio > ${HOME}/istio-auth.yaml
    $ kubectl apply -f ${HOME}/istio-auth.yaml
    {{< /text >}}

#### 远程群集：部署 Istio 组件

1. 通过在 `istio-system`  命名空间中的Istio 证书示例创建 `cacerts` secret：

    {{< text bash >}}
    $ kubectl create ns istio-system
    $ kubectl create secret generic cacerts -n istio-system --from-file=samples/certs/ca-cert.pem --from-file=samples/certs/ca-key.pem --from-file=samples/certs/root-cert.pem --from-file=samples/certs/cert-chain.pem
    {{< /text >}}

1. 按照[设置环境变量](#environment)的说明为 pod 的 IP 地址设置环境变量。

1. 通过以下命令为部署远程集群的组件并为控制平面和应用 pod 启用安全，同时启用创建 Istio Pilot 无选择器服务和端点以在远程集群中获取 DNS 条目。

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
      --set global.remoteTelemetryAddress=${TELEMETRY_POD_IP} > ${HOME}/istio-remote-auth.yaml
    $ kubectl apply -f ${HOME}/istio-remote-auth.yaml
    {{< /text >}}

1. 要为远程集群生成 `kubeconfig` 配置文件，请按照[Kubernetes 配置部分](#kubeconfig)的步骤操作。

### 主集群：实例化凭据

你必须为每个远程群集实例化凭据。请按照[实例化凭据工程](#credentials)完成部署。

**恭喜!**

你已经在两个集群中配置了所有 Istio 组件以及在应用 sidecar、控制平面组件和其他应用 sidecar 之间开启了双向TLS。
