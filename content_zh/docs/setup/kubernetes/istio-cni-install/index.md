---
title: 安装 Istio CNI 
description: Istio CNI 插件的安装和使用，该插件让运维人员可以用较低的权限来完成网格服务的部署工作。
weight: 70
keywords: [kubernetes,cni,sidecar,proxy,network,helm]
---

缺省情况下，Istio 会在网格中部署的 Pod 上注入一个初始化容器——`istio-init`。这个初始化容器会将 Pod 网络的流量劫持到 Istio Sidecar 上。这需要用户或者向网格中部署 Pod 的 Service Account 具有部署 [`NET_ADMIN` 容器](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-capabilities-for-a-container)的授权。对 Istio 用户的这种授权需要，对于某些组织的安全政策来说，可能是无法接受的。Istio CNI（[容器网络接口](https://github.com/containernetworking/cni#cni---the-container-network-interface)）插件能够代替 `istio-init` 容器完成同样的网络功能，而且无需 Istio 用户额外申请 Kubernetes RBAC 授权。

[Istio CNI 插件](https://github.com/istio/cni)会在 Kubernetes Pod 生命周期的网络设置阶段完成 Istio 网格中的 Pod 流量转发设置工作，用户向网格中进行 Pod 部署时，不再有对 [`NET_ADMIN` 功能的需求](/docs/setup/kubernetes/spec-requirements/)。

## 前提条件 {#prerequisites}

1. 安装支持 CNI 的 Kubernetes 集群。并且 `kubelet` 使用 `--network-plugin=cni` 参数启用 [CNI](https://github.com/containernetworking/cni)插件。
    * AWS EKS、Azure AKS 以及 IBM Cloud IKS 集群具备这一功能。
    * Google Cloud GKE 集群需要启用[网络策略](https://cloud.google.com/kubernetes-engine/docs/how-to/network-policy)功能，让 Kubernetes 配置为 `network-plugin=cni`。

1. Kubernetes 集群需要启用 [ServiceAccount 准入控制器](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/#serviceaccount)。
    * Kubernetes 文档中强烈建议所有使用 `ServiceAccount` 的 Kubernetes 集群都应该启用该控制器。

## 安装 {#installation}

1. 获取 Kubernetes 环境 CNI 插件 `--cni-bin-dir` 以及 `--cni-conf-dir` 的设置。
    * [托管 Kubernetes 用法](#hosted-Kubernetes-usage)一节中的介绍了非缺省配置的介绍。

1. 在[使用 Helm 安装 Istio](/zh/docs/setup/kubernetes/helm-install/)的过程中，加入  `--set istio_cni.enabled=true` 的设置，来启用 Istio CNI 插件的安装。例如：

    {{< text bash >}}
    $ helm template install/kubernetes/helm/istio --name istio --namespace istio-system \
      --set istio_cni.enabled=true > $HOME/istio.yaml
    {{< /text >}}

    > 可以在 [`values.yaml`](https://github.com/istio/cni/blob/master/deployments/kubernetes/install/helm/istio-cni/values.yaml) 中获取 `istio-cni` 的完整参数

### 用例：排除特定的 Kubernetes 命名空间 {#example-excluding-specific-Kubernetes-namespaces}

下面的例子中对 Istio CNI 插件进行配置，忽略 `istio-system`、`foo_ns` 以及 `bar_ns` 命名空间中的 Pod：

1. 创建一个 Istio 清单文件，其中启用了 Istio CNI 插件，并覆盖了 `istio-cni` Helm Chart 的缺省配置中的 `logLevel` 以及 `excludeNamespaces` 参数：

    {{< text bash >}}
    $ helm template install/kubernetes/helm/istio --name istio --namespace istio-system \
    --set istio_cni.enabled=true \
    --set istio-cni.logLevel=info \
    --set istio-cni.excludeNamespaces={"istio-system,foo_ns,bar_ns"} > $HOME/istio.yaml
    {{< /text >}}

### Helm Chart 参数 {#helm-chart-parameter}

| 参数 | 值 | 缺省值 | 描述 |
|--------|--------|---------|-------------|
| `hub` | | | 用于拉取 `install-cni` 镜像的仓库地址。 |
| `tag` | | | 用于拉取 `install-cni` 镜像的标签。 |
| `logLevel` | `panic`, `fatal`, `error`, `warn`, `info`, `debug` | `warn` | CNI 的日志级别。 |
| `excludeNamespaces` | `[]string` | `[ istio-system ]` | 命名空间名称列表，列表内的命名空间会从 Istio Pod 检查中排除出去。|
| `cniBinDir` | | `/opt/cni/bin` | 必须和集群中的 `--cni-bin-dir` 取值一致（`kubelet` 参数）。|
| `cniConfDir` | | `/etc/cni/net.d` | 必须和集群中的 `--cni-conf-dir` 取值一致（`kubelet` 参数）。|
| `cniConfFileName` | | None | 如果不做设置，会查找 `cni-conf-dir` 中的第一个文件（和 `kubelet` 一样）。主要用于测试 `install-cni` 的插件配置。如果做了赋值，`install-cni` 会把插件配置注入到 `cni-conf-dir` 目录下的这个文件之中。|

### 托管 Kubernetes 的用法 {#hosted-Kubernetes-usage}

并非所有 Kubernetes 集群都会在 `kubelet` 配置中使用 CNI 插件的，因此 `istio-cni` 方案并非随处可用的。`istio-cni` 插件应该可用于任何支持 CNI 插件的托管 Kubernetes 集群。下表列出了多种常见 Kubernetes 中的 CNI 支持情况。

| 集群托管类型 | 是否 CNI | 是否需要非缺省配置 |
|---------------------|----------|-------------------------------|
| GKE 1.9+ default | N | |
| GKE 1.9+ w/[network-policy](https://cloud.google.com/kubernetes-engine/docs/how-to/network-policy) | Y | `istio-cni.cniBinDir=/home/kubernetes/bin` |
| IKS (IBM cloud) | Y | |
| EKS (AWS) | Y | |
| AKS (Azure) | Y | |
| Red Hat OpenShift 3.10+ | Y | |

#### GKE 配置 {#google-Kubernetes-engine-setup}

1. 参考[为 Istio 准备 GKE 集群](/zh/docs/setup/kubernetes/platform-setup/gke/)的内容，并启用[网络策略](https://cloud.google.com/kubernetes-engine/docs/how-to/network-policy)。
    * 注意：如果是现存集群，这一操作会重新部署 Node。

1. 在 Helm 中使用如下参数安装 Istio `--set istio_cni.enabled=true --set istio-cni.cniBinDir=/home/kubernetes/bin`

## Sidecar 注入的兼容性 {#sidecar-injection-compatibility}

在 Helm 安装过程中需要用 `istio_cni.enabled=true` 生成 `istio-sidecar-injector` Configmap，使用这一配置对 Kubernetes Pod 进行 Istio 注入才能够使用 Istio 的 CNI 插件。可参看 [Istio Sidecar 注入文档](/zh/docs/setup/kubernetes/sidecar-injection/)，获取更多 Sidecar 注入方面的详细内容。

下列注入方式都是可以支持 Istio CNI 插件的：

1. [自动注入 Sidecar](/zh/docs/setup/kubernetes/sidecar-injection/#sidecar-的自动注入)。
1. 使用 `istio-sidecar-injector` Configmap 进行手工注入。
    * 执行 `istioctl kube-inject`，直接使用 Configmap：

        {{< text bash >}}
        $ istioctl kube-inject -f deployment.yaml -o deployment-injected.yaml --injectConfigMapName istio-sidecar-injector
        $ kubectl apply -f deployment-injected.yaml
        {{< /text >}}

    * 从 Configmap 中获取配置文件，用于执行 `istioctl kube-inject`：

        {{< text bash >}}
        $ kubectl -n istio-system get configmap istio-sidecar-injector -o=jsonpath='{.data.config}' > inject-config.yaml
        $ istioctl kube-inject -f deployment.yaml -o deployment-injected.yaml --injectConfigFile inject-config.yaml
        $ kubectl apply -f deployment-injected.yaml
        {{< /text >}}

## 操作细节 {#operational-details}

Istio CNI 插件会监听 Kubernetes Pod 的创建和删除事件，并作出如下动作：

1. 通过 Istio Sidecar 识别用户应用 Pod 的流量是否需要重定向。

1. 对 Pod 网络命名空间进行配置，将流量转向 Istio Sidecar。

### 识别 Pod 是否需要流量重定向 {#identifying-pods-requiring-traffic-redirection}

Istio CNI 插件会检查 Pod 是否符合下列要求，如果符合，就把业务 Pod 的流量交由 Sidecar 处理：

1. Pod 所在命名空间没有在 `exclude_namespaces` 中列出。
1. Pod 中有一个名为 `istio-proxy` 的容器。
1. Pod 中的容器不止一个。
1. Pod 的注解中不包含 `sidecar.istio.io/inject`，或者 `sidecar.istio.io/inject` 注解的值为 `true`。

### 流量重定向的细节 {#traffic-redirection-details}

Istio CNI 插件会配置应用 Pod 的网络命名空间，把流量重定向给 Istio Sidecar 处理。下面的表格中描述了重定向功能的参数。可以通过同名的 Pod 注解来修改这些参数的缺省值。

| 注解名称 | 值 | 缺省 | 描述 |
|----------------|--------|---------|-------------|
| `sidecar.istio.io/interceptionMode`| `REDIRECT`, `TPROXY` | `REDIRECT` | Iptables 的重定向模式。 |
| `traffic.sidecar.istio.io/includeOutboundIPRanges` | `<IPCidr1>,<IPCidr2>,...` | `*` | 可选项，逗号分隔的 CIDR 列表，列表范围内的 IP 地址才会发生重定向。缺省值为 `*`，会对所有流量进行重定向。|
| `traffic.sidecar.istio.io/excludeOutboundIPRanges` | `<IPCidr1>,<IPCidr2>,...` | | 可选项，逗号分隔的 CIDR 列表，范围内的 IP 不会进行重定向，该选项仅在 `includeOutboundIPRanges` 取值为 `*` 的情况下生效。|
| `traffic.sidecar.istio.io/includeInboundPorts` | `<port1>,<port2>,...` | Pod 的 `containerPorts` 列表 | 逗号分隔的监听端口列表，这些流量会被重定向到 Sidecar，`*` 会重定向所有端口。|
| `traffic.sidecar.istio.io/excludeInboundPorts` | `<port1>,<port2>,...` | | 逗号分隔的监听端口列表，列表中的端口会被不会被重定向到 Istio Sidecar 中。仅在 `includeInboundPorts` 为 `*` 的时候生效。 |

### 日志 {#logging}

Istio CNI 插件在容器运行时的进程空间内运行，因此日志条目会加入到 `kubelet` 进程中。

## 和其它 CNI 插件的兼容性 {#compatibility-with-other-plug-in-s}

Istio CNI 插件的兼容性和当前的 `NET_ADMIN` `istio-init` 容器是一样的。

Istio CNI 插件作为一个链式 CNI 插件存在。也就是说它的配置会作为一个新的配置列表元素被加入到现存 CNI 插件配置中。
[CNI 规范参考](https://github.com/containernetworking/cni/blob/master/SPEC.md#network-configuration-lists)中介绍了这方面的更多细节。
当 Pod 被创建或删除时，容器运行时会按照列表顺序调用每个插件。Istio CNI 插件只会把应用 Pod 的流量重定向到 Sidecar 中（在 Pod 的网络命名空间中使用 `iptables` 完成）。

{{< warning_icon >}} 这种操作对设置 Pod 网络的基本 CNI 插件**应该**是没有影响的，但是并没有针对所有 CNI 进行验证。
