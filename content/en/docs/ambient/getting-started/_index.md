---
title: Getting Started
description: How to deploy and install Istio in ambient mode.
weight: 2
aliases:
  - /docs/ops/ambient/getting-started
  - /latest/docs/ops/ambient/getting-started
owner: istio/wg-networking-maintainers
skip_list: true
test: yes
---

This guide shows you how to install Istio in ambient mode with Helm, in a non-production quick-start context.

If you are looking to install Istio's ambient mode in a production context, we recommend following the more [advanced Helm install guide](/docs/ambient/install/helm-installation/).

We generally encourage the use of Helm to install Istio when using ambient mode. Helm helps you manage components separately, is widely compatible with other tooling, and allows you to independently install and upgrade individual Istio components if desired.

## Prerequisites

1. Check the [Platform-Specific Prerequisites](/docs/ambient/install/platform-prerequisites).

1. [Install the Helm client](https://helm.sh/docs/intro/install/), version 3.6 or above.

1. Configure your Helm client to pull from the Istio Helm repository:

    {{< text syntax=bash snip_id=configure_helm >}}
    $ helm repo add istio https://istio-release.storage.googleapis.com/charts
    $ helm repo update
    {{< /text >}}

*See [the helm repo documentation](https://helm.sh/docs/helm/helm_repo/) for command documentation.*

Istio is made up of multiple components which belong to either the {{< gloss >}}data plane{{< /gloss >}} or the {{< gloss >}}control plane{{< /gloss >}}. Different components may have different effects on your applications and cluster networking when upgraded.

For installing Istio with support for the {{< gloss >}}ambient{{< /gloss >}} data plane mode quickly in a non-production cluster, we provide a simple Helm chart which bundles all the required Istio component Helm charts.

{{< tip >}}
For production deployments, it is strongly recommended to install the components separately via Helm to allow for more control during Istio upgrades. Consult the [full Helm install guide](/docs/ambient/install/helm-installation/) as well as the [operations guidelines](/docs/ops/best-practices/deployment/) for production deployment considerations.
{{< /tip >}}

## Install

The `ambient` Helm chart composes all the components that enable the use of Istio's ambient data plane mode:

{{< text syntax=bash snip_id=install_ambient_chart >}}
$ helm install istio-ambient istio/samples/ambient -n istio-system --create-namespace --wait
{{< /text >}}

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

Congratulations! You've successfully installed Istio with support for ambient mode. Continue to the next step to [install the demo application and add it to the ambient mesh](/docs/ambient/getting-started/deploy-sample-app/), or [add your own applications to the ambient mesh](/docs/ambient/usage/add-workloads/)

## Uninstall

### Uninstall an ingress gateway (optional)

If you previously installed an ingress gateway, uninstall it by running the command below:

{{< text syntax=bash snip_id=delete_ingress >}}
$ helm delete istio-ingress -n istio-ingress --wait
$ kubectl delete namespace istio-ingress
{{< /text >}}

If your Kubernetes cluster doesn't support the `LoadBalancer` service type (`type: LoadBalancer`) with a proper external IP assigned, run the above command without the `--wait` parameter to avoid the infinite wait. See [Installing Gateways](/docs/setup/additional-setup/gateway/) for in-depth documentation on gateway installation.

### Uninstall Istio

1. Remove the Istio ambient Helm installation:

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
