---
title: Customizable Install with Helm
description: Install and configure Istio for in-depth evaluation or production use.
weight: 27
keywords: [kubernetes,helm]
icon: helm
---

Follow this guide to install and configure an Istio mesh using
[Helm](https://helm.sh/docs/) for in-depth evaluation or production use.

The Helm charts used in this guide are the same underlying charts used when
installing Istio via [Istioctl](/docs/setup/install/istioctl/) or the
[IstioOperator API](/docs/setup/install/operator/).

## Prerequisites

1. [Download the Istio release](/docs/setup/getting-started/#download).

1. Perform any necessary [platform-specific setup](/docs/setup/platform-setup/).

1. Check the [Requirements for Pods and Services](/docs/ops/deployment/requirements/).

1. [Install a Helm client](https://helm.sh/docs/intro/install/) with a version higher than 3.1.

    {{< warning >}}
    Use a 3.x version of Helm. Helm 2 is not supported.
    {{< /warning >}}

The commands in this guide use the Helm charts that are included in the Istio release packages.

## Installation steps

Change directory to the root of the release and then
follow the instructions below.

1. Create a namespace for the `istio-system` components:

    {{< text bash >}}
    $ kubectl create namespace istio-system
    {{< /text >}}

1. Install the Istio base chart which contains cluster level resources like
   Custom Resource Definitions (CRDs), cluster role and cluster role bindings
   and service accounts used by the Istio components:

    {{< text bash >}}
    $ helm install --namespace istio-system istio-base manifests/charts/base
    {{< /text >}}

1. Install the Istio discovery (istiod) chart which includes the Istio control
   plane deployment and its associated configuration:

    {{< warning >}}
    The default chart configuration uses the secure third party tokens for Service
    Account token projections used by Istio proxies to authenticate with the Istio
    control plane. Before proceeding to install this chart, you should verify
    if third party tokens are enabled in your cluster by following the steps
    describe [here](/docs/ops/best-practices/security/#configure-third-party-service-account-tokens).
    If third party tokens are not enabled, you should add the option
    `--set global.jwtPolicy=first-party-jwt` to the following command.
    If the `jwtPolicy` is not set correctly, the `istiod` pod will not get
    deployed due to the missing `istio-token` volume.
    {{< /warning >}}

    {{< text bash >}}
    $ helm install --namespace istio-system istiod manifests/charts/istio-control/istio-discovery
    {{< /text >}}

1. (Optional) Install the Istio ingress gateway chart which contains the ingress
   gateway components:

    {{< warning >}}
    Similar to the discovery chart above, the default ingress gateway chart uses
    third party tokens. If third party tokens are not enabled, you should
    add the option `--set global.jwtPolicy=first-party-jwt` to the following command.
    If the `jwtPolicy` is not set correctly, the `istio-ingressgateway` pod will
    not get deployed due to the missing `istio-token` volume.
    {{< /warning >}}

    {{< text bash >}}
    $ helm install --namespace istio-system istio-ingress manifests/charts/gateways/istio-ingress
    {{< /text >}}

1. (Optional) Install the Istio egress gateway chart which contains the egress
   gateway components:

    {{< warning >}}
    Similar to the discovery chart above, the default egress gateway chart uses
    third party tokens. If third party tokens are not enabled, you should
    add the option `--set global.jwtPolicy=first-party-jwt` to the following command.
    If the `jwtPolicy` is not set correctly, the `istio-egressgateway` pod will
    not get deployed due to the missing `istio-token` volume.
    {{< /warning >}}

    {{< text bash >}}
    $ helm install --namespace istio-system istio-egress manifests/charts/gateways/istio-egress
    {{< /text >}}

## Verifying the installation

1. Ensure all Kubernetes pods in `istio-system` namespace are deployed and have a
   `STATUS` of `Running`:

    {{< text bash >}}
    $ kubectl get pods -n istio-system
    {{< /text >}}

## Uninstall

You can uninstall Istio and its components by uninstalling the charts
installed above.

1. List all the Istio charts installed in `istio-system` namespace:

    {{< text bash >}}
    $ helm ls --namespace istio-system
    {{< /text >}}

1. (Optional) Delete Istio ingress/egress chart:

    {{< text bash >}}
    $ helm delete --namespace istio-system istio-egress
    $ helm delete --namespace istio-system istio-ingress
    {{< /text >}}

1. Delete Istio discovery chart:

    {{< text bash >}}
    $ helm delete --namespace istio-system istiod
    {{< /text >}}

1. Delete Istio base chart:

    {{< warning >}}
    By desgin, deleting a chart via Helm doesn't delete the installed Custom
    Resource Definitions (CRDs) installed via the chart.
    {{< /warning >}}

    {{< text bash >}}
    $ helm delete --namespace istio-system istio-base
    {{< /text >}}

1. Delete the `istio-system` namespace:

    {{< text bash >}}
    $ kubectl delete namespace istio-system
    {{< /text >}}

### Deleting CRDs installed by Istio

Deleting CRDs permanently removes any Istio resources you have created in your
cluster. To permanently delete Istio CRDs installed in your cluster:

    {{< text bash >}}
    $ kubectl get crd | grep --color=never 'istio.io' | awk '{print $1}' \
        | xargs -n1 kubectl delete crd
    {{< /text >}}
