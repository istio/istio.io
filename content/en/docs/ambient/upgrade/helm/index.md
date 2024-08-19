---
title: Upgrade with Helm
description: Upgrading an ambient mode installation with Helm.
weight: 5
aliases:
  - /docs/ops/ambient/upgrade/helm-upgrade
  - /latest/docs/ops/ambient/upgrade/helm-upgrade
  - /docs/ambient/upgrade/helm
  - /latest/docs/ambient/upgrade/helm
owner: istio/wg-environments-maintainers
test: yes
---

Follow this guide to upgrade and configure an ambient mode installation using
[Helm](https://helm.sh/docs/). This guide assumes you have already performed an [ambient mode installation with Helm](/docs/ambient/install/helm/) with a previous version of Istio.

{{< warning >}}
In contrast to sidecar mode, ambient mode supports moving application pods to an upgraded ztunnel proxy without a mandatory restart or reschedule of running application pods. However, upgrading ztunnel **will** cause all long-lived TCP connections on the upgraded node to reset, and Istio does not currently support canary upgrades of ztunnel.

Node cordoning and blue/green node pools are recommended to limit the blast radius of resets on application traffic during production upgrades. See your Kubernetes provider documentation for details.
{{< /warning >}}

## Understanding ambient upgrades

All Istio upgrades involve upgrading the control plane, data plane, and Istio CRDs. Because the ambient data plane is split across [two components](/docs/ambient/architecture/data-plane), the ztunnel and waypoints, upgrades involve separate steps for these components. Upgrading the control plane and CRDs is covered here in brief, but is essentially identical to [the process for upgrading these components in sidecar mode](/docs/setup/upgrade/canary/).

Like sidecar mode, gateways can make use of [revision tags](/docs/setup/upgrade/canary/#stable-revision-labels) to allow fine-grained control over ({{< gloss >}}gateway{{</ gloss >}}) upgrades, including waypoints, with simple controls for rolling back at any point. However, unlike sidecar mode, the ztunnel runs as a DaemonSet — a per-node proxy — meaning that ztunnel upgrades affect, at minimum, an entire node at a time. While this may be acceptable in many cases, applications with long-lived TCP connections may be disrupted.  In such cases, we recommend using node cordoning and draining before upgrading the ztunnel for a given node. For the sake of simplicity, this document will demonstrate in-place upgrades of the ztunnel, which may involve a short downtime.

## Prerequisites

### Organize your tags and revisions

In order to safely upgrade a mesh in ambient mode, your gateways and namespaces should be using the `istio.io/rev` label to specify a revision tag which controls the version of the proxy that is running. We recommend dividing your production cluster into multiple tags to organize your upgrade. All members of a given tag will be upgraded simultaneously, so it is wise to begin your upgrade with your lowest risk applications. We do not recommend referencing revisions directly via labels for upgrades, as this process can easily result in the accidental upgrade of a large number of proxies, and is difficult to segment. To see what tags and revisions you are using in your cluster, see the section on upgrading tags.

### Prepare for the upgrade

Before upgrading Istio, we recommend downloading the new version of istioctl, and running `istioctl x precheck` to make sure the upgrade is compatible with your environment. The output should looks something like this:

{{< text syntax=bash snip_id=istioctl_precheck >}}
$ istioctl x precheck
✔ No issues found when checking the cluster. Istio is safe to install or upgrade!
  To get started, check out <https://istio.io/latest/docs/setup/getting-started/>
{{< /text >}}

Now, update the Helm repository:

{{< text syntax=bash snip_id=update_helm >}}
$ helm repo update istio
{{< /text >}}

### Choose a revision name

Revisions identify unique instances of the Istio control plane, allowing you to run multiple distinct versions of the control plane simultaneously in a single mesh.

It is recommended that revisions stay immutable, that is, once a control plane is installed with a particular revision name, the installation should not be modified, and the revision name should not be reused. Tags, on the other hand, are mutable pointers to revisions. This enables a cluster operator to effect data plane upgrades without the need to adjust any workload labels, simply by moving a tag from one revision to the next. All data planes will connect only to one control plane, specified by the `istio.io/rev` label (pointing to either a revision or tag), or by the default revision if no `istio.io/rev` label is present. Upgrading a data plane consists of simply changing the control plane it is pointed to via modifying labels or editing tags.

Because revisions are intended to be immutable, we recommend choosing a revision name that corresponds with the version of Istio you are installing, such as `1-22-1`. In addition to choosing a new revision name, you should note your current revision name. You can find this by running:

{{< text syntax=bash snip_id=list_revisions >}}
$ kubectl get mutatingwebhookconfigurations -l 'istio.io/rev,!istio.io/tag' -L istio\.io/rev
$ # Store your revision and new revision in variables:
$ export REVISION=istio-1-22-1
$ export OLD_REVISION=istio-1-21-2
{{< /text >}}

## Upgrade the control plane

### Istio CRDs

The cluster-wide Custom Resource Definitions (CRDs) must be upgraded prior to the deployment of a new version of the control plane:

{{< text bash >}}
$ kubectl apply -f manifests/charts/base/crds
{{< /text >}}

### istiod control plane

The [Istiod](/docs/ops/deployment/architecture/#istiod) control plane manages and configures the proxies that route traffic within the mesh. The following command will install a new instance of the control plane alongside the current, but will not introduce any new proxies, or take over control of existing proxies.

If you have customized your istiod installation, you can reuse the `values.yaml` file from previous upgrades or installs to keep your control planes consistent.

{{< text syntax=bash snip_id=upgrade_istiod >}}
$ helm install istiod-"$REVISION" istio/istiod -n istio-system --set revision="$REVISION" --set profile=ambient --wait
{{< /text >}}

### CNI node agent

The Istio CNI agent is responsible for detecting pods added to the ambient mesh, informing ztunnel that proxy ports should be established within added pods, and configuring traffic redirection within the pod network namespace. It is not part of the data plane or control plane.

The CNI at version 1.x is compatible with the control plane at version 1.x+1 and 1.x. This means the control plane must be upgraded before Istio CNI, as long as their version difference is within one minor version.

{{< warning >}}
Upgrading the Istio CNI agent to a compatible version in-place will not disrupt networking for running pods already successfully added to an ambient mesh, but no ambient-captured pods will be successfully scheduled (or rescheduled) on the node until the upgrade is complete and the upgraded Istio CNI agent on the node passes readiness checks. If this is a significant disruption concern, or stricter blast radius controls are desired for CNI upgrades, node taints and/or node cordons are recommended.
{{< /warning >}}

{{< text syntax=bash snip_id=upgrade_cni >}}
$ helm upgrade istio-cni istio/cni -n istio-system
{{< /text >}}

## Upgrade the data plane

### ztunnel DaemonSet

The {{< gloss >}}ztunnel{{< /gloss >}} DaemonSet is the node proxy component. The ztunnel at version 1.x is compatible with the control plane at version 1.x+1 and 1.x. This means the control plane must be upgraded before ztunnel, as long as their version difference is within one minor version. If you have previously customized your ztunnel installation, you can reuse the `values.yaml` file from previous upgrades or installs to keep your {{< gloss >}}data plane{{< /gloss >}} consistent.

{{< warning >}}
Upgrading ztunnel in-place will briefly disrupt all ambient mesh traffic on the node.
Node cordoning and blue/green node pools are recommended to mitigate blast radius risk during production upgrades. See your Kubernetes provider documentation for details.
{{< /warning >}}

{{< text syntax=bash snip_id=upgrade_ztunnel >}}
$ helm upgrade ztunnel istio/ztunnel -n istio-system --set revision="$REVISION" --wait
{{< /text >}}

### Upgrade waypoints and gateways using tags

If you have followed best practices, all of your gateways, workloads, and namespaces use either the default revision (effectively, a tag named `default`), or the `istio.io/rev` label with the value set to a tag name. You can now upgrade all of these to the new version of the Istio data plane by moving their tags to point to the new version, one at a time. To list all tags in your cluster, run:

{{< text syntax=bash snip_id=list_tags >}}
$ kubectl get mutatingwebhookconfigurations -l 'istio.io/tag' -L istio\.io/tag,istio\.io/rev
{{< /text >}}

For each tag, you can upgrade the tag by running the following command, replacing `$MYTAG` with your tag name, and `$REVISION` with your revision name:

{{< text syntax=bash snip_id=upgrade_tag >}}
$ helm template istiod istio/istiod -s templates/revision-tags.yaml --set revisionTags="{$MYTAG}" --set revision="$REVISION" -n istio-system | kubectl apply -f -
{{< /text >}}

This will upgrade all objects referencing that tag, except for those using [manual gateway deployment mode](docs/tasks/traffic-management/ingress/gateway-api/#manual-deployment), which are dealt with below, and sidecars, which are not used in ambient mode.

It is recommended that you closely monitor the health of applications using the upgraded data plane before upgrading the next tag. If you detect a problem, you can rollback a tag, resetting it to point to the name of your old revision:

{{< text syntax=bash snip_id=rollback_tag >}}
$ helm template istiod istio/istiod -s templates/revision-tags.yaml --set revisionTags="{$MYTAG}" --set revision="$OLD_REVISION" -n istio-system | kubectl apply -f -
{{< /text >}}

### Upgrade manually deployed gateways (optional)

`Gateway`s that were [deployed manually](docs/tasks/traffic-management/ingress/gateway-api/#manual-deployment) must be upgraded individually using Helm:

{{< text syntax=bash snip_id=upgrade_gateway >}}
$ helm upgrade istio-ingress istio/gateway -n istio-ingress
{{< /text >}}

## Uninstall the previous control plane

If you have upgraded all data plane components to use the new version of Istio, and are satisfied that you do not need to roll back, you can remove the previous version of the control plane by running:

{{< text syntax=bash snip_id=none >}}
$ helm delete istiod-"$REVISION" -n istio-system
{{< /text >}}
