---
title: 安装 Istio CNI 节点代理
description: 安装并使用 Istio CNI 节点代理，可以让运维人员用更低的权限来部署工作负载。
weight: 70
aliases:
    - /zh/docs/setup/kubernetes/additional-setup/cni
    - /zh/docs/setup/additional-setup/cni
keywords: [cni]
owner: istio/wg-networking-maintainers
test: yes
---

Istio {{< gloss "cni" >}}CNI{{< /gloss >}} 节点代理用于为网格中的 Pod 配置流量重定向。
它以 DaemonSet 的形式在每个节点上运行，并具有被提升的权限。
两种 Istio {{< gloss "data plane" >}}数据平面{{< /gloss >}}模式均使用 CNI 节点代理。

对于 {{< gloss "sidecar" >}}Sidecar{{< /gloss >}} 数据平面模式，
Istio CNI 节点代理是可选的。它消除了在网格中的每个 Pod 中运行特权 Init 容器的要求，
而是将该模式替换为每个 Kubernetes 节点上的单个特权节点代理 Pod。

Istio CNI 节点代理在 {{< gloss "sidecar" >}}Ambient{{< /gloss >}} 数据平面模式下是**必需的**。

本指南重点介绍如何使用 Istio CNI 节点代理作为 Sidecar 数据平面模式的可选组件。
有关使用 Ambient 数据平面模式的信息，请参阅 [Ambient 模式文档](/zh/docs/ambient/)。

{{< tip >}}
注意：Istio CNI 节点代理**不会**替换集群现有的 {{< gloss "cni" >}}CNI{{< /gloss >}}。
除此之外，它还会安装一个**链式** CNI 插件或云提供商使用的集群 CNI，
其中这种链式 CNI 插件设计为分层堆叠在另一个先前安装的主接口
CNI（例如 [Calico](https://docs.projectcalico.org)）之上。
有关详细信息，请参阅[与 CNI 的兼容性](#compatibility-with-other-cnis)。
{{< /tip >}}

按照本指南安装、配置和使用具有 Sidecar 数据平面模式的 Istio CNI 节点代理。

## Sidecar 流量重定向的工作原理 {#how-sidecar-traffic-redirection-works}

### 使用 Init 容器（没有 Istio CNI 节点代理） {#using-the-init-container-without-the-istio-cni-node-agent}

默认情况下，Istio 会在网格中部署的 Pod 中注入一个 Init 容器 `istio-init`。
这个 `istio-init` 容器将设置并重定向与 Istio Sidecar 代理的 Pod 网络来往流量。
这要求将 Pod 部署到网格的用户或服务帐户具有足够的 Kubernetes RBAC
权限来部署[具有 `NET_ADMIN` 和 `NET_RAW` 功能的容器](https://kubernetes.io/zh-cn/docs/tasks/configure-pod-container/security-context/#set-capabilities-for-a-container)。

### 使用 Istio CNI 节点代理 {#using-the-istio-cni-node-agent}

要求 Istio 用户具有提升的 Kubernetes RBAC 权限对于某些组织的安全合规性来说是有问题的，
同样要求在每个工作负载上部署特权 Init 容器也是有问题的。

`istio-cni` 节点代理实际上是 `istio-init` 容器的替代品，它支持相同的网络功能，
但不需要在每个工作负载中使用或部署特权 Init 容器。相反，`istio-cni` 本身作为节点上的单个特权 Pod 运行。
它使用此特权在节点上安装[链式 CNI 插件](https://www.cni.dev/docs/spec/#section-2-execution-protocol)，
该插件在“主”接口 CNI 插件之后调用。每当创建新 Pod 时，
Kubernetes 都会将 CNI 插件作为主机节点上的特权进程动态调用，并能够配置 Pod 网络。

Istio 链式 CNI 插件始终在主接口插件之后运行，识别需要流量重定向的带有 Sidecar 的用户应用程序 Pod，
并在 Kubernetes Pod 生命周期的网络设置阶段设置重定向，从而无需特权 Init 容器，
也无需用户和 Pod 部署的 [`NET_ADMIN` 和 `NET_RAW` 功能的要求](/zh/docs/ops/deployment/application-requirements/)。

{{< image width="60%" link="./cni.svg" caption="Istio CNI" >}}

## 使用前提条件 {#prerequisites-for-use}

1. 使用正确配置的主接口 CNI 插件安装 Kubernetes。
   由于[实现 Kubernetes 网络模型需要支持 CNI 插件](https://kubernetes.io/zh-cn/docs/concepts/extend-kubernetes/compute-storage-net/network-plugins/)，
   所以如果您拥有一个较新的 Kubernetes 集群并且具有功能齐全的 Pod 网络，那么您可能已经拥有此功能。
    * AWS EKS、Azure AKS 和 IBM Cloud IKS 集群都具有此功能。
    * 当启用以下任一特性时，Google Cloud GKE 集群就会启用 CNI：
       [网络策略](https://cloud.google.com/kubernetes-engine/docs/how-to/network-policy)、
       [节点内可见性](https://cloud.google.com/kubernetes-engine/docs/how-to/intranode-visibility)、
       [工作负载身份](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity)、
       [Pod 安全策略](https://cloud.google.com/kubernetes-engine/docs/how-to/pod-security-policies#overview)、
       或 [dataplane v2](https://cloud.google.com/kubernetes-engine/docs/concepts/dataplane-v2)。
    * Kind 默认启用了 CNI。
    * OpenShift 默认启用了 CNI。

1. 安装 Kubernetes，并启用 [ServiceAccount 准入控制器](https://kubernetes.io/zh-cn/docs/reference/access-authn-authz/admission-controllers/#serviceaccount)。
    * Kubernetes 文档强烈建议所有使用 `ServiceAccounts` 的 Kubernetes 安装都这样做。

## 安装 CNI 节点代理 {#installing-the-cni-node-agent}

### 使用 `istio-cni` 组件安装 Istio {#install-istio-with-the-istio-cni-component}

在大多数环境中，可以使用以下命令安装启用了 `istio-cni` 组件的基础 Istio 集群：

{{< tabset category-name="gateway-install-type" >}}

{{< tab name="IstioOperator" category-value="iop" >}}

{{< text syntax=bash snip_id=cni_agent_operator_install >}}
$ cat <<EOF > istio-cni.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  components:
    cni:
      namespace: istio-system
      enabled: true
EOF
$ istioctl install -f istio-cni.yaml -y
{{< /text >}}

{{< /tab >}}

{{< tab name="Helm" category-value="helm" >}}

{{< text syntax=bash snip_id=cni_agent_helm_install >}}
$ helm install istio-cni istio/cni -n istio-system --wait
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

这将在集群中部署一个 `istio-cni` DaemonSet，它将在每个活动节点上创建一个 Pod，
在每个节点上部署 Istio CNI 插件二进制文件，并为插件设置必要的节点级配置。CNI DaemonSet 使用
[`system-node-critical`](https://kubernetes.io/zh-cn/docs/tasks/administer-cluster/guaranteed-scheduling-critical-addon-pods/)
`PriorityClass` 运行。这是因为它是实际重新配置 Pod 网络以将它们添加到 Istio 网格的唯一方法。

{{< tip >}}
您可以将 `istio-cni` 安装到任何 Kubernetes 命名空间中，但该命名空间必须允许在其中调度具有
`system-node-critical` PriorityClass 的 Pod。
某些云提供商（尤其是 GKE）默认不允许在任何命名空间中调度 `system-node-critical` Pod，
但允许在特定命名空间中对其调度，例如 `kube-system`。

您可以将 `istio-cni` 安装到 `kube-system` 中，或者（推荐）为您的 GKE 集群定义一个 ResourceQuota，
以允许在 `istio-system` 中使用 `system-node-critical` Pod。有关更多详细信息，
请参阅[此处](/zh/docs/ambient/install/platform-prerequisites#google-kubernetes-engine-gke)。
{{< /tip >}}

请注意，如果根据[使用 Helm 安装](/zh/docs/setup/install/helm/#installation-steps)指南使用 Helm Chart 安装 `istiod`，
则必须使用以下额外的覆盖值安装 `istiod`，以禁用特权 Init 容器注入：

{{< text syntax=bash snip_id=cni_agent_helm_istiod_install >}}
$ helm install istiod istio/istiod -n istio-system --set pilot.cni.enabled=true --wait
{{< /text >}}

### 附加配置 {#additional-configuration}

除了上述基本配置外，还有其他可设置的配置标志：

* `values.cni.cniBinDir` 和 `values.cni.cniConfDir` 配置安装插件二进制文件和创建插件配置的目录路径。
* `values.cni.cniConfFileName` 配置插件配置文件的名称。
* `values.cni.chained` 控制是否将插件配置为链式 CNI 插件。

通常情况下，这些不需要更改，但某些平台可能使用非标准路径。如果有，
请在[此处](/zh/docs/ambient/install/platform-prerequisites)查看特定平台的指南。

{{< tip >}}
节点可调度和 Istio CNI 插件在该节点上准备就绪之间存在时间间隔。如果应用程序 Pod 在此期间启动，
则可能未正确设置流量重定向，流量将能够绕过 Istio Sidecar。

对于 Sidecar 数据平面模式，此竞争条件可通过“检测和修复”方法缓解。
请参阅[竞争条件和缓解](#race-condition-mitigation)部分以了解此缓解措施的含义以及配置说明。
{{< /tip >}}

### 处理修订的 Init 容器注入 {#handling-init-container-injection-for-revisions}

在安装启用了 CNI 组件的修订版控制平面时，需要为每个安装的修订版设置 `values.pilot.cni.enabled=true`，
以便 Sidecar 注入器不会尝试为该修订版注入 `istio-init` Init 容器。

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  revision: REVISION_NAME
  ...
  values:
    pilot:
      cni:
        enabled: true
  ...
{{< /text >}}

版本 `1.x` 的 CNI 插件与版本 `1.x-1`、`1.x` 和 `1.x+1` 的控制平面兼容，
这意味着 CNI 和控制平面可以按任何顺序升级，只要它们的版本差异在一个小版本以内。

## 操作安装了 CNI 节点代理的集群 {#operating-clusters-with-the-cni-node-agent-installed}

### 升级 {#upgrading}

使用[原地升级](/zh/docs/setup/upgrade/in-place/)对 Istio 进行升级时，
可以使用一个 `IstioOperator` 资源将 CNI 组件与控制平面一起升级。

使用[金丝雀升级](/zh/docs/setup/upgrade/canary/)对 Istio 进行升级时，
由于 CNI 组件作为集群单例运行，因此建议与修订版的控制平面分开操作和升级 CNI 组件。

下面的 `IstioOperator` 可用于独立升级 CNI 组件。

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  profile: empty # 不包括其他组件
  components:
    cni:
      enabled: true
  values:
    cni:
      excludeNamespaces:
        - istio-system
{{< /text >}}

对于 Helm 来说这不是问题，因为 istio-cni 是单独安装的，并且可以通过 Helm 升级：

{{< text syntax=bash snip_id=cni_agent_helm_upgrade >}}
$ helm upgrade istio-cni istio/cni -n istio-system --wait
{{< /text >}}

### 竞争条件和缓解 {#race-condition-mitigation}

Istio CNI DaemonSet 在每个节点上安装 CNI 网络插件。但是，DaemonSet Pod
被调度到节点上与 CNI 插件安装并准备使用之间存在时间间隔。
应用程序 Pod 有可能在此时间间隔内启动，而 `kubelet` 不知道 Istio CNI 插件。
结果是应用程序 Pod 在没有 Istio 流量重定向的情况下启动并绕过 Istio Sidecar。

为了缓解应用程序 Pod 和 Istio CNI DaemonSet 之间的竞争，在 Sidecar
注入过程中添加了一个 `istio-validation` Init 容器，
用于检测流量重定向是否设置正确，如果设置不正确，则阻止 Pod 启动。
CNI DaemonSet 将检测并处理任何卡在这种状态的 Pod；如何处理 Pod 取决于下面描述的配置。
此缓解措施默认启用，可以通过将 `values.cni.repair.enabled` 设置为 false 来关闭。

此修复功能可以进一步配置不同的 RBAC 权限，
以帮助缓解 [`ISTIO-SECURITY-2023-005`](/zh/news/security/istio-security-2023-005/)
中详述的理论攻击媒介。通过根据需要将以下字段设置为 true/false，
您可以选择授予 Istio CNI 的 Kubernetes RBAC 权限。

| 配置                             | 角色     | 错误时的行为                                     | 备注               |
|--------------------------------|--------|--------------------------------------------|------------------|
| `values.cni.repair.deletePods` | 删除 Pod | Pod 被删除后，重新安排时它们将具有正确的配置。                  | 1.20 及以上版本的默认设置  |
| `values.cni.repair.labelPods`  | 更新 Pod | Pod 仅带有标签。用户需要采取手动措施来解决。                   |                  |
| `values.cni.repair.repairPods` | 无      | Pod 会动态地重新配置以获得适当的配置。当容器重新启动时，Pod 将继续正常执行。 | 1.21 及更高版本中的默认设置 |

### 流量重定向参数 {#traffic-redirection-parameters}

为了将应用程序 Pod 网络命名空间中的流量重定向到 Istio 代理 Sidecar 或从 Istio 代理 Sidecar 重定向，
Istio CNI 插件会配置命名空间的 iptables。您可以使用与平常相同的 Pod 注解来调整流量重定向参数，
例如要包含或排除在重定向中的端口和 IP 范围。有关可用参数，
请参阅[资源注解](/zh/docs/reference/config/annotations)。

### 与应用程序 Init 容器的兼容性 {#compatibility-with-application-init-containers}

Istio CNI 插件可能会导致任何处于 Sidecar 数据平面模式的应用程序 Init 容器出现网络连接问题。
使用 Istio CNI 时，`kubelet` 会按照以下步骤启动 Pod：

1. 默认接口 CNI 插件设置 Pod 网络接口并分配 Pod IP。
1. Istio CNI 插件设置到 Pod 内的 Istio Sidecar 代理的流量重定向。
1. 所有 Init 容器均成功执行并完成。
1. Istio Sidecar 代理与 Pod 的其他容器一起在 Pod 中启动。

Init 容器在 Sidecar 代理启动之前执行，这可能会导致其执行期间出现流量丢失。
请使用以下设置之一来避免这种流量丢失：

1. 使用 `runAsUser` 将 Init 容器的 `uid` 设置为 `1337`。
   `1337` 是 [Sidecar 代理使用的 `uid`](/zh/docs/ops/deployment/application-requirements/#pod-requirements)。
   此 `uid` 发送的流量不会被 Istio 的 `iptables` 规则捕获。应用程序容器流量仍将照常被捕获。
1. 设置 `traffic.sidecar.istio.io/excludeOutboundIPRanges` 注解以禁止将流量重定向到与 Init 容器通信的任何 CIDR。
1. 设置 `traffic.sidecar.istio.io/excludeOutboundPorts` 注解以禁用将流量重定向到 Init 容器使用的特定出站端口。

{{< tip >}}
如果启用了 [DNS 代理](/zh/docs/ops/configuration/traffic-management/dns-proxy/)，
并且 Init 容器将流量发送到需要 DNS 解析的主机名，则必须使用 `runAsUser 1337` 解决方法。
{{< /tip >}}

{{< tip >}}
某些平台（例如 OpenShift）不使用 `1337` 作为 Sidecar `uid`，而是使用仅在运行时才知道的伪随机数。在这种情况下，
您可以利用[自定义注入功能](/zh/docs/setup/additional-setup/sidecar-injection/#customizing-injection)指示代理以预定义的
`uid` 运行，并将相同的 `uid` 用于 Init 容器。
{{< /tip >}}

{{< warning >}}
请谨慎使用流量捕获排除，因为 IP/端口排除注解不仅适用于 Init 容器流量，也适用于应用程序容器流量。
即发送到配置的 IP/端口的应用程序流量将绕过 Istio Sidecar。
{{< /warning >}}

### 与其他 CNI 的兼容性 {#compatibility-with-other-cnis}

Istio CNI 插件遵循 [CNI 规范](https://www.cni.dev/docs/spec/#container-network-interface-cni-specification)，
并且应该与任何遵循该规范的 CNI、容器运行时或其他插件兼容。

Istio CNI 插件以链式 CNI 插件的形式运行。这意味着其配置将附加到现有 CNI 插件配置列表中。
有关更多详细信息，请参阅 [CNI 规范参考](https://www.cni.dev/docs/spec/#section-1-network-configuration-format)。

当 Pod 被创建或删除时，容器运行时会按顺序调用列表中的每个插件。

Istio CNI 插件执行一些操作来设置应用程序 Pod 的流量重定向，比如在 Sidecar 数据平面模式下，
这意味着在 Pod 的网络命名空间中应用 `iptables` 规则以将 Pod 内的流量重定向到注入的 Istio 代理 Sidecar。
