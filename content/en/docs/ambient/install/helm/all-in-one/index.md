---
title: Install with Helm (simple)
description: Install Istio with support for ambient mode with Helm using a single chart.
weight: 4
owner: istio/wg-environments-maintainers
test: yes
draft: true
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

<!-- ### Base components -->

<!-- The `base` chart contains the basic CRDs and cluster roles required to set up Istio. -->
<!-- This should be installed prior to any other Istio component. -->

<!-- {{< text syntax=bash snip_id=install_base >}} -->
<!-- $ helm install istio-base istio/base -n istio-system --create-namespace --wait -->
<!-- {{< /text >}} -->

### Install or upgrade the Kubernetes Gateway API CRDs

{{< boilerplate gateway-api-install-crds >}}

### Install the Istio ambient control plane and data plane

The `ambient` chart installs all the Istio data plane and control plane components required for
ambient, using a Helm wrapper chart that composes the individual component charts.

{{< warning >}}
Note that if you install everything as part of this wrapper chart, you can only upgrade or uninstall
ambient via this wrapper chart - you cannot upgrade or uninstall sub-components individually.
{{< /warning >}}

{{< text syntax=bash snip_id=install_ambient_aio >}}
$ helm install istio-ambient istio/ambient --namespace istio-system --create-namespace --wait
{{< /text >}}

### Ingress gateway (optional)

{{< tip >}}
{{< boilerplate gateway-api-future >}}
If you use the Gateway API, you do not need to install and manage an ingress gateway Helm chart as described below.
Refer to the [Gateway API task](/docs/tasks/traffic-management/ingress/gateway-api/#automated-deployment) for details.
{{< /tip >}}

To install an ingress gateway, run the command below:

{{< text syntax=bash snip_id=install_ingress >}}
$ helm install istio-ingress istio/gateway -n istio-ingress --create-namespace --wait
{{< /text >}}

If your Kubernetes cluster doesn't support the `LoadBalancer` service type (`type: LoadBalancer`) with a proper external IP assigned, run the above command without the `--wait` parameter to avoid the infinite wait. See [Installing Gateways](/docs/setup/additional-setup/gateway/) for in-depth documentation on gateway installation.

## Configuration

The ambient wrapper chart composes the following component Helm charts

- base
- istiod
- istio-cni
- ztunnel

Default configuration values can be changed using one or more `--set <parameter>=<value>` arguments. Alternatively, you can specify several parameters in a custom values file using the `--values <file>` argument.

You can override component-level settings via the wrapper chart just like you can when installing
the components individually, by prefixing the value path with the name of the component.

Example:

{{< text syntax=bash snip_id=none >}}
$ helm install istiod istio/istiod --set hub=gcr.io/istio-testing
{{< /text >}}

Becomes:

{{< text syntax=bash snip_id=none >}}
$ helm install istio-ambient istio/ambient --set istiod.hub=gcr.io/istio-testing
{{< /text >}}

when set via the wrapper chart.

To view supported configuration options and documentation for each sub-component, run:

{{< text syntax=bash >}}
$ helm show values istio/istiod
{{< /text >}}

for each component you are interested in.

Full details on how to use and customize Helm installations are available in [the sidecar installation documentation](/docs/setup/install/helm/).

## Verify the installation

### Verify the workload status

After installing all the components, you can check the Helm deployment status with:

{{< text syntax=bash snip_id=show_components >}}
$ helm ls -n istio-system
NAME            NAMESPACE       REVISION    UPDATED                                 STATUS      CHART           APP VERSION
istio-ambient      istio-system    1           2024-04-17 22:14:45.964722028 +0000 UTC deployed    ambient-{{< istio_full_version >}}     {{< istio_full_version >}}
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

You can uninstall Istio and its components by uninstalling the chart
installed above.

1. Uninstall all Istio components

    {{< text syntax=bash snip_id=delete_ambient_aio >}}
    $ helm delete istio-ambient -n istio-system
    {{< /text >}}

1. (Optional) Delete any Istio gateway chart installations:

    {{< text syntax=bash snip_id=delete_ingress >}}
    $ helm delete istio-ingress -n istio-ingress
    $ kubectl delete namespace istio-ingress
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
