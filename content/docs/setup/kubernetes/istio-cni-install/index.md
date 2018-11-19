---
title: Istio CNI Install Options
description: Instructions for installing and using Istio with the Istio CNI plugin.
weight: 70
keywords: [kubernetes,cni]
---

The Istio CNI plugin implements the networking details for injecting the Istio sidecar proxy between application pods
and the container networking infrastructure.  Starting with Istio 1.1, Using the Istio CNI plugin removes the
requirement for the privileged, `NET_ADMIN` container in the Istio users' application pods.  The
[Istio CNI plugin](https://github.com/istio/cni) replaces the functionality provided by the `istio-init`
container injected into application pods' `initContainers` list.

## Prerequisites

1.  Kubernetes installed with the container runtime supporting CNI and `kubelets` configured
    with the main CNI plugin enabled--`network-plugin=cni`.
    *  This is enabled for the Kubernetes installation for IBM Cloud IKS, Azure AKS, and AWS EKS clusters.
    *  For Google Cloud GKE clusters, the
       [network-policy](https://cloud.google.com/kubernetes-engine/docs/how-to/network-policy) feature
       must be enabled to have Kubernetes configured with `network-plugin=cni`.

1.  Kubernetes installed with the [ServiceAccount admission controller](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/#serviceaccount) enabled.
    *  The Kubernetes documentation highly recommends this for all Kubernetes installations
       where `ServiceAccounts` are utilized.

## Installation steps

The installation of the Istio CNI plugin is integrated with the [Istio Installation with Helm](/docs/setup/kubernetes/helm-install/) procedure via the addition of the setting `--set istio_cni.enabled=true`.

{{< text bash >}}
$ helm template install/kubernetes/helm/istio --name istio --namespace istio-system \
  --set istio_cni.enabled=true > $HOME/istio.yaml
{{< /text >}}

Refer to the full set of `istio-cni` Helm parameters in the chart's [`values.yaml`](https://github.com/istio/cni/blob/master/deployments/kubernetes/install/helm/istio-cni/values.yaml).

For most Kubernetes environments the `istio-cni` chart's defaults will configure the Istio CNI plugin in a
manner compatible with the Kubernetes installation.  Refer to the [Hosted Kubernetes Usage](#hosted-kubernetes-usage) section for Kubernetes environment specific procedures.

The following example creates a Istio manifest with the Istio CNI plugin enabled and overrides the default
configuration of the `istio-cni` Helm chart's `logLevel` and `excludeNamespaces` parameters:

{{< text bash >}}
$ helm template install/kubernetes/helm/istio --name istio --namespace istio-system \
  --set istio_cni.enabled=true \
  --set istio-cni.logLevel=info \
  --set istio-cni.excludeNamespaces={"istio-system,foo_ns,bar_ns"} > $HOME/istio.yaml
{{< /text >}}

Note the above `istio-cni.excludeNamespaces` format renders as a json list under the resulting `cni_network_config`
value `exclude_namespaces`.  The Istio CNI plugin will ignore all pods in those Kubernetes namespaces.

### Helm chart parameters

| Option | Values | Default | Description |
|--------|--------|---------|-------------|
| `hub` | | | The container registry to pull the `install-cni` image. |
| `tag` | | | The container tag to use to pull the `install-cni` image. |
| `logLevel` | `panic`, `fatal`, `error`, `warn`, `info`, `debug` | `warn` | Logging level for CNI binary |
| `excludeNamespaces` | `[]string` | `[ istio-system ]` | List of namespaces to exclude from Istio pod check |
| `cniBinDir` | | `/opt/cni/bin` | Must be the same as the environment's `--cni-bin-dir` setting (`kubelet` parameter) |
| `cniConfDir` | | `/etc/cni/net.d` | Must be the same as the environment's `--cni-conf-dir` setting (`kubelet` parameter) |
| `cniConfFileName` | | None | Leave unset to auto-find the first file in the `cni-conf-dir` (as `kubelet` does).  Primarily used for testing `install-cni` plugin configuration.  If set, `install-cni` will inject the plugin configuration into this file in the `cni-conf-dir` |

### Hosted Kubernetes Usage

Not all hosted Kubernetes clusters are created with the `kubelet` configured to use the CNI plugin so
compatibility with this `istio-cni` solution is not ubiquitous.  The `istio-cni` plugin is expected
to work with any hosted Kubernetes leveraging CNI plugins.  The below table indicates the known CNI status
of many common Kubernetes environments.

| Hosted Cluster Type | Uses CNI |
|---------------------|----------|
| GKE 1.9+ default | N |
| GKE 1.9+ w/ [network-policy](https://cloud.google.com/kubernetes-engine/docs/how-to/network-policy) | Y |
| IKS (IBM cloud) | Y |
| EKS (AWS) | Y |
| AKS (Azure) | Y |
| Red Hat OpenShift 3.10| Y |

#### GKE Setup

1.  Refer to the procedure to [prepare a GKE cluster for Istio](/docs/setup/kubernetes/platform-setup/gke/) and
    enable [network-policy](https://cloud.google.com/kubernetes-engine/docs/how-to/network-policy) in your cluster.
    *  Note for existing clusters this redeploys the nodes.

1.  Install Istio via Helm including these options
    `--set istio_cni.enabled=true --set istio-cni.cniBinDir=/home/kubernetes/bin`

## Operational Details

The Istio CNI plugin handles Kubernetes pod create and delete events and does the following:

1.  Identify Istio user application pods with Istio sidecars requiring traffic redirection
1.  Perform pod network namespace details to redirect traffic to/from the Istio sidecar

### Identifying pods requiring traffic redirection

The Istio CNI plugin identifies pods requiring traffic redirection to/from the
accompanying Istio proxy sidecar but checking that the pod meets all of the following conditions:

1.  The pod is NOT in a Kubernetes namespace in the configured `exclude_namespaces` list
1.  The pod has a container named `istio-proxy`
1.  The pod has more than 1 container
1.  The pod has no annotation with key `sidecar.istio.io/inject` OR the value of the annotation is `true`

### Traffic redirection details

To redirect traffic in the application pod's network namespace to/from the Istio proxy sidecar, the Istio
CNI plugin configures the namespace's iptables.  The following table describes the parameters to the
redirect functionality.  The default values for the parameters are able to be overridden by setting the
corresponding application pod annotation key.

| Annotation Key | Values | Default | Description |
|----------------|--------|---------|-------------|
| `sidecar.istio.io/interceptionMode`| `REDIRECT`, `TPROXY` | `REDIRECT` | The iptables redirect mode to use. |
| `traffic.sidecar.istio.io/includeOutboundIPRanges` | `<IPCidr1>,<IPCidr2>,...` | "*" | Optional comma separated list of IP ranges in CIDR form to redirect to the sidecar proxy.  The default value of "*" redirects all traffic. |
| `traffic.sidecar.istio.io/excludeOutboundIPRanges` | `<IPCidr1>,<IPCidr2>,...` | | Optional comma separated list of IP ranges in CIDR form to be excluded from redirection.  Only applies when `includeOutboundIPRanges` is "*". |
| `traffic.sidecar.istio.io/includeInboundPorts` | `<port1>,<port2>,...` | Pod's list of `containerPorts` | Comma separated list of inbound ports for which traffic is to be redirected to the Istio proxy sidecar.  The value of "*" redirects all ports. |
| `traffic.sidecar.istio.io/excludeInboundPorts` | `<port1>,<port2>,...` | | Comma separated list of inbound ports to be excluded from redirection to the Istio sidecar proxy.  Only valid when `includeInboundPorts` is "*" |

### Logging

The Istio CNI plugin is run by the container runtime process space and, therefore, the log entries are added under
the `kubelet` process.

## Compatibility with other CNI plugins

The Istio CNI plugin maintains compatibility with the same set of CNI plugins as the current `NET_ADMIN`
`istio-init` container.

The Istio CNI plugin operates as a chained CNI plugin which means its configuration is added to the existing
CNI plugins configuration as a new configuration list element--see
[CNI specification reference](https://github.com/containernetworking/cni/blob/master/SPEC.md#network-configuration-lists).
When a pod is created or deleted, the container runtime invokes each plugin in the list in order.  The Istio
CNI plugin only performs actions to setup the application pod's traffic redirection to the injected Istio proxy
sidecar (using `iptables` in the pod's network namespace) and _should_ have no effect on the operations
performed by the base CNI plugin actually configuring the pod's networking setup.

