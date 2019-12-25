---
title: 共享控制平面（单一网络）
description: 安装一个跨多个 Kubernetes 集群的 Istio 网格，多集群共享控制平面，并且集群间通过 VPN 互连。
weight: 5
keywords: [kubernetes,multicluster,federation,vpn]
aliases:
    - /zh/docs/setup/kubernetes/multicluster-install/vpn/
    - /zh/docs/setup/kubernetes/install/multicluster/vpn/
    - /zh/docs/setup/kubernetes/install/multicluster/shared-vpn/
---

按照该指南安装一个 Istio [多集群服务网格](/zh/docs/ops/deployment/deployment-models/#multiple-clusters)以让每个 Kubernetes 集群的服务和应用能够将他们的内部 Kubernetes 网络暴露至其它集群。

在这个配置中，多个 Kubernetes 集群运行一份可以连接到一个共享 Istio [控制平面](/zh/docs/ops/deployment/deployment-models/#control-plane-models)的远程配置。
一旦一个或多个远程 Kubernetes 集群连接到该 Istio 控制平面，Envoy 就会形成一个跨多集群的网格网络。

{{< image width="80%" link="./multicluster-with-vpn.svg" caption="跨多 Kubernetes 集群的 Istio 网格可通过 VPN 直接访问远程 Pod" >}}

## 前提条件{#prerequisites}

* 两个或更多运行受支持的 Kubernetes 版本（{{< supported_kubernetes_versions >}}）的集群。

* 能够在多集群中的**一个**上[部署 Istio 控制平面](/zh/docs/setup/install/istioctl/)。

* 满足下列要求的 RFC1918 网络、VPN、或其它更高级的网络技术：

    * 各集群的 Pod CIDR 范围和服务 CIDR 范围在多群集环境中必须唯一，并且不能重叠。

    * 每个集群中的所有 pod CIDRs 必须互相可路由。

    * 所有 Kubernetes 控制平面 API 服务必须互相可路由。

本指南介绍如何使用 Istio 提供的远程配置文件安装多群集 Istio 拓扑。

## 部署本地控制平面{#deploy-the-local-control-plane}

在 Kubernetes 集群**之一**上[安装 Istio 控制平面](/zh/docs/setup/install/istioctl/)。

### 设置环境变量{#environment-var}

在执行本节中的步骤之前，请等待 Istio 控制平面完成初始化。

您必须在 Istio 控制平面集群上执行这些操作，以获取 Istio 控制平面服务端点，例如，Pilot 和 Policy Pod IP 端点。

运行以下命令设置环境变量：

{{< text bash >}}
$ export PILOT_POD_IP=$(kubectl -n istio-system get pod -l istio=pilot -o jsonpath='{.items[0].status.podIP}')
$ export POLICY_POD_IP=$(kubectl -n istio-system get pod -l istio-mixer-type=policy -o jsonpath='{.items[0].status.podIP}')
$ export TELEMETRY_POD_IP=$(kubectl -n istio-system get pod -l istio-mixer-type=telemetry -o jsonpath='{.items[0].status.podIP}')
{{< /text >}}

通常，在远程集群上自动 sidecar 注入已经启用。
要执行手动 sidecar 注入，请参考[手动 sidecar 示例](#manual-sidecar)。

## 安装 Istio 远程组件{#install-the-Istio-remote}

您必须在每个远程 Kubernetes 集群上都部署 `istio-remote` 组件。
您可以用下面两种方式之一来安装该组件：

1. 在远程集群上使用下列命令来安装 Istio 控制平面服务端点：

    {{< text bash >}}
    $ istioctl manifest apply \
    --set profile=remote \
    --set values.global.controlPlaneSecurityEnabled=false \
    --set values.global.createRemoteSvcEndpoints=true \
    --set values.global.remotePilotCreateSvcEndpoint=true \
    --set values.global.remotePilotAddress=${PILOT_POD_IP} \
    --set values.global.remotePolicyAddress=${POLICY_POD_IP} \
    --set values.global.remoteTelemetryAddress=${TELEMETRY_POD_IP} \
    --set gateways.enabled=false \
    --set autoInjection.enabled=true
    {{< /text >}}

    {{< tip >}}
    所有集群的 Istio 组件都必须具有相同的命名空间。
    只要所有集群中所有 Istio 组件的命名空间都相同，就可以在主集群上覆盖 `istio-system` 名称。
    {{< /tip >}}

1. 下列命令示例标记了 `default` 命名空间。使用类似的命令标记所有需要自动进行 sidecar 注入的远程集群的命名空间。

    {{< text bash >}}
    $ kubectl label namespace default istio-injection=enabled
    {{< /text >}}

    为所有需要设置自动 sidecar 注入的 Kubernetes 命名空间重复以上命令。

### 安装配置参数{#installation-configuration-parameters}

你必须配置远程集群的 sidecar 与 Istio 控制平面交互，包括在 `istio-remote` 配置文件中的以下端点：`pilot`、`policy`、`telemetry`和跟踪服务。
该配置文件默认在远程集群中启用自动 sidecar 注入。
您可以通过单独的设置禁用自动 sidecar 注入。

下列表格展示了 `istioctl` 针对远程集群的配置值：

| 安装设置 | 可选值 | 默认 | 值作用 |
| --- | --- | --- | --- |
| `values.global.remotePilotAddress` | 有效的 IP 地址或主机名 | None | 指定 Istio 控制平面的 pilot Pod IP 地址或远程集群 DNS 可解析的主机名 |
| `values.global.remotePolicyAddress` | 有效的 IP 地址或主机名 | None | 指定 Istio 控制平面的 policy Pod IP 地址或远程集群 DNS 可解析的主机名 |
| `values.global.remoteTelemetryAddress` | 有效的 IP 地址或主机名 | None | 指定 Istio 控制平面的 telemetry Pod IP 地址或远程集群 DNS 可解析的主机名 |
| `values.sidecarInjectorWebhook.enabled` | true, false | true | 指定是否在远程集群上启用自动 sidecar 注入 |
| `values.global.remotePilotCreateSvcEndpoint` | true, false | false | 如果设置，将使用 `remotePilotAddress` IP 创建用于 `istio-pilot` 的无选择器的服务和端点，以确保 `istio-pilot.<namespace>` 在远程集群上可通过 DNS 解析。 |
| `values.global.createRemoteSvcEndpoints` | true, false | false | 如果设置，`istio-pilot`、`istio-telemetry` 和 `istio-policy` 的 selector-less 服务和端点将用相应的远程 IP：`remotePilotAddress`、`remoteTelmetryAddress` 和 `remotePolicyAddress` 分别创建，这样确保在远程集群中服务名可以通过 DNS 解析。 |

## 为远程集群创建配置文件{#kubeconfig}

Istio 控制平面需要访问网格中的所有集群以发现服务、端点和 pod 属性。
下列步骤描述了如何通过远程集群为 Istio 控制平面创建 `kubeconfig` 配置文件。

在每个远程集群上执行这些步骤以将集群加入服务网格。这些步骤需要具有远程集群的 `cluster-admin` 用户访问权限。

1. 用以下命令设置为 `istio-reader-service-account` 服务账号构建 `kubeconfig` 文件所需的环境变量：

    {{< text bash >}}
    $ export WORK_DIR=$(pwd)
    $ CLUSTER_NAME=$(kubectl config view --minify=true -o jsonpath='{.clusters[].name}')
    $ export KUBECFG_FILE=${WORK_DIR}/${CLUSTER_NAME}
    $ SERVER=$(kubectl config view --minify=true -o jsonpath='{.clusters[].cluster.server}')
    $ NAMESPACE=istio-system
    $ SERVICE_ACCOUNT=istio-reader-service-account
    $ SECRET_NAME=$(kubectl get sa ${SERVICE_ACCOUNT} -n ${NAMESPACE} -o jsonpath='{.secrets[].name}')
    $ CA_DATA=$(kubectl get secret ${SECRET_NAME} -n ${NAMESPACE} -o jsonpath="{.data['ca\.crt']}")
    $ TOKEN=$(kubectl get secret ${SECRET_NAME} -n ${NAMESPACE} -o jsonpath="{.data['token']}" | base64 --decode)
    {{< /text >}}

    {{< tip >}}
    在许多系统上，`openssl enc -d -base64 -A` 可以替代 `base64 --decode`。
    {{< /tip >}}

1. 在工作目录中，用以下命令创建 `istio-reader-service-account` 服务账号对应的 `kubeconfig` 文件：

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

1. _（可选）_ 创建环境变量文件以创建远程集群的 secret：

    {{< text bash >}}
    $ cat <<EOF > remote_cluster_env_vars
    export CLUSTER_NAME=${CLUSTER_NAME}
    export KUBECFG_FILE=${KUBECFG_FILE}
    export NAMESPACE=${NAMESPACE}
    EOF
    {{< /text >}}

至此，您已在当前目录中创建了远程集群的 `kubeconfig` 文件。
`kubeconfig` 文件的文件名与原始集群名称相同。

## 实例化凭证{#credentials}

在运行 Istio 控制平面的集群上执行这一步骤。
该步骤使用了来自[上一节](#kubeconfig)的 `WORK_DIR`、`CLUSTER_NAME` 和 `NAMESPACE` 环境变量以及为远程集群的 secret 创建的文件。

如果您已经为远程集群的 secret 创建了环境变量文件，运行以下命令加载该文件：

{{< text bash >}}
$ source remote_cluster_env_vars
{{< /text >}}

您可以将 Istio 安装到不同的命名空间。
本步骤使用了 `istio-system` 命名空间。

{{< warning >}}
不要为运行 Istio 控制平面的本地集群存储和标记 secrets。
Istio 始终可以感知到本地集群的 Kubernetes 凭据。
{{< /warning >}}

创建一个 secret 并为每个远程集群正确标记：

{{< text bash >}}
$ kubectl create secret generic ${CLUSTER_NAME} --from-file ${KUBECFG_FILE} -n ${NAMESPACE}
$ kubectl label secret ${CLUSTER_NAME} istio/multiCluster=true -n ${NAMESPACE}
{{< /text >}}

{{< warning >}}
Kubernetes secret 数据密钥必须符合 `DNS-1123 subdomain` [格式](https://tools.ietf.org/html/rfc1123#page-13)。
例如，文件名不能含有下划线。
只需更改文件名使其符合格式，即可解决文件名的任何问题。
{{< /warning >}}

## 卸载远程集群{#uninstalling-the-remote-cluster}

运行下列命令以卸载远程集群：

{{< text bash >}}
    $ istioctl manifest generate \
    --set profile=remote \
    --set values.global.controlPlaneSecurityEnabled=false \
    --set values.global.createRemoteSvcEndpoints=true \
    --set values.global.remotePilotCreateSvcEndpoint=true \
    --set values.global.remotePilotAddress=${PILOT_POD_IP} \
    --set values.global.remotePolicyAddress=${POLICY_POD_IP} \
    --set values.global.remoteTelemetryAddress=${TELEMETRY_POD_IP} \
    --set gateways.enabled=false \
    --set autoInjection.enabled=true | kubectl delete -f -
{{< /text >}}

## 手动 sidecar 注入示例 {#manual-sidecar}

下列例子展示了如何使用 `istioctl manifest` 命令来为禁用自动 sidecar 注入的远程集群生成清单。
另外，这个例子还展示了如何通过 [`istioctl kube-inject`](/zh/docs/reference/commands/istioctl/#istioctl-kube-inject) 命令使用远程集群的 `configmaps` 来为远程集群生成任意应用的清单。

对远程集群执行下列步骤。

在开始之前，请按照[设置环境变量部分](#environment-var)中的说明设置端点IP环境变量。

1. 安装 Istio 远程配置文件：

    {{< text bash >}}
    $ istioctl manifest apply \
    --set profile=remote \
    --set values.global.controlPlaneSecurityEnabled=false \
    --set values.global.createRemoteSvcEndpoints=true \
    --set values.global.remotePilotCreateSvcEndpoint=true \
    --set values.global.remotePilotAddress=${PILOT_POD_IP} \
    --set values.global.remotePolicyAddress=${POLICY_POD_IP} \
    --set values.global.remoteTelemetryAddress=${TELEMETRY_POD_IP} \
    --set gateways.enabled=false \
    --set autoInjection.enabled=false
    {{< /text >}}

1. 为每个远程集群[生成](#kubeconfig) `kubeconfig` 配置文件。

1. 为每个远程集群[实例化凭证](#credentials)。

### 手动将 sidecars 注入到应用程序清单{#manually-inject-the-sidecars-into-the-application-manifests}

以下示例 `istioctl` 命令将 sidecar 注入到应用程序清单中。
在为远程集群设置了 `kubeconfig` 上下文的 shell 中运行以下命令。

{{< text bash >}}
$ ORIGINAL_SVC_MANIFEST=mysvc-v1.yaml
$ istioctl kube-inject --injectConfigMapName istio-sidecar-injector --meshConfigMapName istio -f ${ORIGINAL_SVC_MANIFEST} | kubectl apply -f -
{{< /text >}}

## 从不同的集群中访问服务{#access-services-from-different-clusters}

Kubernetes 基于集群解析 DNS。
由于 DNS 解析与集群有关，因此无论服务端点的位置在哪，您都必须在运行客户端的每个集群中定义服务对象。
为确保这种情况，请使用 `kubectl` 将服务对象复制到每个集群。
复制可确保 Kubernetes 可以解析任何集群中的服务名称。
由于服务对象是在命名空间中定义的，如果该命名空间不存在，您必须定义它，并将其包含在所有集群的服务定义中。

## 部署注意事项{#deployment-considerations}

前面的步骤提供了一个简单且按部就班的部署多集群环境的指导。
一个生产环境需要更多的步骤或更复杂的部署选项。
本节收集 Istio 服务的端点 IPs 并使用它们来调用 `istioctl`。
这个过程会在远程集群上创建 Istio 服务。
作为在远程集群中创建那些服务和端口的一部分，Kubernetes 会往 `kube-dns` 配置对象中添加 DNS 条目。

这让远程集群上的 `kube-dns` 配置对象可以为那些远程集群中的所有 Envoy sidecars 解析 Istio 服务名。
因为 Kubernetes pods 没有固定的 IPs，控制平面中的任意 Istio 服务 pod 的重启都会导致它的端点变化。
因此，任何从远程集群到那个端点的连接都会断开。
这个行为记录在 [Istio 问题 #4822](https://github.com/istio/istio/issues/4822)。

有几个选项可以避免或解决这个情况。本节概述了这些选项：

* 更新 DNS 条目
* 使用负载均衡服务类型
* 通过网关暴露这些 Istio 服务

### 更新 DNS 条目{#update-the-DNS-entries}

本地 Istio 控制平面发生任何故障或重新启动时，必须使用 Istio 服务的正确端点映射更新远程集群上的 `kube-dns`。
有许多方法可以做到这一点。
最明显的是在控制平面集群上的 Istio 服务重新启动后，在远程集群中重新运行 `istioctl` 命令。

### 使用负载均衡服务类型{#use-load-balance-service-type}

在 Kubernetes 中，您可以声明一个服务的服务类型为 `LoadBalancer`。
更多信息请参考 Kubernetes 文档的[服务类型](https://kubernetes.io/docs/concepts/services-networking/service/#publishing-services-service-types)。

Pod 重启问题的一个简单的解决方案就是为 Istio 服务使用负载均衡器。
然后，您可以使用负载均衡器的 IPs 作为 Istio 服务的端点 IPs 来配置远程集群。
您可能需要下列 Istio 服务的负载均衡器 IPs：

* `istio-pilot`
* `istio-telemetry`
* `istio-policy`

目前，Istio 安装没有提供用于为 Istio 服务指定服务类型的选项。
您可以在 Istio 清单中手动指定服务类型。

### 通过网关暴露这些 Istio 服务{#expose-the-Istio-services-via-a-gateway}

这个方法使用了 Istio ingress 网关功能。
远程集群需要 `istio-pilot`、`istio-telemetry` 和 `istio-policy` 服务指向 Istio ingress 网关的负载均衡器 IP。
然后，所有的服务指向相同的 IP。
您必须接着创建 destination rules 以在 ingress 网关的主集群中访问到对应的 Istio 服务。

此方法提供了两种选择：

* 重用提供的清单所创建的默认 Istio ingress 网关。您只需要添加正确的 destination rules。

* 为多集群创建另外一个 Istio ingress 网关。

## 安全性{#security}

Istio 支持在控制平面组件之间以及注入到应用的 pods 的 sidecar 之间部署双向 TLS。

### 控制平面安全性{#control-plane-security}

按照这些步骤启用控制平面安全性：

1. 部署 Istio 控制平面集群需要：

    * 启用控制平面安全性。

    * 禁用 `citadel` 证书自签名。

    * Istio 控制平面命名空间中具有[证书颁发机构（CA）证书](/zh/docs/tasks/security/citadel-config/plugin-ca-cert/#plugging-in-the-existing-certificate-and-key)的名为 `cacerts` 的 secret。

1. 部署 Istio 远程集群需要：

    * 启用控制平面安全性。

    * 禁用 `citadel` 证书自签名。

    * Istio 控制平面命名空间中具有 [CA 证书](/zh/docs/tasks/security/citadel-config/plugin-ca-cert/#plugging-in-the-existing-certificate-and-key)的名为 `cacerts` 的 secret。
      主集群的证书颁发机构（CA）或根 CA 必须也为远程集群签名 CA 证书。

    * Istio pilot 服务主机名可被 DNS 解析。
      DNS 解析是必需的，因为 Istio 将 sidecar 配置为使用 `istio-pilot.<namespace>` 主题名称格式来验证证书主题名称。

    * 设置控制平面 IPs 或可解析的主机名。

### 应用 pods 间的双向 TLS{#mutual-TLS-between-application-pods}

按照这些步骤以为所有应用 pods 启用双向 TLS：

1. 部署 Istio 控制平面集群需要：

    * 启用全局双向 TLS。

    * 禁用 Citadel 证书自签名。

    * Istio 控制平面命名空间中具有 [CA 证书](/zh/docs/tasks/security/citadel-config/plugin-ca-cert/#plugging-in-the-existing-certificate-and-key)的名为 `cacerts` 的 secret。

1. 部署 Istio 远程集群需要：

    * 启用全局双向 TLS。

    * 禁用 Citadel 证书自签名。

    * Istio 控制平面命名空间中具有 [CA 证书](/zh/docs/tasks/security/citadel-config/plugin-ca-cert/#plugging-in-the-existing-certificate-and-key)的名为 `cacerts` 的 secret。
      主集群的 CA 或根 CA 必须也为远程集群签名 CA 证书。

{{< tip >}}
对于控制平面安全性和应用 pod 安全性步骤，CA 证书的步骤相同。
{{< /tip >}}

### 部署示例{#example-deployment}

这个示例过程将在同时启用控制平面双向 TLS 和应用 pod 双向 TLS 的情况下安装 Istio。
该过程用无选择器的服务和端点来设置远程集群。
Istio Pilot 用该服务和端点以让远程 sidecars 可以通过 Istio 的本地 Kubernetes DNS 解析 `istio-pilot.istio-system` 主机名。

#### 主集群：部署控制平面集群{#primary-cluster-deploy-the-control-plane-cluster}

1. 使用 `istio-system` 命名空间中的 Istio 证书示例创建 `cacerts` secret：

    {{< text bash >}}
    $ kubectl create ns istio-system
    $ kubectl create secret generic cacerts -n istio-system --from-file=samples/certs/ca-cert.pem --from-file=samples/certs/ca-key.pem --from-file=samples/certs/root-cert.pem --from-file=samples/certs/cert-chain.pem
    {{< /text >}}

1. 部署 Istio 控制平面，并为控制平面和应用程序容器启用安全性：

    {{< text bash >}}
    $ istioctl manifest apply \
      --set values.global.mtls.enabled=true \
      --set values.security.selfSigned=false \
      --set values.global.controlPlaneSecurityEnabled=true
    {{< /text >}}

#### 远程集群：部署 Istio 组件{#remote-cluster-deploy-Istio-components}

1. 使用 `istio-system` 命名空间中的 Istio 证书示例创建 `cacerts` secret：

    {{< text bash >}}
    $ kubectl create ns istio-system
    $ kubectl create secret generic cacerts -n istio-system --from-file=samples/certs/ca-cert.pem --from-file=samples/certs/ca-key.pem --from-file=samples/certs/root-cert.pem --from-file=samples/certs/cert-chain.pem
    {{< /text >}}

1. 按照[设置环境变量部分](#environment-var)中的说明设置端点 IP 环境变量。

1. 以下命令部署远程集群的组件，并为控制平面和应用程序 pod 启用安全性，并启用 Istio Pilot 无选择器服务和端点的创建，以在远程集群中获取 DNS 条目。

    {{< text bash >}}
    $ istioctl manifest apply \
      --set profile=remote \
      --set values.global.mtls.enabled=true \
      --set values.security.selfSigned=false \
      --set values.global.controlPlaneSecurityEnabled=true \
      --set values.global.createRemoteSvcEndpoints=true \
      --set values.global.remotePilotCreateSvcEndpoint=true \
      --set values.global.remotePilotAddress=${PILOT_POD_IP} \
      --set values.global.remotePolicyAddress=${POLICY_POD_IP} \
      --set values.global.remoteTelemetryAddress=${TELEMETRY_POD_IP} \
      --set gateways.enabled=false \
      --set autoInjection.enabled=true
    {{< /text >}}

1. 要为远程集群生成 `kubeconfig` 配置文件，请遵循 [Kubernetes 配置部分](#kubeconfig)中的步骤。

### 主集群：实例化凭证{#primary-cluster-instantiate-credentials}

您必须为每个远程集群都实例化凭证。请按照[实例化凭证过程](#credentials)完成部署。

### 恭喜{#congratulations}

您已将所有群集中的所有 Istio 组件都配置为在应用 sidecars、控制平面组件和其他应用 sidecars 之间使用双向 TLS。
