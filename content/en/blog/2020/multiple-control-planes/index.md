---
title: "Multiple Control Planes"
subtitle: Simplifying Istio upgrades by offering safe canary deployments of the control plane
description: Simplifying Istio upgrades by offering safe canary deployments of the control plane.
publishdate: 2020-05-19
attribution: "John Howard (Google)"
keywords: [install,upgrade,revision,control plane]
---

Canary deployments have been a core feature of Istio from its beginnings. Users rely on Istio's traffic management features to safely control the rollout of new versions of their applications, while making use of Istio's rich telemetry to compare the performance of canaries. However, when it came to upgrading Istio, there was not an easy way to canary the upgrade, and due to  the in place nature of the upgrade, any issues or changes found will impact the entire mesh at once.

In Istio 1.6, we will support a new upgrade model to safely canary new versions of Istio itself. In this new model, proxies will be tied to a specific control plane that they want to use. This allows a new version to be deployed to the cluster with much lower risk -- no proxies will connect to the new version until the user explicitly chooses to. This allows gradually migrating workloads to the new control plane, while monitoring changes using Istio telemetry to investigate any issues - just like using `VirtualService` for workloads. Each independent control plane is referred to as a "revision" and will be identified by a `istio.io/rev` label.

## Understanding upgrades

Upgrading Istio is a fairly complicated process. During the transition period between two versions, which may be a long time for large clusters, there are version differences between proxies and the control plane. In the old model the old and new control planes use the same Service, traffic will be randomly distributed between the two, offering no control to the user. However, in the new model, there will never be cross-version communication. Take a look at how the upgrade changes:

<iframe src="https://docs.google.com/presentation/d/e/2PACX-1vSbj4B52oEtQ8wGvmaSy29Zao3Q8Ex-w6JaripuJThMTK4F4bxDZkyNUSaexz8Rp8v4QCuDB2dAZkrv/embed?start=false&loop=true&delayms=3000" frameborder="0" width="960" height="569" allowfullscreen="true" mozallowfullscreen="true" webkitallowfullscreen="true"></iframe>

## Configuring

Control plane selection is done based on the sidecar injection webhook. Each control plane is configured to select objects with a matching `istio.io/rev` label on the namespace. These pods will then be configured to connect to a control plane specific to that revision. This means that, unlike in the current model, a given proxy will connect to the same revision throughout its entire lifetime. This avoids subtle issues that may arise when a proxy switches what control plane it is connected to.

The new `istio.io/rev` label will replace the `istio-injection=enabled` label when using revisions. For example, if we had a revision named canary, we would label our namespaces that we want to use this revision with istio.io/rev=canary. See the [upgrade guide](/docs/setup/upgrade) for more information.
