---
title: "Safely Upgrade Istio using a Canary Control Plane Deployment"
subtitle: Simplifying Istio upgrades by offering safe canary deployments of the control plane
description: Simplifying Istio upgrades by offering safe canary deployments of the control plane.
publishdate: 2020-05-19
attribution: "John Howard (Google)"
keywords: [install,upgrade,revision,control plane]
---

Canary deployments are a core feature of Istio. Users rely on Istio's traffic management features to safely control the rollout of new versions of their applications, while making use of Istio's rich telemetry to compare the performance of canaries. However, when it came to upgrading Istio, there was not an easy way to canary the upgrade, and due to the in-place nature of the upgrade, issues or changes found affect the entire mesh at once.

Istio 1.6 will support a new upgrade model to safely canary-deploy new versions of Istio. In this new model, proxies will associate with a specific control plane that they use. This allows a new version to deploy to the cluster with less risk - no proxies connect to the new version until the user explicitly chooses to. This allows gradually migrating workloads to the new control plane, while monitoring changes using Istio telemetry to investigate any issues, just like using `VirtualService` for workloads. Each independent control plane is referred to as a "revision" and has an `istio.io/rev` label.

## Understanding upgrades

Upgrading Istio is a complicated process. During the transition period between two versions, which might take a long time for large clusters, there are version differences between proxies and the control plane. In the old model the old and new control planes use the same Service, traffic is randomly distributed between the two, offering no control to the user. However, in the new model, there is not cross-version communication. Look at how the upgrade changes:

<iframe src="https://docs.google.com/presentation/d/e/2PACX-1vR2R_Nd1XsjriBfwbqmcBc8KtdP4McDqNpp8S5v6woq28FnsW-kATBrKtLEG9k61DuBwTgFKLWyAxuK/embed?start=false&loop=true&delayms=3000" frameborder="0" width="960" height="569" allowfullscreen="true" mozallowfullscreen="true" webkitallowfullscreen="true"></iframe>

## Configuring

Control plane selection is done based on the sidecar injection webhook. Each control plane is configured to select objects with a matching `istio.io/rev` label on the namespace. Then, the upgrade process configures the pods to connect to a control plane specific to that revision. Unlike in the current model, this means that a given proxy connects to the same revision during its lifetime. This avoids subtle issues that might arise when a proxy switches which control plane it is connected to.

The new `istio.io/rev` label will replace the `istio-injection=enabled` label when using revisions. For example, if we had a revision named canary, we would label our namespaces that we want to use this revision with istio.io/rev=canary. See the [upgrade guide](/docs/setup/upgrade) for more information.
