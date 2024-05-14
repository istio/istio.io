---
title: Upgrade with Helm
description: Upgrading an ambient mode installation with Helm.
weight: 5
aliases:
  - /docs/ops/ambient/upgrade/helm-upgrade
  - /latest/docs/ops/ambient/upgrade/helm-upgrade  
owner: istio/wg-environments-maintainers
test: yes
status: Experimental
---

Follow this guide to upgrade and configure an ambient mode installation using
[Helm](https://helm.sh/docs/). This guide assumes you have already performed an [ambient mode installation with Helm](/docs/ambient/install/helm-installation/) with a previous minor or patch version of Istio.

{{< boilerplate ambient-alpha-warning >}}

{{< warning >}}
In contrast to sidecar mode, ambient mode supports moving application pods to an upgraded data plane without a mandatory restart or reschedule of running application pods. However, upgrading the data plane **will** briefly disrupt all workload traffic on the upgraded node, and ambient mode does not currently support canary upgrades of the data plane.

Node cordoning and blue/green node pools are recommended to control blast radius of application pod traffic disruption during production upgrades. See your Kubernetes provider documentation for details.
{{< /warning >}}

## Prerequisites

1. Update the Helm repository:

    {{< text syntax=bash snip_id=update_helm >}}
    $ helm repo update istio
    {{< /text >}}

## In-place upgrade

You can perform an in place upgrade of Istio in your cluster using the Helm
upgrade workflow.

Before upgrading Istio, it is recommended to run the `istioctl x precheck` command to make sure the upgrade is compatible with your environment.

{{< text syntax=bash snip_id=istioctl_precheck >}}
$ istioctl x precheck
✔ No issues found when checking the cluster. Istio is safe to install or upgrade!
  To get started, check out <https://istio.io/latest/docs/setup/getting-started/>
{{< /text >}}

{{< warning >}}
[Helm does not upgrade or delete CRDs](https://helm.sh/docs/chart_best_practices/custom_resource_definitions/#some-caveats-and-explanations) when performing an upgrade. Because of this restriction, an additional step is required when upgrading Istio with Helm.
{{< /warning >}}

### Manually upgrade the CRDs and Istio base chart

1. Upgrade the Kubernetes custom resource definitions ({{< gloss >}}CRDs{{</ gloss >}}):

    {{< text syntax=bash snip_id=manual_crd_upgrade >}}
    $ kubectl apply -f manifests/charts/base/crds
    {{< /text >}}

1. Upgrade the Istio base chart:

    {{< text syntax=bash snip_id=upgrade_base >}}
    $ helm upgrade istio-base manifests/charts/base -n istio-system --skip-crds
    {{< /text >}}

### Upgrade the Istio discovery Component

Istiod is the control plane component that manages and configures the proxies to route traffic within an ambient mesh.

{{< text syntax=bash snip_id=upgrade_istiod >}}
$ helm upgrade istiod istio/istiod -n istio-system
{{< /text >}}

### Upgrade the ztunnel component

The ztunnel DaemonSet is the node proxy component.

{{< warning >}}
As ambient mode is not yet Stable, the following statement is not a compatibility guarantee, and is subject to change, or removal. Prior to reaching Stable status, this component and/or the control plane may receive breaking changes that prevent compatibility between minor versions.
{{< /warning >}}

The ztunnel at version 1.x is generally compatible with the control plane at version 1.x+1 and 1.x. This means the control plane must be upgraded before ztunnel, as long as their version difference is within one minor version.

{{< warning >}}
Upgrading ztunnel in-place will briefly disrupt all ambient mesh traffic on the node.
Node cordoning and blue/green node pools are recommended to mitigate blast radius risk during production upgrades. See your Kubernetes provider documentation for details.
{{< /warning >}}

{{< text syntax=bash snip_id=upgrade_ztunnel >}}
$ helm upgrade ztunnel istio/ztunnel -n istio-system
{{< /text >}}

### Upgrade the CNI component

The Istio CNI agent is responsible for detecting pods added to the ambient mesh, informing ztunnel that proxy ports should be established within added pods, and configuring traffic redirection within the pod network namespace. It is not part of the data plane or control plane.

{{< warning >}}
As ambient mode is not yet Stable, the following statement is not a compatibility guarantee, and is subject to change, or removal. Prior to reaching Stable status, this component and/or the control plane may receive breaking changes that prevent compatibility between minor versions.
{{< /warning >}}

The CNI at version 1.x is generally compatible with the control plane at version 1.x+1 and 1.x. This means the control plane must be upgraded before Istio CNI, as long as their version difference is within one minor version.

{{< warning >}}
Upgrading the Istio CNI agent to a compatible version in-place will not disrupt networking for running pods already successfully added to an ambient mesh, but no ambient-captured pods will be successfully scheduled (or rescheduled) on the node until the upgrade is complete and the upgraded Istio CNI agent on the node passes readiness checks. If this is a significant disruption concern, or stricter blast radius controls are desired for CNI upgrades, node taints and/or node cordons are recommended.
{{< /warning >}}

{{< text syntax=bash snip_id=upgrade_cni >}}
$ helm upgrade istio-cni istio/cni -n istio-system
{{< /text >}}

### Upgrade the Gateway component (optional)

Gateway components manage east-west and north-south dataplane traffic between ambient mesh boundaries, as well as some aspects of the L7 dataplane.

{{< text syntax=bash snip_id=upgrade_gateway >}}
$ helm upgrade istio-ingress istio/gateway -n istio-ingress
{{< /text >}}

## Configuration

To view supported configuration options and documentation, run:

{{< text syntax=bash snip_id=show_istiod_values >}}
$ helm show values istio/istiod
{{< /text >}}

## Verify the installation

### Verify the workload status

After installing all the components, you can check the Helm deployment status with:

{{< text syntax=bash snip_id=show_components >}}
$ helm list -n istio-system
{{< /text >}}

You can check the status of the deployed Istio pods with:

{{< text syntax=bash snip_id=check_pods >}}
$ kubectl get pods -n istio-system
{{< /text >}}

## Uninstall

Please refer to the uninstall section in the [Helm installation guide](/docs/ambient/install/helm-installation/#uninstall).
