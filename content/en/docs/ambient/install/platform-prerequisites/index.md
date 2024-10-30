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

### Amazon Elastic Kubernetes Service (EKS)

If you are using EKS:

- with Amazon's VPC CNI
- with Pod ENI trunking enabled
- **and** you are using EKS pod-attached SecurityGroups via [SecurityGroupPolicy](https://aws.github.io/aws-eks-best-practices/networking/sgpp/#enforcing-mode-use-strict-mode-for-isolating-pod-and-node-traffic)

[`POD_SECURITY_GROUP_ENFORCING_MODE` must be explicitly set to `standard`](https://github.com/aws/amazon-vpc-cni-k8s/blob/master/README.md#pod_security_group_enforcing_mode-v1110), or pod health probes (which are by-default silently exempted from all policy enforcement by the VPC CNI) will fail. This is because Istio uses a link-local SNAT address for kubelet health probes, which Amazon's VPC CNI is not aware of, and the VPC CNI does not have an option to exempt link-local addresses from policy enforcement.

You can check if you have pod ENI trunking enabled by running the following command:

{{< text syntax=bash >}}
$ kubectl set env daemonset aws-node -n kube-system --list | grep ENABLE_POD_ENI
{{< /text >}}

You can check if you have any pod-attached security groups in your cluster by running the following command:

{{< text syntax=bash >}}
$ kubectl get securitygrouppolicies.vpcresources.k8s.aws
{{< /text >}}

You can set `POD_SECURITY_GROUP_ENFORCING_MODE=standard` by running the following command, and recycling affected pods:

{{< text syntax=bash >}}
$ kubectl set env daemonset aws-node -n kube-system POD_SECURITY_GROUP_ENFORCING_MODE=standard
{{< /text >}}

### k3d

When using [k3d](https://k3d.io/) with the default Flannel CNI, you must append the correct `platform` value to your installation commands, as k3d uses nonstandard locations for CNI configuration and binaries which requires some Helm overrides.

1. Create a cluster with Traefik disabled so it doesn't conflict with Istio's ingress gateways:

    {{< text bash >}}
    $ k3d cluster create --api-port 6550 -p '9080:80@loadbalancer' -p '9443:443@loadbalancer' --agents 2 --k3s-arg '--disable=traefik@server:*'
    {{< /text >}}

1.  Set `global.platform=k3d` when installing Istio charts. For example:

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

When using [K3s](https://k3s.io/) and one of its bundled CNIs, you must append the correct `platform` value to your installation commands, as K3s uses nonstandard locations for CNI configuration and binaries which requires some Helm overrides. For the default K3s paths, Istio provides built-in overrides based on the `global.platform` value.

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

However, these locations may be overridden in K3s, [according to K3s documentation](https://docs.k3s.io/cli/server#k3s-server-cli-help). If you are using K3s with a custom, non-bundled CNI, you must manually specify the correct paths for those CNIs, e.g. `/etc/cni/net.d` - [see the K3s docs for details](https://docs.k3s.io/networking/basic-network-options#custom-cni). For example:

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

If you are installing Istio on [MicroK8s](https://microk8s.io/), you must append the correct `platform` value to your installation commands, as MicroK8s [uses non-standard locations for CNI configuration and binaries](https://microk8s.io/docs/change-cidr). For example:

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

If you are using [minikube](https://kubernetes.io/docs/tasks/tools/install-minikube/) with the [Docker driver](https://minikube.sigs.k8s.io/docs/drivers/docker/),
you must append the correct `platform` value to your installation commands, as minikube with Docker uses a nonstandard bind mount path for containers.
For example:

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

### Red Hat OpenShift

OpenShift requires that `ztunnel` and `istio-cni` components are installed in the `kube-system` namespace, and that you set `global.platform=openshift` for all charts.

If you use `helm`, you can set the target namespace and `global.platform` values directly.

If you use `istioctl`, you must use a special profile named `openshift-ambient` to accomplish the same thing.

{{< tabset category-name="install-method" >}}

{{< tab name="Helm" category-value="helm" >}}

    {{< text syntax=bash >}}
    $ helm install istio-cni istio/cni -n kube-system --set profile=ambient --set global.platform=openshift --wait
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
applying any default-DENY `NetworkPolicy` in a Cilium CNI install underlying Istio in ambient mode will cause `kubelet` health probes (which are by-default silently exempted from all policy enforcement by Cilium) to be blocked. This is because Istio uses a link-local SNAT address for kubelet health probes, which Cilium is not aware of, and Cilium does not have an option to exempt link-local addresses from policy enforcement.

    This can be resolved by applying the following `CiliumClusterWideNetworkPolicy`:

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

    This policy override is *not* required unless you already have other default-deny `NetworkPolicies` or `CiliumNetworkPolicies` applied in your cluster.

    Please see [issue #49277](https://github.com/istio/istio/issues/49277) and [CiliumClusterWideNetworkPolicy](https://docs.cilium.io/en/stable/network/kubernetes/policy/#ciliumclusterwidenetworkpolicy) for more details.
