---
title: Install with Helm [Experimental]
linktitle: Install with Helm
description: Install and configure Istio for in-depth evaluation or production use.
weight: 27
keywords: [kubernetes,helm]
owner: istio/wg-environments-maintainers
icon: helm
test: no
---

{{< warning >}}
This feature is actively in development and is considered `pre-alpha`.
{{< /warning >}}

Follow this guide to install and configure an Istio mesh using
[Helm](https://helm.sh/docs/) for in-depth evaluation or production use.

The Helm charts used in this guide are the same underlying charts used when
installing Istio via [Istioctl](/docs/setup/install/istioctl/) or the
[Operator](/docs/setup/install/operator/).

## Prerequisites

1. [Download the Istio release](/docs/setup/getting-started/#download).

1. Perform any necessary [platform-specific setup](/docs/setup/platform-setup/).

1. Check the [Requirements for Pods and Services](/docs/ops/deployment/requirements/).

1. [Install a Helm client](https://helm.sh/docs/intro/install/) with a version higher than 3.1.1.

    {{< warning >}}
    Helm 2 is not supported for installing Istio.
    {{< /warning >}}

The commands in this guide use the Helm charts that are included in the Istio release package.

## Installation steps

Change directory to the root of the release package and then
follow the instructions below.

1. Create a namespace `istio-system` for Istio components:

    {{< text bash >}}
    $ kubectl create namespace istio-system
    {{< /text >}}

1. Install the Istio base chart which contains cluster-wide resources used by
   the Istio control plane:

    {{< text bash >}}
    $ helm install --namespace istio-system istio-base manifests/charts/base
    {{< /text >}}

    {{< warning >}}
    The default chart configuration uses the secure third party tokens for service
    account token projections used by Istio proxies to authenticate with the Istio
    control plane. Before proceeding to install any of the charts below, you should
    verify if third party tokens are enabled in your cluster by following the steps
    describe [here](/docs/ops/best-practices/security/#configure-third-party-service-account-tokens).
    If third party tokens are not enabled, you should add the option
    `--set global.jwtPolicy=first-party-jwt` to the Helm install commands.
    If the `jwtPolicy` is not set correctly, pods associated with `istiod`,
    gateways or workloads with injected Envoy proxies will not get deployed due
    to the missing `istio-token` volume.
    {{< /warning >}}

1. Install the Istio discovery chart which deploys the `istiod` service:

    {{< text bash >}}
    $ helm install --namespace istio-system istiod manifests/charts/istio-control/istio-discovery
    {{< /text >}}

1. (Optional) Install the Istio ingress gateway chart which contains the ingress
   gateway components:

    {{< text bash >}}
    $ helm install --namespace istio-system istio-ingress manifests/charts/gateways/istio-ingress
    {{< /text >}}

1. (Optional) Install the Istio egress gateway chart which contains the egress
   gateway components:

    {{< text bash >}}
    $ helm install --namespace istio-system istio-egress manifests/charts/gateways/istio-egress
    {{< /text >}}

## Verifying the installation

1. Ensure all Kubernetes pods in `istio-system` namespace are deployed and have a
   `STATUS` of `Running`:

    {{< text bash >}}
    $ kubectl get pods -n istio-system
    {{< /text >}}

## Upgrading using Helm

Before upgrading Istio in your cluster, we recommend creating a backup of your
custom configurations, and restoring it from backup if necessary:

{{< text bash >}}
$ kubectl get crds | grep 'istio.io' | cut -f1-1 -d "." | \
    xargs -n1 -I{} sh -c "kubectl get --all-namespaces -o yaml {}; echo ---" > $HOME/ISTIO_RESOURCE_BACKUP.yaml
{{< /text >}}

You can restore your custom configuration like this:

{{< text bash >}}
$ kubectl apply -f $HOME/ISTIO_RESOURCE_BACKUP.yaml
{{< /text >}}

### Migrating from non-Helm installations

If you're migrating from a version of Istio installed using `istioctl` or
Operator to Helm, you need to delete your current installation and re-install
Istio using Helm as described above.

{{< warning >}}
Uninstalling Istio can cause your custom Istio configurations to be lost
permanently so it is highly recommended to take a backup of your Istio
configuration before deleting Istio in your cluster.
{{< /warning >}}

You can follow steps mentioned in the
[Istioctl uninstall guide](/docs/setup/install/istioctl#uninstall-istio) or
[Operator uninstall guide](/docs/setup/install/operator/#uninstall)
depending upon your installation method.

### In place upgrade

You can perform an in place upgrade of Istio in your cluster using the Helm
upgrade workflow.

{{< warning >}}
This upgrade path is only supported from Istio version 1.8 and above.

Add your override values file or custom options to the commands below to
preserve your custom configuration during Helm upgrades.
{{< /warning >}}

1. Upgrade the Istio base chart:

    {{< text bash >}}
    $ helm upgrade --namespace istio-system istio-base manifests/charts/base
    {{< /text >}}

1. Upgrade the Istio discovery chart:

    {{< text bash >}}
    $ helm upgrade --namespace istio-system istiod manifests/charts/istio-control/istio-discovery
    {{< /text >}}

1. (Optional) Upgrade the Istio ingress or egress gateway charts if installed in
   your cluster:

    {{< text bash >}}
    $ helm upgrade --namespace istio-system istio-ingress manifests/charts/gateways/istio-ingress
    $ helm upgrade --namespace istio-system istio-egress manifests/charts/gateways/istio-egress
    {{< /text >}}

### Canary Upgrade

You can install a canary version of Istio control plane to validate that the new
version is compatible with your existing configuration and data plane using
the steps below:

1. Install a canary version of the Istio discovery chart by setting the revision
   value:

    {{< text bash >}}
    $ helm install --namespace istio-system istiod-canary manifests/charts/istio-control/istio-discovery --set revision=canary
    {{< /text >}}

1. Verify that you have two versions of `istiod` installed in your cluster:

    {{< text bash >}}
    $ kubectl get pods -n istio-system -l app=istiod -L istio.io/rev
      NAME                            READY   STATUS    RESTARTS   AGE   REV
      istiod-5649c48ddc-dlkh8         1/1     Running   0          71m   default
      istiod-canary-9cc9fd96f-jpc7n   1/1     Running   0          34m   canary
    {{< /text >}}

1. Follow the steps [here](/docs/setup/upgrade/#data-plane) to test or migrate
   existing workloads to use the canary control plane.

1. Once you have verified and migrated your workloads to use the canary control
   plane, you can uninstall your old control plane:

    {{< text bash >}}
    $ helm delete --namespace istio-system istiod
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
