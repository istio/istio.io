---
title: Upgrade with Helm
linktitle: Upgrade with Helm
description: Upgrade and configure Istio for in-depth evaluation.
weight: 27
keywords: [kubernetes,helm]
owner: istio/wg-environments-maintainers
test: no
---

Follow this guide to upgrade and configure an Istio mesh using
[Helm](https://helm.sh/docs/) for in-depth evaluation.  This guide assumes you have already performed an
[installation with Helm](../../install/helm) for a previous minor or patch version of Istio.

{{< boilerplate helm-preamble >}}

{{< boilerplate helm-hub-tag >}}

{{< boilerplate helm-prereqs >}}

## Upgrade steps

Change directory to the root of the release package and then
follow the instructions below.

{{< boilerplate helm-jwt-warning >}}

Before upgrading Istio, it is recommended to run the `istioctl x precheck` command to make sure the upgrade is compatible with your environment.

{{< text bash >}}
$ istioctl x precheck
✔ No issues found when checking the cluster. Istio is safe to install or upgrade!
To get started, check out https://istio.io/latest/docs/setup/getting-started/
{{< /text >}}

### Create a backup

{{< boilerplate helm-backup >}}

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

Please refer to the uninstall section in our [Helm install guide](/docs/setup/install/helm/#uninstall).

