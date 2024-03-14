---
title: Platform-Specific Prerequisites
description: Platform-specific prerequisites for installing Istio in ambient mode.
weight: 4
owner: istio/wg-environments-maintainers
test: no
---

This document covers any platform or environment specific prerequisites for installing Istio in ambient mode.

## Platform

### Google Kubernetes Engine (GKE)

1. On GKE, Istio components with the [system-node-critical](https://kubernetes.io/docs/tasks/administer-cluster/guaranteed-scheduling-critical-addon-pods/) `priorityClassName` can only be installed in namespaces that have a [ResourceQuota](https://kubernetes.io/docs/concepts/policy/resource-quotas/) defined. By default in GKE, only `kube-system` has a defined ResourceQuota for the `node-critical` class. `istio-cni` and `ztunnel` both require the `node-critical` class, and so in GKE, both components must either:

      - Be installed into `kube-system` (_not_ `istio-system`)
      - Be installed into another namespace (such as `istio-system`) in which a ResourceQuota has been manually created, for example:

          {{< text syntax=yaml snip_id=none >}}
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

### Minikube

1. If you are using [Minikube](https://kubernetes.io/docs/tasks/tools/install-minikube/) with the [Docker driver](https://minikube.sigs.k8s.io/docs/drivers/docker/),
you must append `--set cni.cniNetnsDir="/var/run/docker/netns"` to the `helm install` command so that the `istio-cni` node agent can correctly manage
and capture pods on the node.

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
