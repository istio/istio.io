---
title: Install Istio with the Istio CNI plugin
description: Install and use Istio with the Istio CNI plugin, allowing operators to deploy services with lower privilege.
weight: 70
aliases:
    - /docs/setup/kubernetes/install/cni
    - /docs/setup/kubernetes/additional-setup/cni
keywords: [kubernetes,cni,sidecar,proxy,network,helm]
owner: istio/wg-networking-maintainers
test: no
---

Follow this guide to install, configure, and use an Istio mesh using the Istio Container Network Interface
([CNI](https://github.com/containernetworking/cni#cni---the-container-network-interface))
plugin.

By default Istio injects an init container, `istio-init`, in pods deployed in
the mesh.  The `istio-init` container sets up the pod network traffic
redirection to/from the Istio sidecar proxy.  This requires the user or
service-account deploying pods to the mesh to have sufficient Kubernetes RBAC
permissions to deploy [containers with the `NET_ADMIN` and `NET_RAW` capabilities](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-capabilities-for-a-container).
Requiring Istio users to have elevated Kubernetes RBAC permissions is
problematic for some organizations' security compliance.  The Istio CNI plugin
is a replacement for the `istio-init` container that performs the same
networking functionality but without requiring Istio users to enable elevated
Kubernetes RBAC permissions.

The Istio CNI plugin identifies Istio user application pods with Istio sidecars requiring traffic redirection and
performs the Istio mesh pod traffic redirection in the Kubernetes pod lifecycle's network
setup phase, thereby removing the [requirement for the `NET_ADMIN` and `NET_RAW` capabilities](/docs/ops/deployment/requirements/)
for users deploying pods into the Istio mesh.  The Istio CNI plugin
replaces the functionality provided by the `istio-init` container.

## Install CNI

### Prerequisites

1. Install Kubernetes with the container runtime supporting CNI and `kubelet` configured
  with the main [CNI](https://github.com/containernetworking/cni) plugin enabled via `--network-plugin=cni`.
    * AWS EKS, Azure AKS, and IBM Cloud IKS clusters have this capability.
    * Google Cloud GKE clusters has CNI enableds when any of the following features is enabled:
       [network policy](https://cloud.google.com/kubernetes-engine/docs/how-to/network-policy),
       [intranode visibility](https://cloud.google.com/kubernetes-engine/docs/how-to/intranode-visibility),
       [workload identity](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity),
       [pod security policy](https://cloud.google.com/kubernetes-engine/docs/how-to/pod-security-policies#overview),
       and [dataplane v2](https://cloud.google.com/kubernetes-engine/docs/concepts/dataplane-v2).
    * OpenShift has CNI enabled by default.

1. Install Kubernetes with the [ServiceAccount admission controller](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/#serviceaccount) enabled.
    * The Kubernetes documentation highly recommends this for all Kubernetes installations
      where `ServiceAccounts` are utilized.

### Install Istio with CNI plugin

In most environments, a basic Istio cluster with CNI enabled can be installed using the following install configuration:

{{< text bash >}}
$ cat << EOF > istio-cni.yaml
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
EOF
$ istioctl install -f istio-cni.yaml
{{< /text >}}

This will deploy an `istio-cni-node` Daemonset into the cluster, which installs Istio CNI plugin bianry to each node and set up needed configuration for the plugin.
The `istio-cni-node` Daemonset runs with [`system-node-critical`](https://kubernetes.io/docs/tasks/administer-cluster/guaranteed-scheduling-critical-addon-pods/) `PriorityClass`.

There are several commonly used install options:

* `components.cni.namespace=kube-system` configures the namespace to install the CNI Daemonset.
* `values.cni.cniBinDir` and `values.cni.cniConfDir` configure the directory pathes to install plugin binary and create plugin configuration.
  `values.cni.cniConfFileName` configures the name of plugin configuration file.
* `values.cni.chained` controls whether to configure the Istio CNI plugin as a chained CNI plugin.

### Hosted Kubernetes settings

The `istio-cni` plugin is expected to work with any hosted Kubernetes leveraging CNI plugins.
Some platforms required special installation settings.

* Google Kubernetes Engine
{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  components:
    cni:
      enabled: true
      namespace: kube-system
  values:
    cni:
      excludeNamespaces:
        - istio-system
        - kube-system
      cniBinDir: /home/kubernetes/bin
{{< /text >}}

* Red Hat OpenShift 4.2+
{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  components:
    cni:
      enabled: true
      namespace: kube-system
  values:
    sidecarInjectorWebhook:
      injectedAnnotations:
        k8s.v1.cni.cncf.io/networks: istio-cni
    cni:
      excludeNamespaces:
        - istio-system
        - kube-system
      cniBinDir: /var/lib/cni/bin
      cniConfDir: /etc/cni/multus/net.d
      cniConfFileName: istio-cni.conf
      chained: false
{{< /text >}}

## Manage CNI

### Upgrade



### CNI race condition repairing

### Traffic redirection parameters

To redirect traffic in the application pod's network namespace to/from the Istio proxy sidecar,
the Istio CNI plugin configures the namespace's iptables.
You can adjust traffic redirection parameters using pod annotations, such as ports and IP ranges to be included or excluded from redirection.
See [resource annotations](/docs/reference/config/annotations) for available parameters.

### Logging & Monitoring

The Istio CNI plugin runs in the container runtime process space.
Due to this, the `kubelet` process writes the plugin's log entries into its log.

### Compatibility with application init containers

The Istio CNI plugin may cause networking connectivity problems for any application `initContainers`. When using Istio CNI, `kubelet`
starts an injected pod with the following steps:

1. The Istio CNI plugin sets up traffic redirection to the Istio sidecar proxy within the pod.
1. All init containers execute and complete successfully.
1. The Istio sidecar proxy starts in the pod along with the pod's other containers.

Init containers execute before the sidecar proxy starts, which can result in traffic loss during their execution.
Avoid this traffic loss with one or both of the following settings:

* Set the `traffic.sidecar.istio.io/excludeOutboundIPRanges` annotation to disable redirecting traffic to any
  CIDRs the init containers communicate with.
* Set the `traffic.sidecar.istio.io/excludeOutboundPorts` annotation to disable redirecting traffic to the
  specific outbound ports the init containers use.

### Compatibility with other CNI plugins

The Istio CNI plugin maintains compatibility with the same set of CNI plugins as the current
`istio-init` container which requires the `NET_ADMIN` and `NET_RAW` capabilities.

The Istio CNI plugin operates as a chained CNI plugin.  This means its configuration is added to the existing
CNI plugins configuration as a new configuration list element.  See the
[CNI specification reference](https://github.com/containernetworking/cni/blob/master/SPEC.md#network-configuration-lists) for further details.
When a pod is created or deleted, the container runtime invokes each plugin in the list in order.  The Istio
CNI plugin only performs actions to setup the application pod's traffic redirection to the injected Istio proxy
sidecar (using `iptables` in the pod's network namespace).

{{< warning >}}
The Istio CNI plugin should not interfere with the operations of the base CNI plugin that configures the pod's
networking setup, although not all CNI plugins have been validated.
{{< /warning >}}
