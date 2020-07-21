---
title: Multicluster Installation
description: Configure an Istio mesh spanning multiple clusters.
weight: 30
list_below: true
aliases:
    - /docs/setup/kubernetes/multicluster-install/
    - /docs/setup/kubernetes/multicluster/
    - /docs/setup/kubernetes/install/multicluster/
keywords: [kubernetes,multicluster]
test: n/a
---

This guide shows you how to deploy a multicluster
{{< gloss >}}service mesh{{< /gloss >}}.

Familiarity with [single cluster deployments](/docs/ops/deployment/deployment-models/#single-cluster)
is needed before attempting a {{< gloss >}}multicluster{{< /gloss >}} deployment.

To deploy a service mesh across multiple networks, go to the following legacy guides:

- [Replicated control planes](/docs/setup/install/multicluster/legacy/gateways)
    provides information on connecting clusters through gateways.

- [Shared control planes](/docs/setup/install/multicluster/legacy/shared)
    provides information on adding remote clusters on other networks.

## Before you begin

Choose a [deployment model](/docs/ops/deployment/deployment-models/) that suits
your needs before you build your multicluster deployment. If you already have a
single cluster service mesh, you can
[add clusters that are within the same network to your mesh.](/docs/setup/install/multicluster/single-network/)

### Prerequisites

To successfully deploy a multicluster service mesh, you need to meet the
following prerequisites:

- Your {{< gloss "pod" >}}pods{{< /gloss >}} and
  {{< gloss "workload" >}}workloads{{< /gloss >}} meet [Istio's requirements.](/docs/ops/deployment/requirements/)

- Your {{< gloss "cluster" >}}clusters{{< /gloss >}} are using a [supported platform.](/docs/setup/platform-setup/)

- Individual cluster pod [CIDR](https://en.wikipedia.org/wiki/Classless_Inter-Domain_Routing)
  ranges and service CIDR ranges that are unique across the network without any overlap.

- All pod CIDRs in the same network can route to each other.

### Assumptions

This multicluster deployment guide makes the following assumptions:

- You have a working directory on your system, for example `/sample-mesh`.
  The guides refer to the working directory as `WORK_DIR`, and it provides
  temporary file storage as needed.

- The configuration context for each cluster is in the
  [default Kubernetes configuration file.](https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/)
  That default is either `~/.kube/config` or the value stored in the
  `KUBECONFIG` environment variable. Relying on the default allows us to
  easily switch between clusters.

### Set environment variables {#env-var}

{{< boilerplate mc-env-var >}}

To continue, pick from the following options:
