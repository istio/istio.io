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

On GKE, Istio components with the [system-node-critical](https://kubernetes.io/docs/tasks/administer-cluster/guaranteed-scheduling-critical-addon-pods/) `priorityClassName` can only be installed in namespaces that have a [ResourceQuota](https://kubernetes.io/docs/concepts/policy/resource-quotas/) defined. By default in GKE, only `kube-system` has a defined ResourceQuota for the `node-critical` class. The Istio CNI node agent and `ztunnel` both require the `node-critical` class, and so in GKE, both components must either:

- Be installed into `kube-system` (_not_ `istio-system`)
- Be installed into another namespace (such as `istio-system`) in which a ResourceQuota has been manually created, for example:

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

If you are using [k3d](https://k3d.io/) with the default Flannel CNI, you must append some values to your installation command,  as k3d uses nonstandard locations for CNI configuration and binaries.

1. Create a cluster with Traefik disabled so it doesn't conflict with Istio's ingress gateways:

    {{< text bash >}}
    $ k3d cluster create --api-port 6550 -p '9080:80@loadbalancer' -p '9443:443@loadbalancer' --agents 2 --k3s-arg '--disable=traefik@server:*'
    {{< /text >}}

1.  Set the `cniConfDir` and `cniBinDir` values when installing Istio. For example:

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

### K3s

When using [K3s](https://k3s.io/) and one of its bundled CNIs, you must append some values to your installation command, as K3S uses nonstandard locations for CNI configuration and binaries. These nonstandard locations may be overridden as well, [according to K3s documentation](https://docs.k3s.io/cli/server#k3s-server-cli-help). If you are using K3s with a custom, non-bundled CNI, you must use the correct paths for those CNIs, e.g. `/etc/cni/net.d` - [see the K3s docs for details](https://docs.k3s.io/networking/basic-network-options#custom-cni). For example:

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

If you are installing Istio on [MicroK8s](https://microk8s.io/), you must append a value to your installation command, as MicroK8s [uses non-standard locations for CNI configuration and binaries](https://microk8s.io/docs/change-cidr). For example:

{{< tabset category-name="install-method" >}}

{{< tab name="Helm" category-value="helm" >}}

    {{< text syntax=bash >}}
    $ helm install istio-cni istio/cni -n istio-system --set profile=ambient --wait --set cniConfDir=/var/snap/microk8s/current/args/cni-network --set cniBinDir=/var/snap/microk8s/current/opt/cni/bin

{{< /tab >}}

{{< tab name="istioctl" category-value="istioctl" >}}

    {{< text syntax=bash >}}
    $ istioctl install --set profile=ambient --set values.cni.cniConfDir=/var/snap/microk8s/current/args/cni-network --set values.cni.cniBinDir=/var/snap/microk8s/current/opt/cni/bin
    {{< /text >}}

{{< /tab >}}

{{< /tabset >}}

### minikube

If you are using [minikube](https://kubernetes.io/docs/tasks/tools/install-minikube/) with the [Docker driver](https://minikube.sigs.k8s.io/docs/drivers/docker/),
you must append some values to your installation command so that the Istio CNI node agent can correctly manage
and capture pods on the node. For example:

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

### Red Hat OpenShift

OpenShift requires that `ztunnel` and `istio-cni` components are installed in the `kube-system` namespace.  An `openshift-ambient` installation profile is provided which will make this change for you.  Replace instances of `profile=ambient` with `profile=openshift-ambient` in the installation commands. For example:

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

## CNI plugins

The following configurations apply to all platforms, when certain {{< gloss "CNI" >}}CNI plugins{{< /gloss >}} are used:

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
