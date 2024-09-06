---
title: Install with Helm
description: Install Istio with support for ambient mode with Helm.
weight: 4
aliases:
  - /docs/ops/ambient/install/helm-installation
  - /latest/docs/ops/ambient/install/helm-installation
  - /docs/ambient/install/helm-installation
  - /latest/docs/ambient/install/helm-installation
owner: istio/wg-environments-maintainers
test: yes
---

{{< tip >}}
Follow this guide to install and configure an Istio mesh with support for ambient mode.
If you are new to Istio, and just want to try it out, follow the
[quick start instructions](/docs/ambient/getting-started) instead.
{{< /tip >}}

We encourage the use of Helm to install Istio for production use in ambient mode. To allow controlled upgrades, the control plane and data plane components are packaged and installed separately. (Because the ambient data plane is split across [two components](/docs/ambient/architecture/data-plane), the ztunnel and waypoints, upgrades involve separate steps for these components.)

## Prerequisites

1. Check the [Platform-Specific Prerequisites](/docs/ambient/install/platform-prerequisites).

1. [Install the Helm client](https://helm.sh/docs/intro/install/), version 3.6 or above.

1. Configure the Helm repository:

    {{< text syntax=bash snip_id=configure_helm >}}
    $ helm repo add istio https://istio-release.storage.googleapis.com/charts
    $ helm repo update
    {{< /text >}}

## Install the control plane

Default configuration values can be changed using one or more `--set <parameter>=<value>` arguments. Alternatively, you can specify several parameters in a custom values file using the `--values <file>` argument.

{{< tip >}}
You can display the default values of configuration parameters using the `helm show values <chart>` command or refer to Artifact Hub chart documentation for the [base](https://artifacthub.io/packages/helm/istio-official/base?modal=values), [istiod](https://artifacthub.io/packages/helm/istio-official/istiod?modal=values), [CNI](https://artifacthub.io/packages/helm/istio-official/cni?modal=values), [ztunnel](https://artifacthub.io/packages/helm/istio-official/ztunnel?modal=values) and [Gateway](https://artifacthub.io/packages/helm/istio-official/gateway?modal=values) chart configuration parameters.
{{< /tip >}}

Full details on how to use and customize Helm installations are available in [the sidecar installation documentation](/docs/setup/install/helm/).

Unlike [istioctl](/docs/ambient/install/istioctl/) profiles, which group together components to be installed or removed, Helm profiles simply set groups of configuration values.

### Base components

The `base` chart contains the basic CRDs and cluster roles required to set up Istio.
This should be installed prior to any other Istio component.

{{< text syntax=bash snip_id=install_base >}}
$ helm install istio-base istio/base -n istio-system --create-namespace --wait
{{< /text >}}

### Install or upgrade the Kubernetes Gateway API CRDs

{{< boilerplate gateway-api-install-crds >}}

### istiod control plane

The `istiod` chart installs a revision of Istiod. Istiod is the control plane component that manages and
configures the proxies to route traffic within the mesh.

{{< text syntax=bash snip_id=install_istiod >}}
$ helm install istiod istio/istiod --namespace istio-system --set profile=ambient --wait
{{< /text >}}

### CNI node agent

The `cni` chart installs the Istio CNI node agent. It is responsible for detecting the pods that belong to the ambient mesh, and configuring the traffic redirection between pods and the ztunnel node proxy (which will be installed later).

{{< text syntax=bash snip_id=install_cni >}}
$ helm install istio-cni istio/cni -n istio-system --set profile=ambient --wait
{{< /text >}}

## Install the data plane

### ztunnel DaemonSet

The `ztunnel` chart installs the ztunnel DaemonSet, which is the node proxy component of Istio's ambient mode.

{{< text syntax=bash snip_id=install_ztunnel >}}
$ helm install ztunnel istio/ztunnel -n istio-system --wait
{{< /text >}}

### Ingress gateway (optional)

To install an ingress gateway, run the command below:

{{< text syntax=bash snip_id=install_ingress >}}
$ helm install istio-ingress istio/gateway -n istio-ingress --create-namespace --wait
{{< /text >}}

If your Kubernetes cluster doesn't support the `LoadBalancer` service type (`type: LoadBalancer`) with a proper external IP assigned, run the above command without the `--wait` parameter to avoid the infinite wait. See [Installing Gateways](/docs/setup/additional-setup/gateway/) for in-depth documentation on gateway installation.

## Configuration

To view supported configuration options and documentation, run:

{{< text syntax=bash >}}
$ helm show values istio/istiod
{{< /text >}}

## Verify the installation

### Verify the workload status

After installing all the components, you can check the Helm deployment status with:

{{< text syntax=bash snip_id=show_components >}}
$ helm ls -n istio-system
NAME            NAMESPACE       REVISION    UPDATED                                 STATUS      CHART           APP VERSION
istio-base      istio-system    1           2024-04-17 22:14:45.964722028 +0000 UTC deployed    base-{{< istio_full_version >}}     {{< istio_full_version >}}
istio-cni       istio-system    1           2024-04-17 22:14:45.964722028 +0000 UTC deployed    cni-{{< istio_full_version >}}      {{< istio_full_version >}}
istiod          istio-system    1           2024-04-17 22:14:45.964722028 +0000 UTC deployed    istiod-{{< istio_full_version >}}   {{< istio_full_version >}}
ztunnel         istio-system    1           2024-04-17 22:14:45.964722028 +0000 UTC deployed    ztunnel-{{< istio_full_version >}}  {{< istio_full_version >}}
{{< /text >}}

You can check the status of the deployed pods with:

{{< text syntax=bash snip_id=check_pods >}}
$ kubectl get pods -n istio-system
NAME                             READY   STATUS    RESTARTS   AGE
istio-cni-node-g97z5             1/1     Running   0          10m
istiod-5f4c75464f-gskxf          1/1     Running   0          10m
ztunnel-c2z4s                    1/1     Running   0          10m
{{< /text >}}

### Verify with the sample application

After installing ambient mode with Helm, you can follow the [Deploy the sample application](/docs/ambient/getting-started/deploy-sample-app/) guide to deploy the sample application and ingress gateways, and then you can
[add your application to the ambient mesh](/docs/ambient/getting-started/secure-and-visualize/#add-bookinfo-to-the-mesh).

## Uninstall

You can uninstall Istio and its components by uninstalling the charts
installed above.

1. List all the Istio charts installed in `istio-system` namespace:

    {{< text syntax=bash >}}
    $ helm ls -n istio-system
    NAME            NAMESPACE       REVISION    UPDATED                                 STATUS      CHART           APP VERSION
    istio-base      istio-system    1           2024-04-17 22:14:45.964722028 +0000 UTC deployed    base-{{< istio_full_version >}}     {{< istio_full_version >}}
    istio-cni       istio-system    1           2024-04-17 22:14:45.964722028 +0000 UTC deployed    cni-{{< istio_full_version >}}      {{< istio_full_version >}}
    istiod          istio-system    1           2024-04-17 22:14:45.964722028 +0000 UTC deployed    istiod-{{< istio_full_version >}}   {{< istio_full_version >}}
    ztunnel         istio-system    1           2024-04-17 22:14:45.964722028 +0000 UTC deployed    ztunnel-{{< istio_full_version >}}  {{< istio_full_version >}}
    {{< /text >}}

1. (Optional) Delete any Istio gateway chart installations:

    {{< text syntax=bash snip_id=delete_ingress >}}
    $ helm delete istio-ingress -n istio-ingress
    $ kubectl delete namespace istio-ingress
    {{< /text >}}

1. Delete the ztunnel chart:

    {{< text syntax=bash snip_id=delete_ztunnel >}}
    $ helm delete ztunnel -n istio-system
    {{< /text >}}

1. Delete the Istio CNI chart:

    {{< text syntax=bash snip_id=delete_cni >}}
    $ helm delete istio-cni -n istio-system
    {{< /text >}}

1. Delete the istiod control plane chart:

    {{< text syntax=bash snip_id=delete_istiod >}}
    $ helm delete istiod -n istio-system
    {{< /text >}}

1. Delete the Istio base chart:

    {{< tip >}}
    By design, deleting a chart via Helm doesn't delete the installed Custom
    Resource Definitions (CRDs) installed via the chart.
    {{< /tip >}}

    {{< text syntax=bash snip_id=delete_base >}}
    $ helm delete istio-base -n istio-system
    {{< /text >}}

1. Delete CRDs installed by Istio (optional)

    {{< warning >}}
    This will delete all created Istio resources.
    {{< /warning >}}

    {{< text syntax=bash snip_id=delete_crds >}}
    $ kubectl get crd -oname | grep --color=never 'istio.io' | xargs kubectl delete
    {{< /text >}}

1. Delete the `istio-system` namespace:

    {{< text syntax=bash snip_id=delete_system_namespace >}}
    $ kubectl delete namespace istio-system
    {{< /text >}}
