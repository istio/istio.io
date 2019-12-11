---
title: Multicluster Installation
description: Configure an Istio mesh spanning multiple Kubernetes clusters.
weight: 30
aliases:
    - /docs/setup/kubernetes/multicluster-install/
    - /docs/setup/kubernetes/multicluster/
    - /docs/setup/kubernetes/install/multicluster/
keywords: [kubernetes,multicluster]
---

{{< tip >}}
Note that these instructions are not mutually exclusive.
In a large multicluster deployment, composed from more than two clusters,
a combination of the approaches can be used. For example,
two clusters might share a control plane while a third has its own.
{{< /tip >}}

Refer to the [multicluster deployment model](/docs/ops/deployment/deployment-models/#multiple-clusters)
concept documentation for more information.
