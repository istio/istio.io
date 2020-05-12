---
title: Upgrade Notes
description: Important Changes to consider when upgrading to Istio 1.6.
weight: 20
---

This page describes changes you need to be aware of when upgrading from Istio
1.5.x to Istio 1.6.x. Here, we detail cases where we intentionally broke backwards
compatibility. We also mention cases where backwards compatibility was preserved
but new behavior was introduced that would be surprising to someone familiar with
the use and operation of Istio 1.5.

## Removal of legacy Helm charts

In Istio 1.4 we introduced a [new way to install Istio](https://istio.io/blog/2019/introducing-istio-operator/), utilizing the in-cluster Operator or `istioctl install` command. As part of this effort, we deprecated the old Helm charts. Over time, many of the new features added to Istio have been implemented only in these new installation methods. As a result, we have decided to remove the old installation Helm charts in Istio 1.6.

Because there have been a number of changes introduced in Istio 1.5 that were not present in the legacy installation method, such as Istiod and Telemetry V2, we recommend reviewing the [Istio 1.5 Upgrade Notes](https://istio.io/news/releases/1.5.x/announcing-1.5/upgrade-notes/#control-plane-restructuring) before continuing.

Upgrade from the legacy Helm charts can now be safely done using a [Control Plane Revision](https://preliminary.istio.io/blog/2020/multiple-control-planes/). In place upgrade is not supported and may result in downtime, so please follow the [Canary Upgrade](https://preliminary.istio.io/docs/setup/upgrade/#canary-upgrades) steps.

{{< tip >}}
Istio does not currently support skip-level upgrades. If you are still using Istio 1.4, we recommend first upgrading to Istio 1.5. However, if you do choose to upgrade from previous version, you must first disable Galley configuration validation. This can be done by adding `--enable-validation=false` to the Galley deployment and removing the `istio-galley` `ValidatingWebhookConfiguration`
{{< /tip >}}

# TODO: Looking at the 1.5 docs, there were several feature gaps between telemetry v2 and mixer. Do these still exist?
