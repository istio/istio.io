---
title: Platform-Specific Prerequisites
description: Platform-specific prerequisites for installing Istio in ambient mode.
weight: 4
owner: istio/wg-environments-maintainers
test: no
---

This document covers any platform or environment specific prerequisites for installing Istio in ambient mode.

## Platform

### Minikube

1. If you are using [Minikube](https://kubernetes.io/docs/tasks/tools/install-minikube/) with the [Docker driver](https://minikube.sigs.k8s.io/docs/drivers/docker/),
you must append `--set cni.cniNetnsDir="/var/run/docker/netns"` to the `helm install` command so that the `istio-cni` node agent can correctly manage
and capture pods on the node.

### MicroK8s

1. If you are using [MicroK8s](https://microk8s.io/), you must append `--set values.cni.cniConfDir=/var/snap/microk8s/current/args/cni-network --set values.cni.cniBinDir=/var/snap/microk8s/current/opt/cni/bin` to the `helm install` command, as MicroK8s [uses nonstandard locations for CNI configuration and binaries](https://microk8s.io/docs/change-cidr).

### K3S

1. If you are using [K3S](https://k3s.io/), you must append `--set values.cni.cniConfDir=/var/lib/rancher/k3s/agent/etc/cni/net.d --set values.cni.cniBinDir=/var/lib/rancher/k3s/data/current/bin/` to the `helm install` command, as K3S uses nonstandard locations for CNI configuration and binaries. These nonstandard locations may be overridden as well [according to K3S documentation](https://docs.k3s.io/cli/server#k3s-server-cli-help).

## CNI

### Cilium

1. Cilium currently defaults to proactively deleting other CNI plugins and their config, and must be configured with
`cni.exclusive = false` to properly support chaining. See [the Cilium documentation](https://docs.cilium.io/en/stable/helm-reference/) for more details.

1. Due to how Cilium manages node identity and internally allow-lists node-level health probes to pods,
applying default-DENY `NetworkPolicy` in a Cilium CNI install underlying Istio in ambient mode, will cause `kubelet` health probes (which are by-default exempted from NetworkPolicy enforcement by Cilium) to be blocked.

    This can be resolved by applying the following `CiliumClusterWideNetworkPolicy`:

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

    Please see [issue #49277](https://github.com/istio/istio/issues/49277) and [CiliumClusterWideNetworkPolicy](https://docs.cilium.io/en/stable/network/kubernetes/policy/#ciliumclusterwidenetworkpolicy) for more details.
