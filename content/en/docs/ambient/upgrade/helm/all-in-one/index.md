---
title: Upgrade with Helm (simple)
description: Upgrading an ambient mode installation with Helm using a single chart
weight: 5
owner: istio/wg-environments-maintainers
test: yes
draft: true
---

Follow this guide to upgrade and configure an ambient mode installation using
[Helm](https://helm.sh/docs/). This guide assumes you have already performed an [ambient mode installation with Helm and the ambient wrapper chart](/docs/ambient/install/helm/all-in-one) with a previous version of Istio.

{{< warning >}}
Note that these upgrade instructions only apply if you are upgrading Helm installation created using the
ambient wrapper chart, if you installed via individual Helm component charts, see [the relevant upgrade docs](docs/ambient/upgrade/helm)
{{< /warning >}}

## Understanding ambient mode upgrades

{{< warning >}}
Note that if you install everything as part of this wrapper chart, you can only upgrade or uninstall
ambient via this wrapper chart - you cannot upgrade or uninstall sub-components individually.
{{< /warning >}}

## Prerequisites

### Prepare for the upgrade

Before upgrading Istio, we recommend downloading the new version of istioctl, and running `istioctl x precheck` to make sure the upgrade is compatible with your environment. The output should look something like this:

{{< text syntax=bash snip_id=istioctl_precheck >}}
$ istioctl x precheck
✔ No issues found when checking the cluster. Istio is safe to install or upgrade!
  To get started, check out <https://istio.io/latest/docs/setup/getting-started/>
{{< /text >}}

Now, update the Helm repository:

{{< text syntax=bash snip_id=update_helm >}}
$ helm repo update istio
{{< /text >}}

### Upgrade the Istio ambient control plane and data plane

{{< warning >}}
Upgrading using the wrapper chart in-place will briefly disrupt all ambient mesh traffic on the node,  **even with the use of revisions**. In practice the disruption period is a very small window, primarily affecting long-running connections.

Node cordoning and blue/green node pools are recommended to mitigate blast radius risk during production upgrades. See your Kubernetes provider documentation for details.
{{< /warning >}}

The `ambient` chart upgrades all the Istio data plane and control plane components required for
ambient, using a Helm wrapper chart that composes the individual component charts.

If you have customized your istiod installation, you can reuse the `values.yaml` file from previous upgrades or installs to keep settings consistent.

{{< text syntax=bash snip_id=upgrade_ambient_aio >}}
$ helm upgrade istio-ambient istio/ambient -n istio-system --wait
{{< /text >}}

### Upgrade manually deployed gateway chart (optional)

`Gateway`s that were [deployed manually](/docs/tasks/traffic-management/ingress/gateway-api/#manual-deployment) must be upgraded individually using Helm:

{{< text syntax=bash snip_id=none >}}
$ helm upgrade istio-ingress istio/gateway -n istio-ingress
{{< /text >}}
