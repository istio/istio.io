---
title: 平台特定先决条件
description: 在 Ambient 模式下安装 Istio 的平台特定先决条件。
weight: 4
owner: istio/wg-environments-maintainers
test: no
---

本文档涵盖了在 Ambient 模式下安装 Istio 的任何特定于平台或环境的先决条件。

## 平台 {#platform}

### Minikube {#minikube}

1. 如果您使用 [Minikube](https://kubernetes.io/docs/tasks/tools/install-minikube/)
   以及 [Docker 驱动](https://minikube.sigs.k8s.io/docs/drivers/docker/)，
   必须在 `helm install` 命令后追加 `--set cni.cniNetnsDir="/var/run/docker/netns"`，
   以便 `istio-cni` 节点代理能够正确管理和捕获节点上的 Pod。

### MicroK8s {#microk8s}

1. 如果您使用的是 [MicroK8s](https://microk8s.io/)，
   由于 MicroK8s [对于 CNI 配置和二进制文件使用了非标准位置](https://microk8s.io/docs/change-cidr)，
   则必须在 `helm install` 命令附加
   `--set values.cni.cniConfDir=/var/snap/microk8s/current/args/cni-network --set values.cni.cniBinDir=/var/snap/microk8s/current/opt/cni/bin`。

### K3S {#k3s}

1. 如果您使用的是 [K3S](https://k3s.io/)，
   则必须在 `helm install` 命令中附加
   `--set values.cni.cniConfDir=/var/lib/rancher/k3s/agent/etc/cni/net.d --set values.cni.cniBinDir=/var/lib/rancher/k3s/data/current/bin/`，
   因为 K3S 使用非标准位置来存储 CNI 配置和二进制文件。
   [根据 K3S 文档](https://docs.k3s.io/zh/cli/server#k3s-server-cli-%E5%B8%AE%E5%8A%A9)这些非标准位置也可以被覆盖。

## CNI {#cni}

### Cilium {#cilium}

1. Cilium 目前默认主动删除其他 CNI 插件及其配置，
   并且必须配置 `cni.exclusive = false` 才能正确支持链接。
   有关更多详细信息，请参阅
   [Cilium 文档](https://docs.cilium.io/en/stable/helm-reference/)。

1. 由于 Cilium 管理节点身份并在内部允许节点级健康探针到 Pod 的白名单，
   在 Cilium CNI 安装下的 Istio Ambient 模式中应用 default-DENY 的 `NetworkPolicy`，
   将会导致被 Cilium 默认免于 `NetworkPolicy` 执行的 `kubelet` 健康探针被阻塞。

    这可以通过应用以下 `CiliumClusterWideNetworkPolicy` 来解决：

    {{< text syntax=yaml snip_id=none >}}
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
