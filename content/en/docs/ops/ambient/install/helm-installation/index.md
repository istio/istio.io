---
title: Install with Helm
description: How to install Ambient Mesh with Helm.
weight: 4
owner: istio/wg-environments-maintainers
test: yes
---

This guide shows you how to install ambient mesh with Helm.
Besides the demo in [Getting Started with Ambient Mesh](/docs/ops/ambient/getting-started/),
we **encourage** you to follow this guide to install ambient mesh.
Helm helps you manage components separately, and you can easily upgrade the components to the latest version.

## Prerequisites

1. Perform any necessary [platform-specific setup](/docs/setup/platform-setup/).

1. Check the [Requirements for Pods and Services](/docs/ops/deployment/requirements/).

1. [Install the Helm client](https://helm.sh/docs/intro/install/), version 3.6 or above.

1. Configure the Helm repository:

    {{< text syntax=bash snip_id=configure_helm >}}
    $ helm repo add istio https://istio-release.storage.googleapis.com/charts
    $ helm repo update
    {{< /text >}}

*See [helm repo](https://helm.sh/docs/helm/helm_repo/) for command documentation.*

## Installing the Components

### Installing the base Component

The `base` chart contains the basic CRDs and cluster roles required to set up Istio.
This should be installed prior to any other Istio component.

{{< text syntax=bash snip_id=install_base >}}
$ helm install istio-base istio/base -n istio-system --create-namespace
{{< /text >}}

### Installing the CNI Component

The **CNI** chart installs the Istio CNI Plugin. It is responsible for detecting the pods that belong to the ambient mesh,
and configuring the traffic redirection between the ztunnel DaemonSet, which will be installed later.

{{< text syntax=bash snip_id=install_cni >}}
$ helm install istio-cni istio/cni -n istio-system --set profile=ambient
{{< /text >}}

### Installing the discovery Component

The `istiod` chart installs a revision of Istiod. Istiod is the control plane component that manages and
configures the proxies to route traffic within the mesh.

{{< text syntax=bash snip_id=install_discovery >}}
$ helm install istiod istio/istiod --namespace istio-system --set profile=ambient
{{< /text >}}

### Installing the ztunnel component

The `ztunnel` chart installs the ztunnel DaemonSet, which is the node-proxy component of ambient.

{{< text syntax=bash snip_id=install_ztunnel >}}
$ helm install ztunnel istio/ztunnel -n istio-system
{{< /text >}}

### (Optional) Install an ingress gateway

{{< warning >}}
The namespace the gateway is deployed in must not have a `istio-injection=disabled` label.
See [Controlling the injection policy](/docs/setup/additional-setup/sidecar-injection/#controlling-the-injection-policy) for more info.
{{< /warning >}}

{{< text syntax=bash snip_id=install_ingress >}}
$ helm install istio-ingress istio/gateway -n istio-ingress --wait --create-namespace
{{< /text >}}

See [Installing Gateways](/docs/setup/additional-setup/gateway/) for in-depth documentation on gateway installation.

## Configuration

To view supported configuration options and documentation, run:

{{< text syntax=bash >}}
$ helm show values istio/istiod
{{< /text >}}

## Verifying the Installation

### Verifying the workload status

After installing all the components, you can check the Helm deployment status with:

{{< text syntax=bash snip_id=show_components >}}
$ helm ls -n istio-system
NAME            NAMESPACE       REVISION    UPDATED         STATUS      CHART           APP VERSION
istio-base      istio-system    1           ... ... ... ... deployed    base-1.0.0      1.0.0
istio-cni       istio-system    1           ... ... ... ... deployed    cni-1.0.0       1.0.0
istiod          istio-system    1           ... ... ... ... deployed    istiod-1.0.0    1.0.0
ztunnel         istio-system    1           ... ... ... ... deployed    ztunnel-1.0.0   1.0.0
{{< /text >}}

You can check the status of the deployed pods with:

{{< text syntax=bash snip_id=check_pods >}}
$ kubectl get pods -n istio-system
NAME                             READY   STATUS    RESTARTS   AGE
istio-cni-node-g97z5             1/1     Running   0          10m
istiod-5f4c75464f-gskxf          1/1     Running   0          10m
ztunnel-c2z4s                    1/1     Running   0          10m
{{< /text >}}

### Verifying with the Sample Application

After installing ambient with Helm, you can follow
[Deploy the sample application](/docs/ops/ambient/getting-started/#bookinfo)
guide to deploy the sample application and ingress gateways, and then you can
[add your application to ambient](/docs/ops/ambient/getting-started/#addtoambient).

## Uninstall

You can uninstall Istio and its components by uninstalling the charts
installed above.

1. List all the Istio charts installed in `istio-system` namespace:

    {{< text syntax=bash >}}
    $ helm ls -n istio-system
    NAME            NAMESPACE       REVISION    UPDATED         STATUS      CHART           APP VERSION
    istio-base      istio-system    1           ... ... ... ... deployed    base-1.0.0      1.0.0
    istio-cni       istio-system    1           ... ... ... ... deployed    cni-1.0.0       1.0.0
    istiod          istio-system    1           ... ... ... ... deployed    istiod-1.0.0    1.0.0
    ztunnel         istio-system    1           ... ... ... ... deployed    ztunnel-1.0.0   1.0.0
    {{< /text >}}

1. (Optional) Delete any Istio gateway chart installations:

    {{< text syntax=bash snip_id=delete_ingress >}}
    $ helm delete istio-ingress -n istio-ingress
    $ kubectl delete namespace istio-ingress
    {{< /text >}}

1. Delete Istio CNI chart:

    {{< text syntax=bash snip_id=delete_cni >}}
    $ helm delete istio-cni -n istio-system
    {{< /text >}}

1. Delete Istio ztunnel chart:

    {{< text syntax=bash snip_id=delete_ztunnel >}}
    $ helm delete ztunnel -n istio-system
    {{< /text >}}

1. Delete Istio discovery chart:

    {{< text syntax=bash snip_id=delete_discovery >}}
    $ helm delete istiod -n istio-system
    {{< /text >}}

1. Delete Istio base chart:

    {{< tip >}}
    By design, deleting a chart via Helm doesn't delete the installed Custom
    Resource Definitions (CRDs) installed via the chart.
    {{< /tip >}}

    {{< text syntax=bash snip_id=delete_base >}}
    $ helm delete istio-base -n istio-system
    {{< /text >}}

1. Delete CRDs Installed by Istio (Optional)

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
