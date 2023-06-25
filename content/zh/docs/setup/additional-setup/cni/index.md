---
title: 安装 Istio CNI 插件
description: 安装并使用 Istio CNI 插件，可以让运维人员用更低的权限来部署服务。
weight: 70
aliases:
    - /zh/docs/setup/kubernetes/install/cni
    - /zh/docs/setup/kubernetes/additional-setup/cni
keywords: [cni]
owner: istio/wg-networking-maintainers
test: yes
---

按照此流程利用 Istio 容器网络接口（[CNI](https://github.com/containernetworking/cni#cni---the-container-network-interface)）来安装、配置和使用 Istio 网格。

默认情况下，Istio 会在网格中部署的 Pod 上注入一个 `initContainer`：`istio-init`。
`istio-init` 容器会将 Pod 的网络流量劫持到 Istio Sidecar 代理上。
这需要用户或部署 Pod 的 Service Account 具有足够的部署
[`NET_ADMIN` 容器](https://kubernetes.io/zh-cn/docs/tasks/configure-pod-container/security-context/#set-capabilities-for-a-container)的 Kubernetes RBAC 权限。
Istio 用户权限的提升，对于某些组织的安全政策来说，可能是难以接受的。
Istio CNI 插件就是一个能够替代 `istio-init` 容器来实现相同的网络功能但却不需要 Istio 用户申请额外的 Kubernetes RBAC 授权的方案。

Istio CNI 插件会在 Kubernetes Pod 生命周期的网络设置阶段完成 Istio 网格的 Pod 流量转发设置工作，
因此用户在部署 Pod 到 Istio 网格中时，不再需要配置 [`NET_ADMIN` 功能需求](/zh/docs/ops/deployment/requirements/)了。
Istio CNI 插件代替了 `istio-init` 容器所实现的功能。

{{< tip >}}
注意: Istio CNI 插件作为一个链接的 CNI 插件运行，它被设计为与另一个 CNI 插件一起使用，
如 [PTP](https://www.cni.dev/plugins/current/main/ptp/) 或 [Calico](https://docs.projectcalico.org)。
详情请参见[与其他CNI插件的兼容性](#compatibility-with-other-cni-plugins)。
{{< /tip >}}

## 安装 CNI {#install-cni}

### 前提条件 {#prerequisites}

1. 安装支持 CNI 的 Kubernetes 集群，并且 `kubelet` 使用 `--network-plugin=cni` 参数启用
    [CNI](https://github.com/containernetworking/cni) 插件。
    * AWS EKS、Azure AKS 和 IBM Cloud IKS 集群具备这一功能。
    * Google Cloud GKE 集群只需启用以下特性之一，就可以启用 CNI：
    [network policy](https://cloud.google.com/kubernetes-engine/docs/how-to/network-policy)、
    [intranode visibility](https://cloud.google.com/kubernetes-engine/docs/how-to/intranode-visibility)、
    [workload identity](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity)、
    [pod security policy](https://cloud.google.com/kubernetes-engine/docs/how-to/pod-security-policies#overview)、
    [dataplane v2](https://cloud.google.com/kubernetes-engine/docs/concepts/dataplane-v2)。
    * OpenShift 默认启用了 CNI。

1. Kubernetes 需要启用 [ServiceAccount 准入控制器](https://kubernetes.io/zh-cn/docs/reference/access-authn-authz/admission-controllers/#serviceaccount)。
    * Kubernetes 文档中强烈建议所有使用 `ServiceAccounts` 的 Kubernetes 安装实例都启用该控制器。

### 用 CNI 插件安装 Istio {#install-istio-with-cni-plugin}

在大多数环境中，可以使用以下配置安装基础的 Istio 集群并启用 CNI：

{{< tabset category-name="gateway-install-type" >}}

{{< tab name="IstioOperator" category-value="iop" >}}

{{< text bash >}}
$ cat <<EOF > istio-cni.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  components:
    cni:
      enabled: true
EOF
$ istioctl install -f istio-cni.yaml -y
{{< /text >}}

{{< /tab >}}

{{< tab name="Helm" category-value="helm" >}}

{{< text bash >}}
$ helm install istio-cni istio/cni -n kube-system --wait
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

这将部署 `istio-cni-node` DaemonSet 到集群中，将 Istio CNI 插件可执行文件安装到每个节点上并为此插件设置必要的配置。
CNI DaemonSet 使用 [`system-node-critical`](https://kubernetes.io/zh-cn/docs/tasks/administer-cluster/guaranteed-scheduling-critical-addon-pods/) `PriorityClass` 来运行。

{{< image width="60%" link="./cni.svg" caption="Istio CNI" >}}

有几个常用的安装选项：

* `components.cni.namespace=kube-system` 配置命名空间以安装 CNI DaemonSet。
* `values.cni.cniBinDir` 和 `values.cni.cniConfDir` 配置安装插件可执行文件的目录路径并创建插件配置。
* `values.cni.cniConfFileName` 配置插件配置文件的名称。
* `values.cni.chained` 控制是否将插件配置为链式的 CNI 插件。

{{< tip >}}
在一个节点变得可调度和 Istio CNI 插件在该节点上准备就绪之间存在某个时间间隔。
如果应用 Pod 在此期间启动，则流量重定向可能会被不正确地设置，且流量可能绕过 Istio Sidecar。
这种竞争条件通过“检测和修复”方法得到缓解。
请查阅[竞争条件和缓解措施](#race-condition-mitigation)一节以了解此缓解措施的影响。
{{< /tip >}}

### 通过 Helm 安装 {#installing-with-helm}

{{< text bash >}}
$  helm install istiod istio/istiod -n istio-system --set values.istio_cni.enabled=true --wait
{{< /text >}}

Istio CNI 和 Istio Discovery Chart 使用不同的值，需要您在安装 `istiod` Chart 时，
在重载值文件或命令提示符中设置以下内容来管理网络注解的同时关联 CNI 插件：

* `values.istio_cni.enabled` 应设置为与 `values.cni.enabled` 相同的值。

* `values.istio_cni.chained` 应设置为与 `values.cni.chained` 相同的值。

例如：

{{< text bash >}}
$  helm install istiod istio/istiod -n istio-system --set values.istio_cni.enabled=true --wait
{{< /text >}}

### 托管 Kubernetes 设置 {#hosted-Kubernetes-settings}

`istio-cni` 插件预期可用于任何使用 CNI 插件的托管 Kubernetes 版本。
默认的安装配置适用于大多数平台。某些平台需要特殊的安装设置。

{{< tabset category-name="cni-platform" >}}

{{< tab name="Google Kubernetes Engine" category-value="gke" >}}

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  components:
    cni:
      enabled: true
      namespace: kube-system
  values:
    cni:
      cniBinDir: /home/kubernetes/bin
{{< /text >}}

{{< /tab >}}

{{< tab name="Red Hat OpenShift 4.2+" category-value="ocp" >}}

{{< text bash >}}
$ istioctl install --set profile=openshift
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

## 操作细节 {#operation-details}

### 升级 {#upgrade}

当使用[原地升级](/zh/docs/setup/upgrade/in-place/)来升级 Istio 时，
CNI 组件可以使用一个 `IstioOperator` 资源与控制平面一起升级。

使用[金丝雀升级](/zh/docs/setup/upgrade/canary/)升级 Istio 时，
由于 CNI 组件以集群单例运行，建议将 CNI 组件与改版后的控制平面分开运行和升级。
下面的 `IstioOperator` 可用于独立操作 CNI 组件。

这对 Helm 而言不是问题，因为 istio-cni 是单独安装的。

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  profile: empty # Do not include other components
  components:
    cni:
      enabled: true
  values:
    cni:
      excludeNamespaces:
        - istio-system
        - kube-system
{{< /text >}}

在启用 CNI 组件的情况下安装修订的控制平面时，需要设置 `values.istio_cni.enabled`，
这样 Sidecar 注入程序就不会注入 `istio-init` 初始化容器。

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  revision: REVISION_NAME
  ...
  values:
    istio_cni:
      enabled: true
  ...
{{< /text >}}

`1.x` 版本的 CNI 插件兼容 `1.x-1`、`1.x` 和 `1.x+1` 版本的控制平面，
这意味着 CNI 和控制平面可以按任何顺序进行升级，只要它们的版本差异在一个次要版本之内。

### 竞争条件和缓解措施 {#race-condition-mitigation}

Istio CNI DaemonSet 在每个节点上安装 CNI 网络插件。
但是，在将 DaemonSet Pod 调度到一个节点上与 CNI 插件被安装好并准备就绪之间存在一个时间间隔。
应用 Pod 有可能在这个时间间隔内启动，而 `kubelet` 不了解 Istio CNI 插件。
结果应用 Pod 在没有 Istio 流量重定向的情况下启动并绕过了 Istio Sidecar。

为了缓解应用 Pod 和 Istio CNI DaemonSet 之间的竞争，添加了一个 `istio-validation` 初始化容器作为 Sidecar 注入的一部分。
该容器会检测流量重定向是否设置正确，如果不正确则阻止 Pod 启动。CNI DaemonSet 将检测并驱逐任何卡在这种状态下的 Pod。
当新的 Pod 启动时，它应该正确设置流量重定向。此缓解措施默认被启用，可以通过将 `values.cni.repair.enabled` 设置为 false 来关闭。

### 流量重定向参数 {#traffic-redirection-parameters}

为了将应用 Pod 的网络命名空间中的流量重定向至 Istio Sidecar，Istio CNI 插件配置了命名空间的 iptables。
您可以使用与正常情况相同的 Pod 注解来调整流量重定向参数，例如要包含或排除在重定向之外的端口和 IP 范围。
有关可用参数，请参阅[资源注解](/zh/docs/reference/config/annotations)。

### 和应用的初始化容器的兼容性 {#compatibility-with-application-init-containers}

Istio CNI 插件可能会导致与任何应用 `initContainers` 的网络连通性问题。
使用 Istio CNI 时，`kubelet` 会通过以下步骤启动一个注入的 Pod：

1. Istio CNI 插件在 Pod 内设置流量重定向到 Istio Sidecar。
1. 等待所有的初始化容器成功执行完毕。
1. Istio Sidecar 跟随 Pod 的其它容器一起启动。

初始化容器在 Sidecar 启动之前执行，这会导致在它们执行期间会有流量丢失。
可以用以下的一种或所有设置来防止流量丢失：

1. 使用 `runAsUser` 讲过初始化容器的 `uid` 设置为 `1337`。
  `1337` 是 [Sidecar 代理使用的 `uid`](/zh/docs/ops/deployment/requirements/#pod-requirements)。
   这个 `uid` 发送的流量并非通过 Istio 的 `iptables` 规则进行捕获。
   应用容器流量仍将像往常一样被捕获。
1. 设置 `traffic.sidecar.istio.io/excludeOutboundIPRanges` 注解来禁止重定向流量到任何与初始化容器有通信的 CIDR。
1. 设置 `traffic.sidecar.istio.io/excludeOutboundPorts` 注解来禁止重定向流量到初始化容器所用到的出站端口。

{{< tip >}}
如果启用了 [DNS 代理](/zh/docs/ops/configuration/traffic-management/dns-proxy/)，
您必须使用 `runAsUser 1337` 解决方法，并且初始化容器将流量发送到需要 DNS 解析的主机名。
{{< /tip >}}

{{< warning >}}
请谨慎使用流量捕获排除法，因为 IP/端口排除注解不仅适用于初始化容器流量，还适用于应用容器流量。
即发送到配置的 IP/端口的应用流量将绕过 Istio Sidecar。
{{< /warning >}}

### 和其它 CNI 插件的兼容性{#compatibility-with-other-CNI-plugins}

Istio CNI 插件维护着与当前需要 `NET_ADMIN` 和 `NET_RAW` 能力的 `istio-init` 容器相同的 CNI 插件集。

Istio CNI 插件作为一个链式 CNI 插件存在。也就是说它的配置会作为一个新的配置列表元素被加入到现存 CNI 插件配置中。
参考 [CNI 规范](https://github.com/containernetworking/cni/blob/master/SPEC.md#network-configuration-lists)中的更多细节。
当 Pod 被创建或删除时，容器运行时会按照列表顺序调用每个插件。Istio CNI 插件只会把应用 Pod 的流量重定向到
Sidecar 中（通过在 Pod 的网络命名空间中使用 `iptables` 完成）。

{{< warning >}}
Istio CNI 插件应该不会与设置 Pod 网络的基本 CNI 插件有冲突，但并不是所有的 CNI 插件都经过了验证。
{{< /warning >}}
