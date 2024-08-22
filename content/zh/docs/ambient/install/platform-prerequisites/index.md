---
title: 平台特定先决条件
description: 在 Ambient 模式下安装 Istio 的平台特定先决条件。
weight: 2
aliases:
  - /zh/docs/ops/ambient/install/platform-prerequisites
  - /zh/latest/docs/ops/ambient/install/platform-prerequisites
owner: istio/wg-environments-maintainers
test: no
---

本文档涵盖了在 Ambient 模式下安装 Istio 的任何平台或环境特定的先决条件。

## 平台 {#platform}

某些 Kubernetes 环境需要您设置各种 Istio 配置选项来支持它们。

### Google Kubernetes Engine（GKE） {#google-kubernetes-engine-gke}

在 GKE 上，具有 [system-node-critical](https://kubernetes.io/zh-cn/docs/tasks/administer-cluster/guaranteed-scheduling-critical-addon-pods/)
`priorityClassName` 的 Istio 组件只能安装在定义了 [ResourceQuota](https://kubernetes.io/zh-cn/docs/concepts/policy/resource-quotas/)
的命名空间中。默认情况下，在 GKE 中，只有 `kube-system` 为 `node-critical` 类定义了 ResourceQuota。
Istio CNI 节点代理和 `ztunnel` 都需要 `node-critical` 类，因此在 GKE 中，两个组件都必须满足以下任一条件：

- 安装到 `kube-system`（**不是** `istio-system`）
- 安装到另一个已手动创建 ResourceQuota 的命名空间（如 `istio-system`），例如：

{{< text syntax=yaml >}}
apiVersion: v1
kind: ResourceQuota
metadata:
  name: gcp-critical-pods
  namespace: istio-system
spec:
  hard:
    pods: 1000
  scopeSelector:
    matchExpressions:
    - operator: In
      scopeName: PriorityClass
      values:
      - system-node-critical
{{< /text >}}

### k3d {#k3d}

如果您将 [k3d](https://k3d.io/) 与默认 Flannel CNI 结合使用，
则必须在安装命令中附加一些值，因为 k3d 使用非标准位置来存储 CNI 配置和二进制文件。

1. 创建一个禁用 Traefik 的集群，以免与 Istio 的入口网关冲突：

    {{< text bash >}}
    $ k3d cluster create --api-port 6550 -p '9080:80@loadbalancer' -p '9443:443@loadbalancer' --agents 2 --k3s-arg '--disable=traefik@server:*'
    {{< /text >}}

1. 在安装 Istio 时设置 `cniConfDir` 和 `cniBinDir` 值。例如：

    {{< tabset category-name="install-method" >}}

    {{< tab name="Helm" category-value="helm" >}}

        {{< text syntax=bash >}}
        $ helm install istio-cni istio/cni -n istio-system --set profile=ambient --wait --set cniConfDir=/var/lib/rancher/k3s/agent/etc/cni/net.d --set cniBinDir=/bin
        {{< /text >}}

    {{< /tab >}}

    {{< tab name="istioctl" category-value="istioctl" >}}

        {{< text syntax=bash >}}
        $ istioctl install --set profile=ambient --set values.cni.cniConfDir=/var/lib/rancher/k3s/agent/etc/cni/net.d --set values.cni.cniBinDir=/bin
        {{< /text >}}

    {{< /tab >}}

    {{< /tabset >}}

### K3s {#k3s}

当使用 [K3s](https://k3s.io/) 及其捆绑的 CNI 之一时，
你必须在安装命令中附加一些值，因为 K3S 使用非标准位置来存放 CNI 配置和二进制文件。
根据 K3s 文档，这些非标准位置也可能会被覆盖。如果你将 K3s 与自定义的非捆绑 CNI 一起使用，
则必须为这些 CNI 使用正确的路径，例如 `/etc/cni/net.d` - [有关详细信息，请参阅 K3s 文档](https://docs.k3s.io/zh/networking/basic-network-options#custom-cni)。例如：

{{< tabset category-name="install-method" >}}

{{< tab name="Helm" category-value="helm" >}}

    {{< text syntax=bash >}}
    $ helm install istio-cni istio/cni -n istio-system --set profile=ambient --wait --set cniConfDir=/var/lib/rancher/k3s/agent/etc/cni/net.d --set cniBinDir=/var/lib/rancher/k3s/data/current/bin/
    {{< /text >}}

{{< /tab >}}

{{< tab name="istioctl" category-value="istioctl" >}}

    {{< text syntax=bash >}}
    $ istioctl install --set profile=ambient --set values.cni.cniConfDir=/var/lib/rancher/k3s/agent/etc/cni/net.d --set values.cni.cniBinDir=/var/lib/rancher/k3s/data/current/bin/
    {{< /text >}}

{{< /tab >}}

{{< /tabset >}}

### MicroK8s {#microk8s}

如果你在 [MicroK8s](https://microk8s.io/) 上安装 Istio，
则必须在安装命令后附加一个值，因为 MicroK8s [使用非标准位置来存储 CNI 配置和二进制文件](https://microk8s.io/docs/change-cidr)。例如：

{{< tabset category-name="install-method" >}}

{{< tab name="Helm" category-value="helm" >}}

    {{< text syntax=bash >}}
    $ helm install istio-cni istio/cni -n istio-system --set profile=ambient --wait --set cniConfDir=/var/snap/microk8s/current/args/cni-network --set cniBinDir=/var/snap/microk8s/current/opt/cni/bin

    {{< /text >}}

{{< /tab >}}

{{< tab name="istioctl" category-value="istioctl" >}}

    {{< text syntax=bash >}}
    $ istioctl install --set profile=ambient --set values.cni.cniConfDir=/var/snap/microk8s/current/args/cni-network --set values.cni.cniBinDir=/var/snap/microk8s/current/opt/cni/bin
    {{< /text >}}

{{< /tab >}}

{{< /tabset >}}

### minikube {#minikube}

如果你正在使用 [minikube](https://kubernetes.io/docs/tasks/tools/install-minikube/)
和 [Docker 驱动程序](https://minikube.sigs.k8s.io/docs/drivers/docker/)，
则必须在安装命令中附加一些值，以便 Istio CNI 节点代理可以正确管理和捕获节点上的 Pod。例如：

{{< tabset category-name="install-method" >}}

{{< tab name="Helm" category-value="helm" >}}

    {{< text syntax=bash >}}
    $ helm install istio-cni istio/cni -n istio-system --set profile=ambient --wait --set cniNetnsDir="/var/run/docker/netns"
    {{< /text >}}

{{< /tab >}}

{{< tab name="istioctl" category-value="istioctl" >}}

    {{< text syntax=bash >}}
    $ istioctl install --set profile=ambient --set cni.cniNetnsDir="/var/run/docker/netns"
    {{< /text >}}

{{< /tab >}}

{{< /tabset >}}

### Red Hat OpenShift {#red-hat-openshift}

OpenShift 要求在 `kube-system` 命名空间中安装 `ztunnel` 和 `istio-cni` 组件。
提供了 `openshift-ambient` 安装配置文件，它将为您进行此更改。
在安装命令中将 `profile=ambient` 实例替换为 `profile=openshift-ambient`。例如：

{{< tabset category-name="install-method" >}}

{{< tab name="Helm" category-value="helm" >}}

    {{< text syntax=bash >}}
    $ helm install istio-cni istio/cni -n istio-system --set profile=openshift-ambient --wait
    {{< /text >}}

{{< /tab >}}

{{< tab name="istioctl" category-value="istioctl" >}}

    {{< text syntax=bash >}}
    $ istioctl install --set profile=openshift-ambient --skip-confirmation
    {{< /text >}}

{{< /tab >}}

{{< /tabset >}}

## CNI plugins {#cni-plugins}

当使用某些 {{< gloss "CNI" >}}CNI 插件{{< /gloss >}}时，以下配置适用于所有平台：

### Cilium {#cilium}

1. Cilium 目前默认主动删除其他 CNI 插件及其配置，
   并且必须配置 `cni.exclusive = false` 才能正确支持链接。
   有关更多详细信息，请参阅
   [Cilium 文档](https://docs.cilium.io/en/stable/helm-reference/)。
1. Cilium 的 BPF 伪装目前默认处于禁用状态，
   并且在 Istio 使用本地链接 IP 进行 Kubernetes 健康检查时存在问题。
   目前不支持通过 `bpf.masquerade=true` 启用 BPF 伪装，
   这会导致 Istio Ambient 中的 Pod 健康检查无法正常工作。
   Cilium 的默认 iptables 伪装实现应该可以继续正常运行。
1. 由于 Cilium 管理节点身份并在内部允许节点级健康探针到 Pod 的白名单，
   在 Cilium CNI 安装下的 Istio Ambient 模式中应用 default-DENY 的 `NetworkPolicy`，
   将会导致被 Cilium 默认免于 `NetworkPolicy` 执行的 `kubelet` 健康探针被阻塞。

    这可以通过应用以下 `CiliumClusterWideNetworkPolicy` 来解决：

    {{< text syntax=yaml >}}
    apiVersion: "cilium.io/v2"
    kind: CiliumClusterwideNetworkPolicy
    metadata:
      name: "allow-ambient-hostprobes"
    spec:
      description: "Allows SNAT-ed kubelet health check probes into ambient pods"
      endpointSelector: {}
      ingress:
      - fromCIDR:
        - "169.254.7.127/32"
    {{< /text >}}

    请参阅 [Issue #49277](https://github.com/istio/istio/issues/49277)
    和 [CiliumClusterWideNetworkPolicy](https://docs.cilium.io/en/stable/network/kubernetes/policy/#ciliumclusterwidenetworkpolicy)
    了解更多详细信息。
