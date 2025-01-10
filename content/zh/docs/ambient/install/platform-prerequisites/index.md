---
title: 平台特定的前提条件
description: 安装 Ambient 模式的 Istio 时平台特定的前提条件。
weight: 2
aliases:
  - /zh/docs/ops/ambient/install/platform-prerequisites
  - /zh/latest/docs/ops/ambient/install/platform-prerequisites
owner: istio/wg-environments-maintainers
test: no
---

本文档涵盖了安装 Ambient 模式的 Istio 时各类平台或环境特定的前提条件。

## 平台 {#platform}

某些 Kubernetes 环境需要您设置各种配置选项才能支持 Istio。

### Google Kubernetes Engine（GKE） {#google-kubernetes-engine-gke}

#### 命名空间限制 {#namespace-restrictions}

在 GKE 上，任何具有 [system-node-critical](https://kubernetes.io/zh-cn/docs/tasks/administer-cluster/guaranteed-scheduling-critical-addon-pods/)
`priorityClassName` 的 Pod 只能安装在定义了
[ResourceQuota](https://kubernetes.io/zh-cn/docs/concepts/policy/resource-quotas/) 的命名空间中。
默认情况下，在 GKE 中，只有 `kube-system` 为 `node-critical` 类定义了 ResourceQuota。
Istio CNI 节点代理和 `ztunnel` 都需要 `node-critical` 类，
因此在 GKE 中，两个组件都必须满足以下任一条件：

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

#### 平台配置文件 {#platform-profile}

使用 GKE 时，您必须将正确的 `platform` 值附加到安装命令中，
因为 GKE 对 CNI 二进制文件使用非标准位置，这需要 Helm 覆盖。

{{< tabset category-name="install-method" >}}

{{< tab name="Helm" category-value="helm" >}}

    {{< text syntax=bash >}}
    $ helm install istio-cni istio/cni -n istio-system --set profile=ambient --set global.platform=gke --wait
    {{< /text >}}

{{< /tab >}}

{{< tab name="istioctl" category-value="istioctl" >}}

    {{< text syntax=bash >}}
    $ istioctl install --set profile=ambient --set values.global.platform=gke
    {{< /text >}}

{{< /tab >}}

{{< /tabset >}}

### Amazon Elastic Kubernetes Service（EKS） {#amazon-elastic-kubernetes-service-EKS}

如果您使用 EKS：

- 使用亚马逊的 VPC CNI
- 启用 Pod ENI 中继
- **并且**您正在通过 [SecurityGroupPolicy](https://aws.github.io/aws-eks-best-practices/networking/sgpp/#enforcing-mode-use-strict-mode-for-isolating-pod-and-node-traffic)
  使用 EKS Pod 附加的安全组

[`POD_SECURITY_GROUP_ENFORCING_MODE` 必须明确设置为 `standard`](https://github.com/aws/amazon-vpc-cni-k8s/blob/master/README.md#pod_security_group_enforcing_mode-v1110)，
否则 Pod 运行状况探测将失败。这是因为 Istio 使用链路本地 SNAT 地址来识别 kubelet 运行状况探测，
而 VPC CNI 当前在 Pod 安全组 `strict` 模式下错误路由链路本地数据包。
明确将链路本地地址的 CIDR 排除添加到您的安全组将不起作用，
因为 VPC CNI 的 Pod 安全组模式通过静默路由链路之间的流量来工作，
将它们循环通过中继 `Pod ENI` 以实施安全组策略。
由于[链路本地流量无法跨链路路由](https://datatracker.ietf.org/doc/html/rfc3927#section-2.6.2)，
Pod 安全组功能无法将策略强制应用于它们，这是设计约束，并且在 `strict` 模式下会丢弃数据包。

[VPC CNI 组件上有一个未解决的问题](https://github.com/aws/amazon-vpc-cni-k8s/issues/2797)针对此限制。
如果您使用 Pod 安全组，VPC CNI 团队目前的建议是禁用 `strict` 模式来解决此问题，
或者为您的 Pod 使用基于 `exec` 的 Kubernetes 探测器，而不是基于 kubelet 的探测器。

您可以通过运行以下命令来检查是否启用了 Pod ENI 中继：

{{< text syntax=bash >}}
$ kubectl set env daemonset aws-node -n kube-system --list | grep ENABLE_POD_ENI
{{< /text >}}

您可以通过运行以下命令来检查集群中是否有任何附加 Pod 的安全组：

{{< text syntax=bash >}}
$ kubectl get securitygrouppolicies.vpcresources.k8s.aws
{{< /text >}}

您可以通过运行以下命令设置  `POD_SECURITY_GROUP_ENFORCING_MODE=standard`，
并回收受影响的 Pod：

{{< text syntax=bash >}}
$ kubectl set env daemonset aws-node -n kube-system POD_SECURITY_GROUP_ENFORCING_MODE=standard
{{< /text >}}

### k3d

当使用 [k3d](https://k3d.io/) 与默认的 Flannel CNI 时，
您必须将正确的 `platform` 值附加到安装命令中，
因为 k3d 使用非标准位置进行 CNI 配置和二进制文件，这需要一些 Helm 覆盖。

1. 创建一个禁用 Traefik 的集群，以免与 Istio 的入口网关冲突：

    {{< text bash >}}
    $ k3d cluster create --api-port 6550 -p '9080:80@loadbalancer' -p '9443:443@loadbalancer' --agents 2 --k3s-arg '--disable=traefik@server:*'
    {{< /text >}}

1. 安装 Istio Chart 时设置 `global.platform=k3d`。例如：

    {{< tabset category-name="install-method" >}}

    {{< tab name="Helm" category-value="helm" >}}

        {{< text syntax=bash >}}
        $ helm install istio-cni istio/cni -n istio-system --set profile=ambient --set global.platform=k3d --wait
        {{< /text >}}

    {{< /tab >}}

    {{< tab name="istioctl" category-value="istioctl" >}}

        {{< text syntax=bash >}}
        $ istioctl install --set profile=ambient --set values.global.platform=k3d
        {{< /text >}}

    {{< /tab >}}

    {{< /tabset >}}

### K3s

使用 [K3s](https://k3s.io/) 及其绑定的 CNI 之一时，
您必须将正确的 `platform` 值附加到安装命令中，
因为 K3s 对 CNI 配置和二进制文件使用非标准位置，这需要一些 Helm 覆盖。
对于默认的 K3s 路径，Istio 根据 `global.platform` 值提供内置覆盖。

{{< tabset category-name="install-method" >}}

{{< tab name="Helm" category-value="helm" >}}

    {{< text syntax=bash >}}
    $ helm install istio-cni istio/cni -n istio-system --set profile=ambient --set global.platform=k3s --wait
    {{< /text >}}

{{< /tab >}}

{{< tab name="istioctl" category-value="istioctl" >}}

    {{< text syntax=bash >}}
    $ istioctl install --set profile=ambient --set values.global.platform=k3s
    {{< /text >}}

{{< /tab >}}

{{< /tabset >}}

但是，根据 K3s 文档，这些位置可能会在 K3s 中被覆盖。
如果您将 K3s 与自定义、非捆绑的 CNI 一起使用，则必须手动为这些 CNI 指定正确的路径，
比如 `/etc/cni/net.d` - [有关详细信息，请参阅 K3s 文档](https://docs.k3s.io/zh/networking/basic-network-options#custom-cni)。例如：

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

### MicroK8s

如果您要在 [MicroK8s](https://microk8s.io/) 上安装 Istio，
则必须在安装命令中附加正确的 `platform` 值，
因为 MicroK8s [使用非标准位置来存放 CNI 配置和二进制文件](https://microk8s.io/docs/change-cidr)。例如：

{{< tabset category-name="install-method" >}}

{{< tab name="Helm" category-value="helm" >}}

    {{< text syntax=bash >}}
    $ helm install istio-cni istio/cni -n istio-system --set profile=ambient --set global.platform=microk8s --wait

    {{< /text >}}

{{< /tab >}}

{{< tab name="istioctl" category-value="istioctl" >}}

    {{< text syntax=bash >}}
    $ istioctl install --set profile=ambient --set values.global.platform=microk8s
    {{< /text >}}

{{< /tab >}}

{{< /tabset >}}

### minikube

如果您正在使用 [minikube](https://kubernetes.io/docs/tasks/tools/install-minikube/)
和 [Docker 驱动程序](https://minikube.sigs.k8s.io/docs/drivers/docker/)，
您必须将正确的 `platform` 值附加到安装命令中，
因为带有 Docker 的 minikube 使用非标准的容器绑定挂载路径。例如：

{{< tabset category-name="install-method" >}}

{{< tab name="Helm" category-value="helm" >}}

    {{< text syntax=bash >}}
    $ helm install istio-cni istio/cni -n istio-system --set profile=ambient --set global.platform=minikube --wait"
    {{< /text >}}

{{< /tab >}}

{{< tab name="istioctl" category-value="istioctl" >}}

    {{< text syntax=bash >}}
    $ istioctl install --set profile=ambient --set values.global.platform=minikube"
    {{< /text >}}

{{< /tab >}}

{{< /tabset >}}

### Red Hat OpenShift {#red-hat-openshift}

OpenShift 要求在 `kube-system` 命名空间中安装 `ztunnel` 和 `istio-cni` 组件，
并且要求为所有 Chart 设置 `global.platform=openshift`。

{{< tabset category-name="install-method" >}}

{{< tab name="Helm" category-value="helm" >}}

    您必须为安装的**每个** Chart 并设置 `--set global.platform=openshift`，例如 `istiod` Chart：

    {{< text syntax=bash >}}
    $ helm install istiod istio/istiod -n istio-system --set profile=ambient --set global.platform=openshift --wait
    {{< /text >}}

    此外，必须在 `kube-system` 命名空间中安装 `istio-cni` 和 `ztunnel`，例如：

    {{< text syntax=bash >}}
    $ helm install istio-cni istio/cni -n kube-system --set profile=ambient --set global.platform=openshift --wait
    $ helm install ztunnel istio/ztunnel -n kube-system --set profile=ambient --set global.platform=openshift --wait
    {{< /text >}}

{{< /tab >}}

{{< tab name="istioctl" category-value="istioctl" >}}

    {{< text syntax=bash >}}
    $ istioctl install --set profile=openshift-ambient --skip-confirmation
    {{< /text >}}

{{< /tab >}}

{{< /tabset >}}

## CNI 插件 {#cni-plugins}

当使用某些 {{< gloss "CNI" >}}CNI 插件{{< /gloss >}}时，以下配置适用于所有平台：

### Cilium

1. Cilium 目前默认会主动删除其他 CNI 插件及其配置，
   并且必须配置 `cni.exclusive = false` 才能正确支持链式。
   更多细节请参阅 [Cilium 文档](https://docs.cilium.io/en/stable/helm-reference/)。
1. Cilium 的 BPF 伪装目前默认处于禁用状态，
   并且在 Istio 使用本地链路 IP 进行 Kubernetes 健康检查时存在问题。
   目前不支持通过 `bpf.masquerade=true` 启用 BPF 伪装，
   这会导致 Istio Ambient 中的 Pod 健康检查无法正常工作。
   Cilium 的默认 iptables 伪装实现应该可以继续正常运行。
1. 由于 Cilium 管理节点身份的方式以及在内部将节点级健康探针列入 Pod
   的白名单的方式，在 Ambient 模式下在 Istio 底层的 Cilium CNI
   安装中应用任何默认 DENY `NetworkPolicy` 都将导致 `kubelet`
   健康探测（默认情况下 Cilium 会默默地免除所有策略实施）被阻止。
   这是因为 Istio 对于 kubelet 健康探测使用 Cilium 无法识别的链路本地 SNAT 地址，
   并且 Cilium 没有免除链路本地地址执行策略的选项。

    这可以通过应用以下 `CiliumClusterWideNetworkPolicy` 来解决：

    {{< text syntax=yaml >}}
    apiVersion: "cilium.io/v2"
    kind: CiliumClusterwideNetworkPolicy
    metadata:
      name: "allow-ambient-hostprobes"
    spec:
      description: "Allows SNAT-ed kubelet health check probes into ambient pods"
      enableDefaultDeny:
        egress: false
        ingress: false
      endpointSelector: {}
      ingress:
      - fromCIDR:
        - "169.254.7.127/32"
    {{< /text >}}

    除非您的集群中已经应用了其他默认拒绝的 `NetworkPolicies` 或 `CiliumNetworkPolicies`，否则不需要覆盖此策略。

    更多细节请参阅 [Issue #49277](https://github.com/istio/istio/issues/49277)
    和 [CiliumClusterWideNetworkPolicy](https://docs.cilium.io/en/stable/network/kubernetes/policy/#ciliumclusterwidenetworkpolicy)。
