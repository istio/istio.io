---
title: Upgrade with Helm
linktitle: Upgrade with Helm
description: Upgrade and configure Istio for in-depth evaluation.
weight: 27
keywords: [kubernetes,helm]
owner: istio/wg-environments-maintainers
icon: helm
test: no
---

Follow this guide to upgrade and configure an Istio mesh using
[Helm](https://helm.sh/docs/) for in-depth evaluation.  This guy assumes you have already performed an
[installation with Helm](../../install/helm) for a previous minor or patch version of Istio.

{{< boilerplate helm-preamble >}}

{{< boilerplate helm-hub-tag >}}

{{< boilerplate helm-prereqs >}}

## Upgrade steps

Change directory to the root of the release package and then
follow the instructions below.

{{< boilerplate helm-jwt-warning >}}

### Create a backup

{{< boilerplate helm-backup >}}

### Migrating from non-Helm installations

{{< boilerplate helm-migration-nonhelm >}}

### Canary upgrade (recommended)

You can install a canary version of Istio control plane to validate that the new
version is compatible with your existing configuration and data plane using
the steps below:

{{< warning >}}
Note that when you install a canary version of the `istiod` service, the underlying
cluster-wide resources from the base chart are shared across your
primary and canary installations.

Currently, the support for canary upgrades for Istio ingress and egress
gateways is [actively in development](/docs/setup/upgrade/gateways/) and is considered `experimental`.
{{< /warning >}}

1. Install a canary version of the Istio discovery chart by setting the revision
   value:

    {{< text bash >}}
    $ helm install istiod-canary manifests/charts/istio-control/istio-discovery \
        --set revision=canary \
        -n istio-system
    {{< /text >}}

1. Verify that you have two versions of `istiod` installed in your cluster:

    {{< text bash >}}
    $ kubectl get pods -l app=istiod -L istio.io/rev -n istio-system
      NAME                            READY   STATUS    RESTARTS   AGE   REV
      istiod-5649c48ddc-dlkh8         1/1     Running   0          71m   default
      istiod-canary-9cc9fd96f-jpc7n   1/1     Running   0          34m   canary
    {{< /text >}}

1. Follow the steps [here](/docs/setup/upgrade/canary/) to test or migrate
   existing workloads to use the canary control plane.

1. Once you have verified and migrated your workloads to use the canary control
   plane, you can uninstall your old control plane:

    {{< text bash >}}
    $ helm delete istiod -n istio-system
    {{< /text >}}

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
    $ helm upgrade istio-base manifests/charts/base -n istio-system
    {{< /text >}}

1. Upgrade the Istio discovery chart:

    {{< text bash >}}
    $ helm upgrade istiod manifests/charts/istio-control/istio-discovery \
        -n istio-system
    {{< /text >}}

1. (Optional) Upgrade the Istio ingress or egress gateway charts if installed in
   your cluster:

    {{< text bash >}}
    $ helm upgrade istio-ingress manifests/charts/gateways/istio-ingress \
        -n istio-system
    $ helm upgrade istio-egress manifests/charts/gateways/istio-egress \
        -n istio-system
    {{< /text >}}

## Uninstall

You can uninstall Istio and its components by uninstalling the charts
installed above.

1. List all the Istio charts installed in `istio-system` namespace:

    {{< text bash >}}
    $ helm ls -n istio-system
    {{< /text >}}

1. (Optional) Delete Istio ingress/egress chart:

    {{< text bash >}}
    $ helm delete istio-egress -n istio-system
    $ helm delete istio-ingress -n istio-system
    {{< /text >}}

1. Delete Istio discovery chart:

    {{< text bash >}}
    $ helm delete istiod -n istio-system
    {{< /text >}}

1. Delete Istio base chart:

    {{< warning >}}
    By design, deleting a chart via Helm doesn't delete the installed Custom
    Resource Definitions (CRDs) installed via the chart.
    {{< /warning >}}

    {{< text bash >}}
    $ helm delete istio-base -n istio-system
    {{< /text >}}

1. Delete the `istio-system` namespace:

    {{< text bash >}}
    $ kubectl delete namespace istio-system
    {{< /text >}}

### (Optional) Deleting CRDs installed by Istio

Deleting CRDs permanently removes any Istio resources you have created in your
cluster. To permanently delete Istio CRDs installed in your cluster:

    {{< text bash >}}
    $ kubectl get crd | grep --color=never 'istio.io' | awk '{print $1}' \
        | xargs -n1 kubectl delete crd
    {{< /text >}}
