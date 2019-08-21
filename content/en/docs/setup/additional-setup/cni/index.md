---
title: Install Istio with the Istio CNI plugin
description: Install and use Istio with the Istio CNI plugin, allowing operators to deploy services with lower privilege.
weight: 70
aliases:
    - /docs/setup/kubernetes/install/cni
    - /docs/setup/kubernetes/additional-setup/cni
keywords: [kubernetes,cni,sidecar,proxy,network,helm]
---

Follow this flow to install, configure, and use an Istio mesh using the Istio Container Network Interface
([CNI](https://github.com/containernetworking/cni#cni---the-container-network-interface))
plugin.

By default Istio injects an `initContainer`, `istio-init`, in pods deployed in
the mesh.  The `istio-init` container sets up the pod network traffic
redirection to/from the Istio sidecar proxy.  This requires the user or
service-account deploying pods to the mesh to have sufficient Kubernetes RBAC
permissions to deploy [`NET_ADMIN` containers](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-capabilities-for-a-container).
Requiring Istio users to have elevated Kubernetes RBAC permissions is
problematic for some organizations' security compliance.  The Istio CNI plugin
is a replacement for the `istio-init` container that performs the same
networking functionality but without requiring Istio users to enable elevated
Kubernetes RBAC permissions.

The Istio CNI plugin performs the Istio mesh pod traffic redirection in the Kubernetes pod lifecycle's network
setup phase, thereby removing the [`NET_ADMIN` capability requirement](/docs/setup/additional-setup/requirements/)
for users deploying pods into the Istio mesh.  The [Istio CNI plugin](https://github.com/istio/cni)
replaces the functionality provided by the `istio-init` container.

## Prerequisites

1.  Install Kubernetes with the container runtime supporting CNI and `kubelet` configured
    with the main [CNI](https://github.com/containernetworking/cni) plugin enabled via `--network-plugin=cni`.
    *  AWS EKS, Azure AKS, and IBM Cloud IKS clusters have this capability.
    *  Google Cloud GKE clusters require that the
       [network-policy](https://cloud.google.com/kubernetes-engine/docs/how-to/network-policy) feature
       is enabled to have Kubernetes configured with `network-plugin=cni`.

1.  Install Kubernetes with the [ServiceAccount admission controller](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/#serviceaccount) enabled.
    *  The Kubernetes documentation highly recommends this for all Kubernetes installations
       where `ServiceAccounts` are utilized.

## Installation

1.  Determine the Kubernetes environment's CNI plugin `--cni-bin-dir` and `--cni-conf-dir` settings.
    Refer to [Hosted Kubernetes settings](#hosted-kubernetes-settings) for any non-default settings required.

1.  Install Istio CNI and Istio using Helm.
    Refer to the [Customizable Install with Helm](/docs/setup/install/helm/#cni) instructions and the
    **Istio CNI enabled** profile.
    Pass `--set cniBinDir=...` and/or `--set cniConfDir=...` options when installing `istio-cni` if non-default,
    as determined in the previous step.

### Helm chart parameters

The following table shows all the options that the `istio-cni` Helm chart supports:

| Option | Values | Default | Description |
|--------|--------|---------|-------------|
| `hub` | | | The container registry to pull the `install-cni` image. |
| `tag` | | | The container tag to use to pull the `install-cni` image. |
| `logLevel` | `panic`, `fatal`, `error`, `warn`, `info`, `debug` | `warn` | Logging level for CNI binary. |
| `excludeNamespaces` | `[]string` | `[ istio-system ]` | List of namespaces to exclude from Istio pod check. |
| `cniBinDir` | | `/opt/cni/bin` | Must be the same as the environment's `--cni-bin-dir` setting (`kubelet` parameter). |
| `cniConfDir` | | `/etc/cni/net.d` | Must be the same as the environment's `--cni-conf-dir` setting (`kubelet` parameter). |
| `cniConfFileName` | | | Leave unset to auto-find the first file in the `cni-conf-dir` (as `kubelet` does).  Primarily used for testing `install-cni` plugin configuration.  If set, `install-cni` will inject the plugin configuration into this file in the `cni-conf-dir`. |

### Excluding specific Kubernetes namespaces

This example uses Helm to perform the following tasks:

* Install the Istio CNI plugin.
* Configure its log level.
* Ignore the pods in the following namespaces:
    * `istio-system`
    * `foo_ns`
    * `bar_ns`

Refer to the [Customizable Install with Helm](/docs/setup/install/helm/#cni) for complete instructions.

Use the following command to render and apply Istio CNI components and override the default configuration of the
`istio-cni` Helm chart's `logLevel` and `excludeNamespaces` parameters:

{{< text bash >}}
$ helm template install/kubernetes/helm/istio-cni --name=istio-cni --namespace=istio-system \
    --set logLevel=info \
    --set excludeNamespaces={"istio-system,kube-system,foo_ns,bar_ns"} | kubectl apply -f -
{{< /text >}}

### Hosted Kubernetes settings

The Istio CNI solution is not ubiquitous. Some platforms, especially hosted Kubernetes environments, do not enable the
CNI plugin in the `kubelet` configuration.
The `istio-cni` plugin is expected to work with any hosted Kubernetes leveraging CNI plugins.
The following table shows the required settings for many common Kubernetes environments.

| Hosted Cluster Type | Required Istio CNI Setting Overrides | Required Platform Setting Overrides |
|---------------------|--------------------------------------|-------------------------------------|
| GKE 1.9+ (see [GKE setup](#gke-setup) below for details)| `cniBinDir=/home/kubernetes/bin` | enable [network-policy](https://cloud.google.com/kubernetes-engine/docs/how-to/network-policy) |
| IKS (IBM cloud) | _(none)_ | _(none)_ |
| EKS (AWS) | _(none)_ | _(none)_ |
| AKS (Azure) | _(none)_ | _(none)_ |
| Red Hat OpenShift 3.10+ | _(none)_ | _(none)_ |

### GKE setup

1.  Refer to the procedure to [prepare a GKE cluster for Istio](/docs/setup/platform-setup/gke/) and
    enable [network-policy](https://cloud.google.com/kubernetes-engine/docs/how-to/network-policy) in your cluster.

    {{< warning >}}
    For existing clusters, this redeploys all nodes.
    {{< /warning >}}

1.  Install Istio CNI via Helm including the `--set cniBinDir=/home/kubernetes/bin` option.
    For example, the following `helm install` command sets the `cniBinDir` value for a GKE cluster:

    {{< text bash >}}
    $ helm install install/kubernetes/helm/istio-cni --name=istio-cni --namespace=istio-system --set cniBinDir=/home/kubernetes/bin
    {{< /text >}}

## Sidecar injection compatibility

The use of the Istio CNI plugin requires Kubernetes pods to be deployed with a sidecar injection method
that uses the `istio-sidecar-injector` configmap created from the Helm installation with the
`istio_cni.enabled=true`.  Refer to [Istio sidecar injection](/docs/setup/additional-setup/sidecar-injection/)
for details about Istio sidecar injection methods.

The following sidecar injection methods are supported for use with the Istio CNI plugin:

1.  [Automatic sidecar injection](/docs/setup/additional-setup/sidecar-injection/#automatic-sidecar-injection)
1.  Manual sidecar injection with the `istio-sidecar-injector` configmap
    1.  `istioctl kube-inject` using the configmap directly:

        {{< text bash >}}
        $ istioctl kube-inject -f deployment.yaml -o deployment-injected.yaml --injectConfigMapName istio-sidecar-injector
        $ kubectl apply -f deployment-injected.yaml
        {{< /text >}}

    1.  `istioctl kube-inject` using a file created from the configmap:

        {{< text bash >}}
        $ kubectl -n istio-system get configmap istio-sidecar-injector -o=jsonpath='{.data.config}' > inject-config.yaml
        $ istioctl kube-inject -f deployment.yaml -o deployment-injected.yaml --injectConfigFile inject-config.yaml
        $ kubectl apply -f deployment-injected.yaml
        {{< /text >}}

## Operational details

The Istio CNI plugin handles Kubernetes pod create and delete events and does the following:

1.  Identify Istio user application pods with Istio sidecars requiring traffic redirection
1.  Perform pod network namespace configuration to redirect traffic to/from the Istio sidecar

### Identifying pods requiring traffic redirection

The Istio CNI plugin identifies pods requiring traffic redirection to/from the
accompanying Istio proxy sidecar by checking that the pod meets all of the following conditions:

1.  The pod is NOT in a Kubernetes namespace in the configured `exclude_namespaces` list.
1.  The pod has a container named `istio-proxy`.
1.  The pod has more than 1 container.
1.  The pod has no annotation with key `sidecar.istio.io/inject` OR the value of the annotation is `true`.

### Traffic redirection parameters

To redirect traffic in the application pod's network namespace to/from the Istio proxy sidecar, the Istio
CNI plugin configures the namespace's iptables.  The following table describes the parameters to the
redirect functionality.  To override the default values for the parameters, set the corresponding
application pod annotation key.

| Annotation Key | Values | Default | Description |
|----------------|--------|---------|-------------|
| `sidecar.istio.io/interceptionMode`| `REDIRECT`, `TPROXY` | `REDIRECT` | The iptables redirect mode to use. |
| `traffic.sidecar.istio.io/includeOutboundIPRanges` | `<IPCidr1>,<IPCidr2>,...` | `"*"` | Comma separated list of IP ranges in CIDR form to redirect to the sidecar proxy.  The default value of `"*"` redirects all traffic. |
| `traffic.sidecar.istio.io/excludeOutboundIPRanges` | `<IPCidr1>,<IPCidr2>,...` | | Comma separated list of IP ranges in CIDR form to be excluded from redirection.  Only applies when `includeOutboundIPRanges` is `"*"`. |
| `traffic.sidecar.istio.io/includeInboundPorts` | `<port1>,<port2>,...` | Pod's list of `containerPorts` | Comma separated list of inbound ports for which traffic is to be redirected to the Istio proxy sidecar.  The value of `"*"` redirects all ports. |
| `traffic.sidecar.istio.io/excludeInboundPorts` | `<port1>,<port2>,...` | | Comma separated list of inbound ports to be excluded from redirection to the Istio sidecar proxy.  Only valid when `includeInboundPorts` is `"*"`. |
| `traffic.sidecar.istio.io/excludeOutboundPorts` | `<port1>,<port2>,...` | | Comma separated list of outbound ports to be excluded from redirection to Envoy. |
| `traffic.sidecar.istio.io/kubevirtInterfaces` | `<ethX>,<ethY>,...` | | Comma separated list of virtual interfaces whose inbound traffic (from VM) will be treated as outbound. |

### Logging

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

The Istio CNI plugin maintains compatibility with the same set of CNI plugins as the current `NET_ADMIN`
`istio-init` container.

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
