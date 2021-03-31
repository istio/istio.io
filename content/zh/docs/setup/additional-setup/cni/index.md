---
title: 安装 Istio CNI 插件
description: 安装并使用 Istio CNI 插件，可以让运维人员用更低的权限来部署服务。
weight: 70
aliases:
    - /zh/docs/setup/kubernetes/install/cni
    - /zh/docs/setup/kubernetes/additional-setup/cni
keywords: [kubernetes,cni,sidecar,proxy,network,helm]
owner: istio/wg-environments-maintainers
test: no

按照此流程利用 Istio 容器网络接口（[CNI](https://github.com/containernetworking/cni#cni---the-container-network-interface)）来安装、配置和使用 Istio 网格。

默认情况下，Istio 会在网格中部署的 pods 上注入一个 `initContainer`：`istio-init`。
`istio-init` 容器会将 pod 的网络流量劫持到 Istio sidecar 代理上。
这需要用户或部署 pods 的 Service Account 具有足够的部署
[`NET_ADMIN` 容器](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-capabilities-for-a-container)的 Kubernetes RBAC 权限。
Istio 用户权限的提升，对于某些组织的安全政策来说，可能是难以接受的。
Istio CNI 插件就是一个能够替代 `istio-init` 容器来实现相同的网络功能但却不需要 Istio 用户申请额外的 Kubernetes RBAC 授权的方案。

Istio CNI 插件会在 Kubernetes pod 生命周期的网络设置阶段完成 Istio 网格的 pod 流量转发设置工作，因此用户在部署 pods 到 Istio 网格中时，不再需要配置 [`NET_ADMIN` 功能需求](/zh/docs/ops/deployment/requirements/)了。
Istio CNI 插件代替了 `istio-init` 容器所实现的功能。

## 前提条件{#prerequisites}

1. 安装支持 CNI 的 Kubernetes 集群，并且 `kubelet` 使用 `--network-plugin=cni` 参数启用 [CNI](https://github.com/containernetworking/cni) 插件。
    * AWS EKS、Azure AKS 和 IBM Cloud IKS 集群具备这一功能。
    * Google Cloud GKE 集群需要启用[网络策略](https://cloud.google.com/kubernetes-engine/docs/how-to/network-policy)功能，以让 Kubernetes 配置为 `network-plugin=cni`。
    * OpenShift 默认启用了 CNI。

1. Kubernetes 需要启用 [ServiceAccount 准入控制器](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/#serviceaccount)。
    * Kubernetes 文档中强烈建议所有使用 `ServiceAccounts` 的 Kubernetes 安装实例都启用该控制器。

## 基础安装{#basic-installation}

在大多数的环境下，启动 CNI 的基础 Istio 集群可以采用以下命令进行安装：

{{< text bash >}}
$ cat <<EOF > istio-cni.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  components:
    cni:
      enabled: true
  values:
    cni:
      excludeNamespaces:
       - istio-system
       - kube-system
      logLevel: info
EOF
$ istioctl install -f istio-cni.yaml
{{< /text >}}

## 高级安装{#advanced-installation}

1. 确认 Kubernetes 环境的 CNI 插件的 `--cni-bin-dir` 和 `--cni-conf-dir` 设置。
    任何非默认设置都需要参考[托管 Kubernetes 设置](#hosted-Kubernetes-settings)。

1. 使用 `istioctl` 安装 Istio CNI 和 Istio。
    参考 [Istio 安装](/zh/docs/setup/install/istioctl/)的说明并设置 `--set components.cni.enabled=true`选项。
    在上一步中，如果 `istio-cni` 不是按照默认设置安装的，还需要设置 `--set values.cni.cniBinDir=...` 和 `--set values.cni.cniConfDir=...` 选项。
    

### Helm chart 参数{#helm-chart-parameters}

下表列出了 `istio-cni` 支持的所有配置项：

| 选项 | 取值 | 默认值 | 描述 |
|--------|--------|---------|-------------|
| `hub` | | | 用于拉取 `install-cni` 镜像的仓库地址。 |
| `tag` | | | 用于拉取 `install-cni` 镜像的标签。 |
| `pullPolicy` | | `Always` | `install-cni` 镜像的拉取策略。 |
| `logLevel` | `panic`, `fatal`, `error`, `warn`, `info`, `debug` | `warn` | CNI 程序的日志级别。 |
| `excludeNamespaces` | `[]string` | `[ istio-system ]` | 排除 Istio pod 检查的命名空间列表。 |
| `cniBinDir` | | `/opt/cni/bin` | 必须与集群中的 `--cni-bin-dir`（`kubelet` 参数）值一样。 |
| `cniConfDir` | | `/etc/cni/net.d` | 必须与集群中的 `--cni-conf-dir`（`kubelet` 参数）值一样。 |
| `cniConfFileName` | | | 不设置会自动查找 `cni-conf-dir` 目录的第一个文件（与 `kubelet` 一致）。主要用来测试 `install-cni` 的插件配置。如果设置了，`install-cni` 将会把插件配置注入到 `cni-conf-dir` 目录的该文件里面。 |
| `psp_cluster_role` | | | 该值指的是一个 `ClusterRole` 并被用于在 `istio-cni` 的命名空间中创建一个 `RoleBinding`。当您使用 [Pod 安全策略](https://kubernetes.io/docs/concepts/policy/pod-security-policy)并且希望让 `istio-cni` 作为 `priviliged` Pods 运行时，这会非常有用。 |
| `podAnnotations` | | `{}` | pod 级别自定义的附加注解。 |
| `repair.enabled` | `boolean` | `true` | 启用或禁用 [CNI Race Condition](https://github.com/istio/istio/issues/14327) 的探测及修复功能。这会将 `istio-validation`  启动容器注入到每一个被注入的 pod 中用于检查 Istio CNI 是否正确初始化了 pod 的网络配置。这同时也在 CNI `DaemonSet` 中启用了一个新的容器用于监控 pods 并按照下列的数值打上标签或将其删除。|
| `repair.hub` | | | 拉取修复容器的 `install-cni` 镜像的镜像仓库地址。默认情况下与 `hub` 相同。|
| `repair.tag` | | | 用于拉取修复容器的容器标签。默认情况下与 `tag` 相同。|
| `repair.initContainerName` | | `istio-validation` | 使用非标准的 pod 注入配置时，被修复容器检查后的启动容器名称的重载。|
| `repair.labelPods` | `boolean` | `true` | 启用修复控制器给监测到的未能初始化的 pod 打上标签。如果 `deletePods` 是 true 就忽略. |
| `repair.deletePods` | `boolean` | `true` | 启用修复控制器删除未能初始化的 pod 。这些 pod 将会被持续删除直到 CNI 正确地初始化。|
| `repair.brokenPodLabelKey` | | `cni.istio.io/uninitialized` | `labelPods` 是 true 时加入到 broken pods 的标签的键 . |
| `repair.brokenPodLabelValue` | | `true` |`labelPods` 是 true 时加入到 broken pods 的标签的值. |
| `chained` | `true` or `false` | `true` | 在 `cni-conf-dir` 中将配置文件部署为插件链 plugin chain 或独立文件。有些版本的 Kubernetes （比如 OpenShift）倾向于不支持链的方式，这种情况下设为 `false`。 |

这些选项可以在 `istioctl manifest` 命令中通过 `values.cni.<option-name>` 来访问，可以作为 `--set` 的参数，或者作为自定义覆盖文件中的相应路径。

### 排除特定的 Kubernetes 命名空间{#excluding-specific-Kubernetes-namespaces}

本例使用 `istioctl` 来执行以下任务：

* 安装 Istio CNI 插件。
* 配置其日志级别。
* 忽略以下命名空间中的 pods：
    * `istio-system`
    * `foo_ns`
    * `bar_ns`

参考[使用 `Istioctl` 进行自定义安装](/zh/docs/setup/install/istioctl/)中的完整说明。

使用以下命令来渲染并应用 Istio CNI 组件，并覆盖 `istio-cni` 的 `logLevel` 和 `excludeNamespaces` 参数的默认配置：

在本地用你的覆盖配置创建一个 `IstioOperator` CR yaml 来安装 `istio`, 例如 `cni.yaml` 

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  components:
    cni:
      enabled: true
  values:
    cni:
      excludeNamespaces:
       - istio-system
       - kube-system
       - foo_ns
       - bar_ns
      logLevel: info
{{< /text >}}

{{< text bash >}}
$ istioctl install -f cni.yaml
{{< /text >}}

### 托管 Kubernetes 设置{#hosted-Kubernetes-settings}

Istio CNI 方案并非普遍应用的。一些平台，尤其是托管 Kubernetes 环境，并不会在 `kubelet` 配置中启用 CNI 插件。
`istio-cni` 插件应该可用于任何支持 CNI 插件的托管 Kubernetes 集群。
下表列出了一些常见的 Kubernetes 环境中的所需要的设置。

| 集群托管类型 | 所需要的 Istio CNI 设置覆盖 | 所需要的 Platform 设置覆盖 |
|---------------------|--------------------------------------|-------------------------------------|
| GKE 1.9+ (详情见下面的 [GKE 设置](#google-Kubernetes-engine-setup)| `--set components.cni.namespace=kube-system --set values.cni.cniBinDir=/home/kubernetes/bin` | 启用[网络策略](https://cloud.google.com/kubernetes-engine/docs/how-to/network-policy) |
| IKS (IBM cloud) | _(无)_ | _(无)_ |
| EKS (AWS) | _(无)_ | _(无)_ |
| AKS (Azure) | _(无)_ | _(无)_ |
| Red Hat OpenShift 4.2+ | `--set components.cni.namespace=kube-system --set values.cni.cniBinDir=/var/lib/cni/bin --set values.cni.cniConfDir=/etc/cni/multus/net.d --set values.cni.chained=false --set values.cni.cniConfFileName="istio-cni.conf" --set values.sidecarInjectorWebhook.injectedAnnotations."k8s\.v1\.cni\.cncf\.io/networks"=istio-cni` | _(无)_ |

### GKE 设置{#google-Kubernetes-engine-setup}

1. 参考[为 Istio 准备 GKE 集群](/zh/docs/setup/platform-setup/gke/)的内容，并在集群中启用[网络策略](https://cloud.google.com/kubernetes-engine/docs/how-to/network-policy)。

    {{< warning >}}
    如果是现有集群，该操作将会重新部署所有节点。
    {{< /warning >}}

1. 用 `Istioctl` 安装 Istio CNI 包括 ` --set values.cni.cniBinDir=/home/kubernetes/bin` 选项。
例如，下列的 `istioctl manifest` 命令为 GKE 集群设置了 `values.cni.cniBinDir` 值：

{{< text bash >}}
    $ istioctl install --set values.cni.cniBinDir=/home/kubernetes/bin \
        --set components.cni.enabled=true \
        --set components.cni.namespace=kube-system
    {{< /text >}}


## Sidecar 注入的兼容性{#sidecar-injection-compatibility}

使用 Istio CNI 插件需要用 `istio_cni.enabled=true` 选项生成的 `istio-sidecar-injector` Configmap 对 Kubernetes Pod 的部署进行 Istio 注入。Sidecar 注入方面的详细内容请参考 [Istio Sidecar 注入文档](/zh/docs/setup/additional-setup/sidecar-injection/)。

下列的 sidecar 注入方式都是可以支持 Istio CNI 插件的：

1. [sidecar 自动注入](/zh/docs/setup/additional-setup/sidecar-injection/#automatic-sidecar-injection)
1. 使用 `istio-sidecar-injector` configmap 进行 sidecar 手动注入
    1. 直接使用 configmap 执行 [`istioctl kube-inject`](/zh/docs/reference/commands/istioctl/#istioctl-kube-inject) ：

        {{< text bash >}}
        $ istioctl kube-inject -f deployment.yaml -o deployment-injected.yaml --injectConfigMapName istio-sidecar-injector
        $ kubectl apply -f deployment-injected.yaml
        {{< /text >}}

    1. 用 configmap 创建的文件执行 `istioctl kube-inject`：

        {{< text bash >}}
        $ kubectl -n istio-system get configmap istio-sidecar-injector -o=jsonpath='{.data.config}' > inject-config.yaml
        $ istioctl kube-inject -f deployment.yaml -o deployment-injected.yaml --injectConfigFile inject-config.yaml
        $ kubectl apply -f deployment-injected.yaml
        {{< /text >}}

## 操作细节{#operational-details}

Istio CNI 插件会处理 Kubernetes Pod 的创建和删除事件，并作出如下动作：

1. 通过 Istio sidecars 识别 Istio 用户应用 pods 是否需要流量重定向
1. 对 pod 网络命名空间进行配置，将流量转向 Istio sidecar

### 识别 Pod 是否需要流量重定向{#identifying-pods-requiring-traffic-redirection}

Istio CNI 插件会通过检查 Pod 是否符合下列要求来判断是否需要把业务 Pod 的流量交由 Sidecar 处理：

1. Pod 所在 Kubernetes 命名空间没在 `exclude_namespaces` 配置中列出。
1. Pod 中有一个名为 `istio-proxy` 的容器。
1. Pod 中的容器不止一个。
1. Pod 的注解不包含 `sidecar.istio.io/inject` 或其值为 `true`。

### 流量重定向参数{#traffic-redirection-parameters}

为了将应用 pod 的网络命名空间中的流量重定向至 Istio sidecar，Istio CNI 插件配置了命名空间的 iptables。
下表描述了重定向功能的参数。通过设置应用 pod 的注解来覆盖相应的参数的默认值。

| 注解名 | 取值 | 默认值 | 描述 |
|----------------|--------|---------|-------------|
| `sidecar.istio.io/inject` | `true`, `false` | `true` | 表示是否要注入 Istio sidecar。如果设置为 `false`，Istio CNI 插件将不会为这个 pod 配置命名空间的 iptables。 |
| `sidecar.istio.io/status` | | | 由 Istio 的 sidecar 注入所创建的注解。如果没有，Istio CNI 插件将不会配置该 pod 命名空间的 iptables。 |
| `sidecar.istio.io/interceptionMode` | `REDIRECT`, `TPROXY` | `REDIRECT` | 所用的 iptables 重定向模式。 |
| `traffic.sidecar.istio.io/includeOutboundIPRanges` | `<IPCidr1>,<IPCidr2>,...` | `"*"` | 逗号分隔的 CIDR 列表，列表范围内的 IP 地址才会发生重定向。默认值为 `"*"`，会对所有流量进行重定向。 |
| `traffic.sidecar.istio.io/excludeOutboundIPRanges` | `<IPCidr1>,<IPCidr2>,...` | | 逗号分隔的 CIDR 列表，范围内的 IP 不会进行重定向。该选项仅在 `includeOutboundIPRanges` 取值为 `"*"` 时生效。 |
| `traffic.sidecar.istio.io/includeInboundPorts` | `<port1>,<port2>,...` | Pod 的 `containerPorts` 列表 | 逗号分隔的入站端口列表，这些流量会被重定向到 Sidecar，取值为 `"*"` 时会重定向所有端口。 |
| `traffic.sidecar.istio.io/excludeInboundPorts` | `<port1>,<port2>,...` | | 逗号分隔的入站端口列表，列表中的端口不会被重定向到 Istio Sidecar 中。仅在 `includeInboundPorts` 取值为 `"*"` 时生效。 |
| `traffic.sidecar.istio.io/excludeOutboundPorts` | `<port1>,<port2>,...` | | 逗号分隔的出站端口列表，列表中的端口流量不会重定向到 Envoy 中。 |
| `traffic.sidecar.istio.io/kubevirtInterfaces` | `<ethX>,<ethY>,...` | | 逗号分隔的虚拟接口列表，列表中的虚拟接口的入站流量（来自 VM）将被当作出站流量。 |

### 日志{#logging}

Istio CNI 插件在容器运行时的进程空间内运行。因此 `kubelet` 进程会将插件的日志记到它的日志中。

### 和应用的初始化容器的兼容性{#compatibility-with-application-init-containers}

Istio CNI 插件可能会导致与应用 `initContainers` 的网络连通性。
使用 Istio CNI 时，`kubelet` 会通过以下步骤启动一个注入的 pod：

1. Istio CNI 插件在 pod 内设置流量重定向到 Istio sidecar 代理。
1. 等待所有的初始化容器成功执行完毕。
1. Istio sidecar 代理跟随 pod 的其它容器一起启动。

初始化容器在 sidecar 代理启动之前执行，这会导致在它们执行期间会有流量丢失。
可以用以下的一种或所有设置来防止流量丢失：

* 设置 `traffic.sidecar.istio.io/excludeOutboundIPRanges` 注解来禁止重定向流量到任何与初始化容器有通信的 CIDRs。
* 设置 `traffic.sidecar.istio.io/excludeOutboundPorts` 注解来禁止重定向流量到初始化容器所用到的出站端口。

### 和其它 CNI 插件的兼容性{#compatibility-with-other-CNI-plugins}

Istio CNI 插件维护着和当前的 `NET_ADMIN` `istio-init` 容器同样的兼容性。

Istio CNI 插件作为一个链式 CNI 插件存在。也就是说它的配置会作为一个新的配置列表元素被加入到现存 CNI 插件配置中。
参考 [CNI 规范参考](https://github.com/containernetworking/cni/blob/master/SPEC.md#network-configuration-lists)中的更多细节。
当 Pod 被创建或删除时，容器运行时会按照列表顺序调用每个插件。Istio CNI 插件只会把应用 Pod 的流量重定向到 Sidecar 代理中（通过在 Pod 的网络命名空间中使用 `iptables` 完成）。

{{< warning >}}
虽然不是所有的 CNI 插件都经过了验证，但 Istio CNI 插件应该不会与设置 Pod 网络的基本 CNI 插件有冲突。
{{< /warning >}}
