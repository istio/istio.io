---
title: Single Network Multicluster Deployments
description: Describes how to deploy a multicluster service mesh on a flat network.
weight: 10
list_below: true
keywords: [multicluster, single-network, primary-cluster, remote-cluster, deployment]
owner: istio/wg-environments-maintainers
test: n/a
---

This guide provides all the information needed to complete a {{< gloss >}}multicluster{{< /gloss >}} deployment on a
[single network.](/docs/ops/deployment/deployment-models/#single-network)
Go to the [multicluster deployment models page](/docs/ops/deployment/deployment-models/#multiple-clusters)
for more information.

To start a multicluster deployment, go to the [initial configuration section.](/docs/setup/install/multicluster/single-network/initial-configuration)

After completing the initial configuration, complete the instructions in the
following sections as many times as needed to add all the
{{< gloss "cluster" >}}clusters{{< /gloss >}} that you need.

- To add a cluster with a {{< gloss >}}control plane{{< /gloss >}} that engages
    in cross-cluster load balancing, go to the [add a primary cluster section.](/docs/setup/install/multicluster/single-network/primary)

- To add a cluster that connects to a control plane outside the cluster, go
    to the [add a remote cluster section.](/docs/setup/install/multicluster/single-network/remote)

After adding a cluster, [verify that your deployment works as intended.](/docs/setup/install/multicluster/single-network/verify)

To continue, pick one of the following options:
