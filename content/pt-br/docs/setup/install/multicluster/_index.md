---
title: Install Multicluster
description: Install an Istio mesh across multiple Kubernetes clusters.
weight: 40
aliases:
    - /docs/setup/kubernetes/multicluster-install/
    - /docs/setup/kubernetes/multicluster/
    - /docs/setup/kubernetes/install/multicluster/
    - /docs/setup/install/multicluster/gateways/
    - /docs/setup/install/multicluster/shared/
keywords: [kubernetes,multicluster]
simple_list: true
content_above: true
test: table-of-contents
owner: istio/wg-environments-maintainers
---
Follow this guide to install an Istio {{< gloss >}}service mesh{{< /gloss >}}
that spans multiple {{< gloss "cluster" >}}clusters{{< /gloss >}}.

This guide covers some of the most common concerns when creating a
{{< gloss >}}multicluster{{< /gloss >}} mesh:

- [Network topologies](/docs/ops/deployment/deployment-models#network-models):
  one or two networks

- [Control plane topologies](/docs/ops/deployment/deployment-models#control-plane-models):
  multiple {{< gloss "primary cluster" >}}primary clusters{{< /gloss >}},
  a primary and {{< gloss >}}remote cluster{{< /gloss >}}

{{< tip >}}
For meshes that span more than two clusters, you can extend the steps in this
guide to configure more complex topologies.

See [deployment models](/docs/ops/deployment/deployment-models) for more
information.
{{< /tip >}}
