---
title: Istio Ambient Installation Guide 
description: Installation guide for Istio Ambient. 
weight: 2
owner: istio/wg-networking-maintainers
test: n/a
---

## Introduction 

This guide describe installation options and procedures for Istio Ambient mesh.  The two primary installation methods supported are (1) Installation via the `istioctl` cli  (2) Installation via `helm`.  

## Installation

### Pre-requisites & Supported Topologies

Ztunnel proxies are automatically installed when one of the supported installation methods is used to install Istio Ambient mesh.  The minimum Istio version required for the functionality described in this guide is 1.18.0. At this time, the ambient mode is only supported for deployment on Kubernetes clusters, support for deployment on non-Kubernetes endpoints such as Virtual machines is expected to be a future capability. Additionally, only single cluster deployments are supported for Ambient mode.  Some limited multi-cluster scenarios may work currently in ambient mode but the behavior is not guaranteed and official support for multi-cluster operation is a future capability. Finally note that Ztunnel based L4 networking is primnarily focused on East-West mesh networking and can work with all of Istio's North-South networking options including Istio-native ingress and egress gateways as well as Kubernetes native Gateway API implementation. 

{{< tip >}}
A single Istio mesh can include pods and endpoints some of which operate using the sidecar proxy mode while others use the node level proxy of the Ambient architecture. 
{{< /tip >}}

### Understanding the Ztunnel Default Configuration

<< Consider breaking this out into bullets for easier reading TODO >>

One of the goals for the ztunnel proxy design is to provide a usable configuration out of the box with a fixed feature set and that does not require much, or any, custom configuration. Hence currently there are no configuration options that need to be set other than the `ambient` profile setting. Once this profile is used, this in turn sets sets 2 internal configuration parameters (as illustrated in the examples below) within the istioOperator which eventually set the configuration of the `ambient` mesh. In future there may be some additional limited configurability for ztunnel proxies. For now, the pod to ztunnel proxy networking (sometimes also called ztunnel redirection), ztunnel proxy to ztunnel proxy networking as well as ztunnel to other sidecar proxy networing all use a fixed default configuration which is not customizable. In particular, currently, the only option for pod to ztunnel networking setup is currently via the `istio-cni` and only via an internal ipTables based ztunnel traffic redirect option. There is no option to use `init-containers` unlike with sidecar proxies. Alternate forms of ztunnel traffic redirect such as ebpf are also not currently supported, although may be supported in future. Of course, once the baseline `ambient` mesh is installed, features such as Authorization policy (both L4 and L7) as well as other istio functions such as PeerAuthentication options for mutual-TLS are fully configurable similar to standard Istio.  In future release versions, some limited configurability may also be added to the ztunnel proxy layer. 

For the examples in this guide, we used a deployment of Istio Ambient on a `kind` cluster, although these should apply for any Kubernetes cluster version 1.18.0 or later. Refer to the Getting started guide on how to download the `istioctl` client and how to deploy a `kind` cluster. It would be recommended to have a cluster with more than 1 worker node in order to fully exercise the examples described in this guide. 

### Installation using istioctl

Setting Istio profile to `ambient` during installation is all that is needed to enable installation of Ztunnel and Layer-4 networking functionality. An instance of Istio mesh cannot be dynamically switched between sidecar mode and `ambient` mode. A prior instance of istio must be uninstalled before re-innstalling istio in `ambient` for the same set of user application endpoints and namespaces. 

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ istioctl install --set profile=ambient --set components.ingressGateways[0].enabled=true --set components.ingressGateways[0].name=istio-ingressgateway --skip-confirmation
{{< /text >}}

After running the above command, you’ll get the following output that indicates
five components (including {{< gloss "ztunnel" >}}Ztunnel{{< /gloss >}}) have been installed successfully!

{{< text syntax=plain snip_id=none >}}
✔ Istio core installed
✔ Istiod installed
✔ CNI installed
✔ Ingress gateways installed
✔ Ztunnel installed
✔ Installation complete
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ istioctl install --set profile=ambient --skip-confirmation
{{< /text >}}

After running the above command, you’ll get the following output that indicates
four components (including {{< gloss "ztunnel" >}}Ztunnel{{< /gloss >}}) have been installed successfully!

{{< text syntax=plain snip_id=none >}}
✔ Istio core installed
✔ Istiod installed
✔ CNI installed
✔ Ztunnel installed
✔ Installation complete
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

### Installation using Helm charts

An alternative to using istioctl is to use Helm based install of Istio Ambient.

## Setup Repo Info

{{< text bash >}}
$ helm repo add istio https://istio-release.storage.googleapis.com/charts
$ helm repo update
{{< /text >}}

*See [helm repo](https://helm.sh/docs/helm/helm_repo/) for command documentation.*

## Installing the Components

### Installing Base Component

The **Base** chart contains the basic CRDs and cluster roles required to set up Istio.
This should be installed prior to any other Istio component.

<<TO BE CONTINUED .. with content based on Han's PR >>


### Verifying Installation

Verify the installed components using the following commands:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ istioctl verify-install
{{< /text >}}

{{< text syntax=plain snip_id=none >}}
1 Istio control planes detected, checking --revision "default" only
✔ ClusterRole: istiod-istio-system.istio-system checked successfully
--snip--
✔ DaemonSet: ztunnel.istio-system checked successfully
✔ ServiceAccount: ztunnel.istio-system checked successfully
Checked 15 custom resource definitions
Checked 1 Istio Deployments
✔ Istio is installed and verified successfully
{{< /text >}}

{{< text bash >}}
$ istioctl verify-install | grep ztunnel
{{< /text >}}
{{< text syntax=plain snip_id=none >}}
✔ DaemonSet: ztunnel.istio-system checked successfully
✔ ServiceAccount: ztunnel.istio-system checked successfully
{{< /text >}}

{{< text bash >}}
$ kubectl get pods -n istio-system
{{< /text >}}
{{< text syntax=plain snip_id=none >}}
NAME                      READY   STATUS    RESTARTS   AGE
istio-cni-node-8kd8p      1/1     Running   0          6h32m
istio-cni-node-mtzmz      1/1     Running   0          6h32m
istio-cni-node-smp7m      1/1     Running   0          6h32m
istiod-5c7f79574c-btwqx   1/1     Running   0          6h33m
ztunnel-2lb4n             1/1     Running   0          6h33m
ztunnel-wcqpp             1/1     Running   0          6h33m
ztunnel-zxrsx             1/1     Running   0          6h33m
{{< /text >}}

{{< text bash >}}
$ kubectl get daemonset -n istio-system
{{< /text >}}
{{< text syntax=plain snip_id=none >}}
NAME             DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
istio-cni-node   3         3         3       3            3           kubernetes.io/os=linux   6h34m
ztunnel          3         3         3       3            3           <none>                   6h35m
{{< /text >}}

{{< text bash >}}
$ kubectl get istiooperator/installed-state -n istio-system -o yaml
{{< /text >}}
{{< text syntax=plain snip_id=none >}}
--snip--
profile: ambient
  tag: 1.18.0
  values:
    base:
      enableCRDTemplates: false
      validationURL: ""
    cni:
      ambient:
        enabled: true
--snip--
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ istioctl verify-install
{{< /text >}}
{{< text syntax=plain snip_id=none >}}
1 Istio control planes detected, checking --revision "default" only
✔ ClusterRole: istiod-istio-system.istio-system checked successfully
--snip--
✔ DaemonSet: ztunnel.istio-system checked successfully
✔ ServiceAccount: ztunnel.istio-system checked successfully
Checked 15 custom resource definitions
Checked 1 Istio Deployments
✔ Istio is installed and verified successfully
{{< /text >}}

{{< text bash >}}
$ istioctl verify-install | grep ztunnel
{{< /text >}}
{{< text syntax=plain snip_id=none >}}
✔ DaemonSet: ztunnel.istio-system checked successfully
✔ ServiceAccount: ztunnel.istio-system checked successfully
{{< /text >}}

{{< text bash >}}
$ kubectl get pods -n istio-system
{{< /text >}}
{{< text syntax=plain snip_id=none >}}
NAME                      READY   STATUS    RESTARTS   AGE
istio-cni-node-8kd8p      1/1     Running   0          6h32m
istio-cni-node-mtzmz      1/1     Running   0          6h32m
istio-cni-node-smp7m      1/1     Running   0          6h32m
istiod-5c7f79574c-btwqx   1/1     Running   0          6h33m
ztunnel-2lb4n             1/1     Running   0          6h33m
ztunnel-wcqpp             1/1     Running   0          6h33m
ztunnel-zxrsx             1/1     Running   0          6h33m
{{< /text >}}

{{< text bash >}}
$ kubectl get daemonset -n istio-system
{{< /text >}}
{{< text syntax=plain snip_id=none >}}
NAME             DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
istio-cni-node   3         3         3       3            3           kubernetes.io/os=linux   6h34m
ztunnel          3         3         3       3            3           <none>                   6h35m
{{< /text >}}

{{< text bash >}}
$ kubectl get istiooperator/installed-state -n istio-system -o yaml
{{< /text >}}
{{< text syntax=plain snip_id=none >}}
--snip--
profile: ambient
  tag: 1.18.0
  values:
    base:
      enableCRDTemplates: false
      validationURL: ""
    cni:
      ambient:
        enabled: true
    ztunnel:
      enabled: true
  hub: docker.io/istio
  meshConfig:
    defaultConfig:
      proxyMetadata:
        ISTIO_META_ENABLE_HBONE: "true"
--snip--
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

The output of `istioctl verify-install` should indicate all items installed successfully including some ztunnel components as indicated in the examples.

If `ambient` is installed correctly, you should see 1 instance of ztunnel proxy pod per node in RUNNING state in the cluster (including control plane nodes and worker nodes). You should also see 1 instance of the `istio-cni` pods per node and a single instance of the `istiod` controller pod per cluster, all in RUNNING state. 

Confirm from the `istioOperator` output that profile is normally set to `ambient` (unless a custom profile is being used), ztunnel is set to enabled,  cni is enabled for `ambient`. Notice also proxyMetaData field has ISTIO_META_ENABLE_HBONE set to true. If using a custom installation profile, these fields must be set as described to enable `ambient` mode within a custom profile. It is recommended to start with the built-in `ambient` profile before trying any custom variations.


