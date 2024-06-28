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

The Istio {{< gloss="cni" >}}CNI{{< /gloss >}} node agent is used to configure traffic redirection for pods in the mesh. It runs as a DaemonSet, on every node, with elevated privileges. The CNI node agent is used by both Istio {{< gloss >}}data plane{{< /gloss >}} modes.
Istio {{< gloss="cni" >}}CNI{{< /gloss >}} 节点代理用于为网格中的 pod 配置流量重定向。它以 DaemonSet 的形式在每个节点上运行，并具有提升的权限。两种 Istio {{< gloss >}} 数据平面{{< /gloss >}} 模式均使用 CNI 节点代理。

For the {{< gloss >}}sidecar{{< /gloss >}} data plane mode, the Istio CNI node agent is optional. It removes the requirement of running privileged init containers in every pod in the mesh, replacing that model with a single privileged node agent pod on each Kubernetes node.
对于 {{< gloss >}}sidecar{{</gloss >}} 数据平面模式，Istio CNI 节点代理是可选的。它消除了在网格中的每个 pod 中运行特权 init 容器的要求，而是将该模型替换为每个 Kubernetes 节点上的单个特权节点代理 pod。

The Istio CNI node agent is **required** in the {{< gloss >}}ambient{{< /gloss >}} data plane mode.
Istio CNI 节点代理在 {{< gloss >}}ambient{{</gloss >}} 数据平面模式下是 **必需的**。

This guide is focused on using the Istio CNI node agent as an optional part of the sidecar data plane mode. Consult [the ambient mode documentation](/docs/ambient/) for information on using the ambient data plane mode.
本指南重点介绍如何使用 Istio CNI 节点代理作为 Sidecar 数据平面模式的可选部分。有关使用环境数据平面模式的信息，请参阅 [环境模式文档](/docs/ambient/)。

{{< tip >}}
Note: The Istio CNI node agent _does not_ replace your cluster's existing {{< gloss="cni" >}}CNI{{< /gloss >}}. Among other things, it installs a _chained_ CNI plugin, which is designed to be layered on top of another, previously-installed primary interface CNI, such as [Calico](https://docs.projectcalico.org), or the cluster CNI used by your cloud provider. See [compatibility with CNIs](#compatibility-with-other-cni-plugins) for details.
注意：Istio CNI 节点代理不会替换集群现有的 {{< gloss="cni" >}}CNI{{< /gloss >}}。除此之外，它还会安装一个 _链式_ CNI 插件，该插件旨在分层放置在另一个先前安装的主接口 CNI 之上，例如 [Calico](https://docs.projectcalico.org) 或云提供商使用的集群 CNI。有关详细信息，请参阅 [与 CNI 的兼容性](#与其他 cni 插件的兼容性)。
{{< /tip >}}

Follow this guide to install, configure, and use the Istio CNI node agent with the sidecar data plane mode.
按照本指南安装、配置和使用具有 sidecar 数据平面模式的 Istio CNI 节点代理。

## How sidecar traffic redirection works
## Sidecar 流量重定向的工作原理

### Using the init container (without the Istio CNI node agent)
### 使用 init 容器（没有 Istio CNI 节点代理）

By default Istio injects an init container, `istio-init`, in pods deployed in the mesh. The `istio-init` container sets up the pod network traffic redirection to/from the Istio sidecar proxy. This requires the user or service-account deploying pods to the mesh to have sufficient Kubernetes RBAC permissions to deploy [containers with the `NET_ADMIN` and `NET_RAW` capabilities](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-capabilities-for-a-container).
默认情况下，Istio 会在部署在网格中的 pod 中注入一个初始化容器“istio-init”。“istio-init”容器设置 pod 网络流量重定向到/来自 Istio sidecar 代理。这要求将 pod 部署到网格的用户或服务帐户具有足够的 Kubernetes RBAC 权限来部署[具有“NET_ADMIN”和“NET_RAW”功能的容器]（https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-capabilities-for-a-container）。

### Using the Istio CNI node agent
### 使用 Istio CNI 节点代理

Requiring Istio users to have elevated Kubernetes RBAC permissions is problematic for some organizations' security compliance, as is the requirement to deploy privileged init containers with every workload.
要求 Istio 用户具有提升的 Kubernetes RBAC 权限对于某些组织的安全合规性来说是有问题的，因为要求在每个工作负载上部署特权 init 容器也是如此。

The `istio-cni` node agent is effectively a replacement for the `istio-init` container that enables the same networking functionality, but without requiring the use or deployment of privileged init containers in every workload. Instead, `istio-cni` itself runs as a single privileged pod on the node. It uses this privilege to install a [chained CNI plugin](https://www.cni.dev/docs/spec/#section-2-execution-protocol) on the node, which is invoked after your "primary" interface CNI plugin. CNI plugins are invoked dynamically by Kubernetes as a privileged process on the host node whenever a new pod is created, and are able to configure pod networking.
`istio-cni` 节点代理实际上是 `istio-init` 容器的替代品，它支持相同的网络功能，但不需要在每个工作负载中使用或部署特权 init 容器。相反，`istio-cni` 本身作为节点上的单个特权 pod 运行。它使用此特权在节点上安装 [链式 CNI 插件](https://www.cni.dev/docs/spec/#section-2-execution-protocol)，该插件在“主”接口 CNI 插件之后调用。每当创建新 pod 时，Kubernetes 都会将 CNI 插件作为主机节点上的特权进程动态调用，并能够配置 pod 网络。

The Istio chained CNI plugin always runs after the primary interface plugins, identifies user application pods with sidecars requiring traffic redirection, and sets up redirection in the Kubernetes pod lifecycle's network setup phase, thereby removing the need for privileged init containers, as well as the [requirement for `NET_ADMIN` and `NET_RAW` capabilities](/docs/ops/deployment/application-requirements/) for users and pod deployments.
Istio 链式 CNI 插件始终在主接口插件之后运行，识别需要流量重定向的带有 sidecar 的用户应用程序 pod，并在 Kubernetes pod 生命周期的网络设置阶段设置重定向，从而无需特权 init 容器，以及用户和 pod 部署的 [`NET_ADMIN` 和 `NET_RAW` 功能的要求](/docs/ops/deployment/application-requirements/)。

{{< image width="60%" link="./cni.svg" caption="Istio CNI" >}}

## Prerequisites for use
## 使用前提条件

1. Install Kubernetes with a correctly-configured primary interface CNI plugin. As [supporting CNI plugins is required to implement the Kubernetes network model](https://kubernetes.io/docs/concepts/extend-kubernetes/compute-storage-net/network-plugins/), you probably already have this if you have a reasonably recent Kubernetes cluster with functional pod networking.
1. 使用正确配置的主接口 CNI 插件安装 Kubernetes。由于 [实现 Kubernetes 网络模型需要支持 CNI 插件](https://kubernetes.io/docs/concepts/extend-kubernetes/compute-storage-net/network-plugins/)，如果您拥有一个较新的 Kubernetes 集群并且具有功能齐全的 pod 网络，那么您可能已经拥有此功能。
    * AWS EKS, Azure AKS, and IBM Cloud IKS clusters have this capability.
    * AWS EKS、Azure AKS 和 IBM Cloud IKS 集群具有此功能。
    * Google Cloud GKE clusters have CNI enabled when any of the following features are enabled:
    * 当启用以下任何功能时，Google Cloud GKE 集群就会启用 CNI：
       [network policy](https://cloud.google.com/kubernetes-engine/docs/how-to/network-policy),
       [intranode visibility](https://cloud.google.com/kubernetes-engine/docs/how-to/intranode-visibility),
       [workload identity](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity),
       [pod security policy](https://cloud.google.com/kubernetes-engine/docs/how-to/pod-security-policies#overview),
       or [dataplane v2](https://cloud.google.com/kubernetes-engine/docs/concepts/dataplane-v2).
       [网络策略](https://cloud.google.com/kubernetes-engine/docs/how-to/network-policy)、
       [节点内可见性](https://cloud.google.com/kubernetes-engine/docs/how-to/intranode-visibility)、
       [工作负载身份](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity)、
       [pod 安全策略](https://cloud.google.com/kubernetes-engine/docs/how-to/pod-security-policies#overview)、
       或 [dataplane v2](https://cloud.google.com/kubernetes-engine/docs/concepts/dataplane-v2)。
    * Kind has CNI enabled by default.
    * OpenShift has CNI enabled by default.
    * Kind 默认启用 CNI。
    * OpenShift 默认启用 CNI。

1. Install Kubernetes with the [ServiceAccount admission controller](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/#serviceaccount) enabled.
1. 安装 Kubernetes，并启用 [ServiceAccount 准入控制器](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/#serviceaccount)。
    * The Kubernetes documentation highly recommends this for all Kubernetes installations where `ServiceAccounts` are utilized.
    * Kubernetes 文档强烈建议所有使用“ServiceAccounts”的 Kubernetes 安装都这样做。

## Installing the CNI node agent
## 安装 CNI 节点代理

### Install Istio with the `istio-cni` component
### 使用 `istio-cni` 组件安装 Istio

In most environments, a basic Istio cluster with the `istio-cni` component enabled can be installed using the following commands:
在大多数环境中，可以使用以下命令安装启用了“istio-cni”组件的基本 Istio 集群：

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

This will deploy an `istio-cni` DaemonSet into the cluster, which will create one Pod on every active node, deploy the Istio CNI plugin binary on each, and set up the necessary node-level configuration for the plugin. The CNI DaemonSet runs with [`system-node-critical`](https://kubernetes.io/docs/tasks/administer-cluster/guaranteed-scheduling-critical-addon-pods/) `PriorityClass`. This is because it is the only means of actually reconfiguring pod networking to add them to the Istio mesh.
这将在集群中部署一个 `istio-cni` DaemonSet，它将在每个活动节点上创建一个 Pod，在每个节点上部署 Istio CNI 插件二进制文件，并为插件设置必要的节点级配置。CNI DaemonSet 使用 [`system-node-critical`](https://kubernetes.io/docs/tasks/administer-cluster/guaranteed-scheduling-critical-addon-pods/) `PriorityClass` 运行。这是因为它是实际重新配置 pod 网络以将它们添加到 Istio 网格的唯一方法。

{{< tip >}}
You can install `istio-cni` into any Kubernetes namespace, but the namespace must allow pods with the `system-node-critical` PriorityClass to be scheduled in it. Some cloud providers (notably GKE) by default disallow the scheduling of `system-node-critical` pods in any namespace but specific ones, such as `kube-system`.
您可以将“istio-cni”安装到任何 Kubernetes 命名空间中，但该命名空间必须允许在其中调度具有“system-node-critical” PriorityClass 的 pod。某些云提供商（尤其是 GKE）默认不允许在任何命名空间中调度“system-node-critical” pod，但允许在特定命名空间中调度，例如“kube-system”。

You may either install `istio-cni` into `kube-system`, or (recommended) define a ResourceQuota for your GKE cluster that allows the use of `system-node-critical` pods inside `istio-system`. See [here](/docs/ambient/install/platform-prerequisites#google-kubernetes-engine-gke) for more details.
您可以将“istio-cni”安装到“kube-system”中，或者（推荐）为您的 GKE 集群定义一个 ResourceQuota，以允许在“istio-system”中使用“system-node-critical”pod。有关更多详细信息，请参阅[此处]（/docs/ambient/install/platform-prerequisites#google-kubernetes-engine-gke）。
{{< /tip >}}

Note that if installing `istiod` with the Helm chart according to the [Install with Helm](/docs/setup/install/helm/#installation-steps) guide, you must install `istiod` with the following extra override value, in order to disable the privileged init container injection:
请注意，如果根据 [使用 Helm 安装](/docs/setup/install/helm/#installation-steps) 指南使用 Helm 图表安装 `istiod`，则必须使用以下额外的覆盖值安装 `istiod`，以禁用特权初始化容器注入：

{{< text syntax=bash snip_id=cni_agent_helm_istiod_install >}}
$ helm install istiod istio/istiod -n istio-system --set pilot.cni.enabled=true --wait
{{< /text >}}

### Additional configuration
### 附加配置

In addition to the above basic configuration there are additional configuration flags that can be set:
除了上述基本配置外，还有其他可设置的配置标志：

* `values.cni.cniBinDir` and `values.cni.cniConfDir` configure the directory paths to install the plugin binary and create plugin configuration.
* `values.cni.cniConfFileName` configures the name of the plugin configuration file.
* `values.cni.chained` controls whether to configure the plugin as a chained CNI plugin.
* `values.cni.cniBinDir` 和 `values.cni.cniConfDir` 配置安装插件二进制文件和创建插件配置的目录路径。
* `values.cni.cniConfFileName` 配置插件配置文件的名称。
* `values.cni.chained` 控制是否将插件配置为链式 CNI 插件。

Normally, these do not need to be changed, but some platforms may use nonstandard paths. Please check the guidelines for your specific platform, if any, [here](/docs/ambient/install/platform-prerequisites)
通常情况下，这些不需要更改，但某些平台可能使用非标准路径。如果有，请在此处查看特定平台的指南（/docs/ambient/install/platform-prerequisites）

{{< tip >}}
There is a time gap between a node becomes schedulable and the Istio CNI plugin becomes ready on that node. If an application pod starts up during this time, it is possible that traffic redirection is not properly set up and traffic would be able to bypass the Istio sidecar.
节点可调度和 Istio CNI 插件在该节点上准备就绪之间存在时间间隔。如果应用程序 pod 在此期间启动，则可能未正确设置流量重定向，流量将能够绕过 Istio sidecar。

This race condition is mitigated for the sidecar data plane mode by a "detect and repair" method. Please take a look at [race condition & mitigation](#race-condition--mitigation) section to understand the implication of this mitigation, and for configuration instructions
对于 Sidecar 数据平面模式，此竞争条件可通过“检测和修复”方法缓解。请参阅 [竞争条件和缓解](#race-condition--mitigation) 部分以了解此缓解措施的含义以及配置说明
{{< /tip >}}

### Handling init container injection for revisions
### 处理修订的初始化容器注入

When installing revisioned control planes with the CNI component enabled, `values.pilot.cni.enabled=true` needs to be set for each installed revision, so that the sidecar injector does not attempt inject the `istio-init` init container for that revision.
在安装启用了 CNI 组件的修订版控制平面时，需要为每个安装的修订版设置 `values.pilot.cni.enabled=true`，以便 sidecar 注入器不会尝试为该修订版注入 `istio-init` 初始化容器。

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

The CNI plugin at version `1.x` is compatible with control plane at version `1.x-1`, `1.x`, and `1.x+1`, which means CNI and control plane can be upgraded in any order, as long as their version difference is within one minor version.
版本 `1.x` 的 CNI 插件与版本 `1.x-1`、`1.x` 和 `1.x+1` 的控制平面兼容，这意味着 CNI 和控制平面可以按任何顺序升级，只要它们的版本差异在一个小版本以内。

## Operating clusters with the CNI node agent installed
## 操作安装了 CNI 节点代理的集群

### Upgrading
### 升级

When upgrading Istio with [in-place upgrade](/docs/setup/upgrade/in-place/), the CNI component can be upgraded together with the control plane using one `IstioOperator` resource.
使用 [就地升级](/docs/setup/upgrade/in-place/) 升级 Istio 时，可以使用一个 `IstioOperator` 资源将 CNI 组件与控制平面一起升级。

When upgrading Istio with [canary upgrade](/docs/setup/upgrade/canary/), because the CNI component runs as a cluster singleton, it is recommended to operate and upgrade the CNI component separately from the revisioned control plane.
使用 [canary upgrade](/docs/setup/upgrade/canary/) 升级 Istio 时，由于 CNI 组件作为集群单例运行，因此建议与修订版的控制平面分开操作和升级 CNI 组件。

The following `IstioOperator` can be used to upgrade the CNI component independently.
下面的`IstioOperator`可用于独立升级CNI组件。

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

This is not a problem for Helm as the istio-cni is installed separately, and can be upgraded via Helm:
对于 Helm 来说这不是问题，因为 istio-cni 是单独安装的，并且可以通过 Helm 升级：

{{< text syntax=bash snip_id=cni_agent_helm_upgrade >}}
$ helm upgrade istio-cni istio/cni -n istio-system --wait
{{< /text >}}

### Race condition & mitigation
### 竞争条件和缓解

The Istio CNI DaemonSet installs the CNI network plugin on every node. However, a time gap exists between when the DaemonSet pod gets scheduled onto a node, and the CNI plugin is installed and ready to be used. There is a chance that an application pod starts up during that time gap, and the `kubelet` has no knowledge of the Istio CNI plugin. The result is that the application pod comes up without Istio traffic redirection and bypasses Istio sidecar.
Istio CNI DaemonSet 在每个节点上安装 CNI 网络插件。但是，DaemonSet pod 被调度到节点上与 CNI 插件安装并准备使用之间存在时间间隔。应用程序 pod 有可能在此时间间隔内启动，而“kubelet”不知道 Istio CNI 插件。结果是应用程序 pod 在没有 Istio 流量重定向的情况下启动并绕过 Istio sidecar。

To mitigate the race between an application pod and the Istio CNI DaemonSet, an `istio-validation` init container is added as part of the sidecar injection, which detects if traffic redirection is set up correctly, and blocks the pod starting up if not. The CNI DaemonSet will detect and handle any pod stuck in such state; how the pod is handled is dependent on configuration described below. This mitigation is enabled by default and can be turned off by setting `values.cni.repair.enabled` to false.
为了缓解应用程序 pod 和 Istio CNI DaemonSet 之间的竞争，在 sidecar 注入过程中添加了一个 `istio-validation` init 容器，用于检测流量重定向是否设置正确，如果设置不正确，则阻止 pod 启动。CNI DaemonSet 将检测并处理任何卡在这种状态的 pod；如何处理 pod 取决于下面描述的配置。此缓解措施默认启用，可以通过将 `values.cni.repair.enabled` 设置为 false 来关闭。

This repair capability can be further configured with different RBAC permissions to help mitigate the theoretical attack vector detailed in [`ISTIO-SECURITY-2023-005`](/news/security/istio-security-2023-005/).  By setting the below fields to true/false as required, you can select the Kubernetes RBAC permissions granted to the Istio CNI.
此修复功能可以进一步配置不同的 RBAC 权限，以帮助缓解 [`ISTIO-SECURITY-2023-005`](/news/security/istio-security-2023-005/) 中详述的理论攻击媒介。通过根据需要将以下字段设置为 true/false，您可以选择授予 Istio CNI 的 Kubernetes RBAC 权限。

|Configuration                    | Roles       | Behavior on Error                                                                                                                           | Notes
|---------------------------------|-------------|-----------------------------------------------------------------------------------------------------------------------------------------------|-------
|`values.cni.repair.deletePods`   | DELETE pods | Pods are deleted, when rescheduled they will have the correct configuration.                                                                  | Default in 1.20 and older
|`values.cni.repair.labelPods`    | UPDATE pods | Pods are only labeled.  User will need to take manual action to resolve.                                                                      |
|`values.cni.repair.repairPods`   | None        | Pods are dynamically reconfigured to have appropriate configuration. When the container restarts, the pod will continue normal execution.     | Default in 1.21 and newer
| 配置                    | 角色       | 错误时的行为                                                                                                                           | 备注
|---------------------------------|-------------|-----------------------------------------------------------------------------------------------------------------------------------------------|-------
|`values.cni.repair.deletePods`   | 删除 pod | Pod 被删除后，重新安排时它们将具有正确的配置。                                                                  | 1.20 及以上版本的默认设置
|`values.cni.repair.labelPods`    | 更新 pod | Pod 仅带有标签。用户需要采取手动措施来解决。                                                                      |
|`values.cni.repair.repairPods`   | 无        | Pod 会动态地重新配置以获得适当的配置。当容器重新启动时，Pod 将继续正常执行。     | 1.21 及更高版本中的默认设置

### Traffic redirection parameters
### 流量重定向参数

To redirect traffic in the application pod's network namespace to/from the Istio proxy sidecar, the Istio CNI plugin configures the namespace's iptables. You can adjust traffic redirection parameters using the same pod annotations as normal, such as ports and IP ranges to be included or excluded from redirection. See [resource annotations](/docs/reference/config/annotations) for available parameters.
为了将应用程序 pod 网络命名空间中的流量重定向到 Istio 代理 sidecar 或从 Istio 代理 sidecar 重定向，Istio CNI 插件会配置命名空间的 iptables。您可以使用与平常相同的 pod 注释来调整流量重定向参数，例如要包含或排除在重定向中的端口和 IP 范围。有关可用参数，请参阅 [资源注释](/docs/reference/config/annotations)。

### Compatibility with application init containers
### 与应用程序初始化容器的兼容性

The Istio CNI plugin may cause networking connectivity problems for any application init containers in sidecar data plane mode. When using Istio CNI, `kubelet` starts a pod with the following steps:
Istio CNI 插件可能会导致任何处于 sidecar 数据平面模式的应用程序初始化容器出现网络连接问题。使用 Istio CNI 时，“kubelet”会按照以下步骤启动 pod：

1. The default interface CNI plugin sets up pod network interfaces and assigns pod IPs.
1. The Istio CNI plugin sets up traffic redirection to the Istio sidecar proxy within the pod.
1. All init containers execute and complete successfully.
1. The Istio sidecar proxy starts in the pod along with the pod's other containers.
1. 默认接口 CNI 插件设置 pod 网络接口并分配 pod IP。
1. Istio CNI 插件设置到 pod 内的 Istio sidecar 代理的流量重定向。
1. 所有 init 容器均成功执行并完成。
1. Istio sidecar 代理与 pod 的其他容器一起在 pod 中启动。

Init containers execute before the sidecar proxy starts, which can result in traffic loss during their execution. Avoid this traffic loss with one of the following settings:
Init 容器在 Sidecar 代理启动之前执行，这可能会导致其执行期间出现流量丢失。请使用以下设置之一来避免这种流量丢失：

1. Set the `uid` of the init container to `1337` using `runAsUser`. `1337` is the [`uid` used by the sidecar proxy](/docs/ops/deployment/application-requirements/#pod-requirements). Traffic sent by this `uid` is not captured by the Istio's `iptables` rule. Application container traffic will still be captured as usual.
1. 使用 `runAsUser` 将 init 容器的 `uid` 设置为 `1337`。`1337` 是 [sidecar 代理使用的 `uid`](/docs/ops/deployment/application-requirements/#pod-requirements)。此 `uid` 发送的流量不会被 Istio 的 `iptables` 规则捕获。应用程序容器流量仍将照常被捕获。
1. Set the `traffic.sidecar.istio.io/excludeOutboundIPRanges` annotation to disable redirecting traffic to any CIDRs the init containers communicate with.
1. 设置 `traffic.sidecar.istio.io/excludeOutboundIPRanges` 注释以禁止将流量重定向到 init 容器与之通信的任何 CIDR。
1. Set the `traffic.sidecar.istio.io/excludeOutboundPorts` annotation to disable redirecting traffic to the specific outbound ports the init containers use.
1. 设置 `traffic.sidecar.istio.io/excludeOutboundPorts` 注释以禁用将流量重定向到 init 容器使用的特定出站端口。

{{< tip >}}
You must use the `runAsUser 1337` workaround if [DNS proxying](/docs/ops/configuration/traffic-management/dns-proxy/) is enabled, and an init container sends traffic to a host name which requires DNS resolution.
如果启用了 [DNS 代理](/docs/ops/configuration/traffic-management/dns-proxy/)，并且 init 容器将流量发送到需要 DNS 解析的主机名，则必须使用 `runAsUser 1337` 解决方法。
{{< /tip >}}

{{< tip >}}
Some platforms (e.g. OpenShift) do not use `1337` as the sidecar `uid` and instead use a pseudo-random number, that is only known at runtime. In such cases, you can instruct the proxy to run as a predefined `uid` by leveraging the [custom injection feature](/docs/setup/additional-setup/sidecar-injection/#customizing-injection), and use that same `uid` for the init container.
某些平台（例如 OpenShift）不使用“1337”作为 sidecar“uid”，而是使用仅在运行时才知道的伪随机数。在这种情况下，您可以利用 [自定义注入功能](/docs/setup/additional-setup/sidecar-injection/#customizing-injection) 指示代理以预定义的“uid”运行，并将相同的“uid”用于 init 容器。
{{< /tip >}}

{{< warning >}}
Please use traffic capture exclusions with caution, since the IP/port exclusion annotations not only apply to init container traffic, but also application container traffic. i.e. application traffic sent to the configured IP/port will bypass the Istio sidecar.
请谨慎使用流量捕获排除，因为 IP /端口排除注释不仅适用于初始化容器流量，也适用于应用程序容器流量。即发送到配置的 IP /端口的应用程序流量将绕过 Istio sidecar。
{{< /warning >}}

### Compatibility with other CNIs
### 与其他 CNI 的兼容性

The Istio CNI plugin follows the [CNI spec](https://www.cni.dev/docs/spec/#container-network-interface-cni-specification), and should be compatible with any CNI, container runtime, or other plugin that also follows the spec.
Istio CNI 插件遵循 [CNI 规范](https://www.cni.dev/docs/spec/#container-network-interface-cni-specification)，并且应该与任何遵循该规范的 CNI、容器运行时或其他插件兼容。

The Istio CNI plugin operates as a chained CNI plugin. This means its configuration is appended to the list of existing CNI plugins configurations. See the [CNI specification reference](https://www.cni.dev/docs/spec/#section-1-network-configuration-format) for further details.
Istio CNI 插件以链式 CNI 插件的形式运行。这意味着其配置将附加到现有 CNI 插件配置列表中。有关更多详细信息，请参阅 [CNI 规范参考](https://www.cni.dev/docs/spec/#section-1-network-configuration-format)。

When a pod is created or deleted, the container runtime invokes each plugin in the list in order.
当创建或删除 pod 时，容器运行时会按顺序调用列表中的每个插件。

The Istio CNI plugin performs actions to set up the application pod's traffic redirection - in the sidecar data plane mode, this means applying `iptables` rules in the pod's network namespace to redirect in-pod traffic to the injected Istio proxy sidecar.
Istio CNI 插件执行操作来设置应用程序 pod 的流量重定向 - 在 sidecar 数据平面模式下，这意味着在 pod 的网络命名空间中应用“iptables”规则以将 pod 内的流量重定向到注入的 Istio 代理 sidecar。
