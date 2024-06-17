---
title: Install with Helm
description: Install Istio in Ambient mode with Helm.
weight: 4
aliases:
  - /docs/ops/ambient/install/helm-installation
  - /latest/docs/ops/ambient/install/helm-installation
owner: istio/wg-environments-maintainers
test: yes
---

This guide shows you how to install Istio in ambient mode with Helm.
Aside from following the demo in [Getting Started with Ambient Mode](/docs/ambient/getting-started/),
we encourage the use of Helm to install Istio for use in ambient mode. Helm helps you manage components separately, and you can easily upgrade the components to the latest version.

## Prerequisites

1. Check the [Platform-Specific Prerequisites](/docs/ambient/install/platform-prerequisites).

1. [Install the Helm client](https://helm.sh/docs/intro/install/), version 3.6 or above.

1. Configure the Helm repository:

    {{< text syntax=bash snip_id=configure_helm >}}
    $ helm repo add istio https://istio-release.storage.googleapis.com/charts
    $ helm repo update
    {{< /text >}}

*See [helm repo](https://helm.sh/docs/helm/helm_repo/) for command documentation.*

Istio is made up of multiple components which belong to either the {{< gloss >}}data plane{{< /gloss >}} or {{< gloss >}}control plane{{< /gloss >}}, and different components may have different effects on your applications when upgraded - for production deployments, it is strongly recommended to install the components separately to allow for more control during upgrades. Consult the [operations guidelines](/docs/ops/best-practices/deployment/) for production deployment considerations.

For installing Istio with support for the {{< gloss >}}ambient{{< /gloss >}} data plane mode in a non-production cluster, we provide a simple Helm chart which bundles all the required Helm charts.

## Simple install

The `ambient` Helm chart composes all the components that enable the use of Istio's ambient data plane mode:

{{< text syntax=bash snip_id=install_ambient_chart >}}
$ helm install istio-ambient istio/ambient -n istio-system --create-namespace --wait
{{< /text >}}

Proceed to [verifying the installation](#verify-the-installation) or [installing an ingress gateway (optional)](#install-an-ingress-gateway-optional)

## Install the components individually

### Install the base component

The `base` chart contains the basic CRDs and cluster roles required to set up Istio.
This should be installed prior to any other Istio component.

{{< text syntax=bash snip_id=install_base >}}
$ helm install istio-base istio/base -n istio-system --create-namespace --wait
{{< /text >}}

### Install the CNI component

The `cni` chart installs the Istio CNI plugin. It is responsible for detecting the pods that belong to the ambient mesh, and configuring the traffic redirection between pods and the ztunnel node proxy (which will be installed later).

{{< text syntax=bash snip_id=install_cni >}}
$ helm install istio-cni istio/cni -n istio-system --set profile=ambient --wait
{{< /text >}}

### Install the Istiod component

The `istiod` chart installs a revision of Istiod. Istiod is the control plane component that manages and
configures the proxies to route traffic within the mesh.

{{< text syntax=bash snip_id=install_discovery >}}
$ helm install istiod istio/istiod --namespace istio-system --set profile=ambient --wait
{{< /text >}}

### Install the ztunnel component

The `ztunnel` chart installs the ztunnel DaemonSet, which is the node proxy component of Istio's ambient mode.

{{< text syntax=bash snip_id=install_ztunnel >}}
$ helm install ztunnel istio/ztunnel -n istio-system --wait
{{< /text >}}

### Inspecting available chart configuration values

To view supported configuration options and documentation for any published chart, run:

`helm show values`, for example:

{{< text syntax=bash >}}
$ helm show values istio/istiod
{{< /text >}}

{{< text syntax=bash >}}
$ helm show values istio/cni
{{< /text >}}

Changing values can break your installation, and should be done with care.

Proceed to [verifying the installation](#verify-the-installation) or [installing an ingress gateway (optional)](#install-an-ingress-gateway-optional)

## Install an ingress gateway (optional)

To install an ingress gateway, run the command below:

{{< text syntax=bash snip_id=install_ingress >}}
$ helm install istio-ingress istio/gateway -n istio-ingress --create-namespace --wait
{{< /text >}}

If your Kubernetes cluster doesn't support the `LoadBalancer` service type (`type: LoadBalancer`) with a proper external IP assigned, run the above command without the `--wait` parameter to avoid the infinite wait. See [Installing Gateways](/docs/setup/additional-setup/gateway/) for in-depth documentation on gateway installation.

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

After installing ambient mode with Helm, you can follow the [Deploy the sample application](/docs/ambient/getting-started/#bookinfo) guide to deploy the sample application and ingress gateways, and then you can
[add your application to the ambient mesh](/docs/ambient/getting-started/#addtoambient).

## Uninstall

## Uninstall an ingress gateway (optional)

If you previously installed an ingress gateway, uninstall it by running the command below:

{{< text syntax=bash snip_id=delete_ingress >}}
$ helm delete istio-ingress -n istio-ingress --wait
$ kubectl delete namespace istio-ingress
{{< /text >}}

If your Kubernetes cluster doesn't support the `LoadBalancer` service type (`type: LoadBalancer`) with a proper external IP assigned, run the above command without the `--wait` parameter to avoid the infinite wait. See [Installing Gateways](/docs/setup/additional-setup/gateway/) for in-depth documentation on gateway installation.

### Simple uninstall

1. Delete the Istio ambient chart:

    {{< tip >}}
    [By design](https://github.com/helm/community/blob/main/hips/hip-0011.md#deleting-crds),
    deleting a chart via Helm doesn't delete the installed Custom
    Resource Definitions (CRDs) installed via the chart.
    {{< /tip >}}

    {{< text syntax=bash snip_id=delete_ambient_chart >}}
    $ helm delete istio-ambient -n istio-system --wait
    {{< /text >}}

1. Delete CRDs installed by Istio (optional)

    {{< warning >}}
    This will delete all created Istio resources.
    {{< /warning >}}

    {{< text syntax=bash snip_id=delete_crds_chart >}}
    $ kubectl get crd -oname | grep --color=never 'istio.io' | xargs kubectl delete
    {{< /text >}}

1. Delete the `istio-system` namespace:

    {{< text syntax=bash snip_id=delete_system_namespace_chart >}}
    $ kubectl delete namespace istio-system
    {{< /text >}}

### Uninstall the components individually

If you installed the charts individually above, you can uninstall Istio and its components by uninstalling those charts individually:

1. List all the Istio charts installed in `istio-system` namespace:

    {{< text syntax=bash >}}
    $ helm ls -n istio-system
    NAME            NAMESPACE       REVISION    UPDATED                                 STATUS      CHART           APP VERSION
    istio-base      istio-system    1           2024-04-17 22:14:45.964722028 +0000 UTC deployed    base-{{< istio_full_version >}}     {{< istio_full_version >}}
    istio-cni       istio-system    1           2024-04-17 22:14:45.964722028 +0000 UTC deployed    cni-{{< istio_full_version >}}      {{< istio_full_version >}}
    istiod          istio-system    1           2024-04-17 22:14:45.964722028 +0000 UTC deployed    istiod-{{< istio_full_version >}}   {{< istio_full_version >}}
    ztunnel         istio-system    1           2024-04-17 22:14:45.964722028 +0000 UTC deployed    ztunnel-{{< istio_full_version >}}  {{< istio_full_version >}}
    {{< /text >}}

1. Delete the Istio CNI chart:

    {{< text syntax=bash snip_id=delete_cni >}}
    $ helm delete istio-cni -n istio-system
    {{< /text >}}

1. Delete the Istio ztunnel chart:

    {{< text syntax=bash snip_id=delete_ztunnel >}}
    $ helm delete ztunnel -n istio-system
    {{< /text >}}

1. Delete the Istio discovery chart:

    {{< text syntax=bash snip_id=delete_discovery >}}
    $ helm delete istiod -n istio-system
    {{< /text >}}

1. Delete the Istio base chart:

    {{< tip >}}
    [By design](https://github.com/helm/community/blob/main/hips/hip-0011.md#deleting-crds),
    deleting a chart via Helm doesn't delete the installed Custom
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
