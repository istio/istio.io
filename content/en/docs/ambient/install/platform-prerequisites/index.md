---
title: Platform-Specific Prerequisites
description: Platform-specific prerequisites for installing Istio in ambient mode.
weight: 2
aliases:
  - /docs/ops/ambient/install/platform-prerequisites
  - /latest/docs/ops/ambient/install/platform-prerequisites  
owner: istio/wg-environments-maintainers
test: no
---

This document covers any platform- or environment-specific prerequisites for installing Istio in ambient mode.

## Platform

Certain Kubernetes environments require you to set various Istio configuration options to support them.

### Google Kubernetes Engine (GKE)

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

### k3d

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

    {{< /text >}}

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

### Cilium

1. Cilium currently defaults to proactively deleting other CNI plugins and their config, and must be configured with
`cni.exclusive = false` to properly support chaining. See [the Cilium documentation](https://docs.cilium.io/en/stable/helm-reference/) for more details.
1. Cilium's BPF masquerading is currently disabled by default, and has issues with Istio's use of link-local IPs for Kubernetes health checking. Enabling BPF masquerading via `bpf.masquerade=true` is not currently supported, and results in non-functional pod health checks in Istio ambient. Cilium's default iptables masquerading implementation should continue to function correctly.
1. Due to how Cilium manages node identity and internally allow-lists node-level health probes to pods,
applying default-DENY `NetworkPolicy` in a Cilium CNI install underlying Istio in ambient mode, will cause `kubelet` health probes (which are by-default exempted from NetworkPolicy enforcement by Cilium) to be blocked.

    This can be resolved by applying the following `CiliumClusterWideNetworkPolicy`:

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

    Please see [issue #49277](https://github.com/istio/istio/issues/49277) and [CiliumClusterWideNetworkPolicy](https://docs.cilium.io/en/stable/network/kubernetes/policy/#ciliumclusterwidenetworkpolicy) for more details.
