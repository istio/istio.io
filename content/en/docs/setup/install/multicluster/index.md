---
title: Install Multicluster
description: Install an Istio mesh across multiple Kubernetes clusters.
weight: 30
icon: setup
aliases:
    - /docs/setup/kubernetes/multicluster-install/
    - /docs/setup/kubernetes/multicluster/
    - /docs/setup/kubernetes/install/multicluster/
keywords: [kubernetes,multicluster]
simple_list: true
content_above: true
test: n/a
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

## Before you begin

Before you begin, review the [deployment models guide](/docs/ops/deployment/deployment-models)
which describes the foundational concepts used throughout this guide.

In addition, review the requirements and perform the initial steps below.

### Requirements

This guide requires that you have two Kubernetes clusters with any of the
[supported Kubernetes versions](/docs/setup/platform-setup).

The API Server in each cluster must be accessible to the other clusters in the
mesh. Many cloud providers make API Servers publicly accessible via network
load balancers (NLB). If the API Server is not directly accessible, you will
have to modify the installation procedure to enable access. For example, the
[east-west](https://en.wikipedia.org/wiki/East-west_traffic) gateway used in
the multi-network and primary-remote configurations below could also be used
to enable access to the API Server.

### Environment Variables

This guide will refer to two clusters named `cluster1` and `cluster2`. The following
environment variables will be used throughout to simplify the instructions:

Variable | Description
-------- | -----------
`CTX_CLUSTER1` | The context name in the default [Kubernetes configuration file](https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/) used for accessing the `cluster1` cluster.
`CTX_CLUSTER2` | The context name in the default [Kubernetes configuration file](https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/) used for accessing the `cluster2` cluster.

For example:

{{< text bash >}}
$ export CTX_CLUSTER1=cluster1
$ export CTX_CLUSTER2=cluster2
{{< /text >}}

### Configure Trust

A multicluster service mesh deployment requires that you establish trust
between all clusters in the mesh. Depending on the requirements for your
system, there may be multiple options available for establishing trust.
See [certificate management](/docs/tasks/security/cert-management/) for
detailed descriptions and instructions for all available options.
Depending on which option you choose, the installation instructions for
Istio may change slightly.

This guide will assume that you use a common root to generate intermediate
certificates for each cluster. Follow the [instructions](/docs/tasks/security/cert-management/plugin-ca-cert/)
to generate and push a ca certificate secrets to both the `cluster1` and `cluster2`
clusters.

{{< tip >}}
If you currently have a single cluster with a self-signed CA (as described
in [Getting Started](/docs/setup/getting-started/)), you need to
change the CA using one of the methods described in
[certificate management](/docs/tasks/security/cert-management/). Changing the
CA typically requires reinstalling Istio. The installation instructions
below may have to be altered based on your choice of CA.
{{< /tip >}}

## Install Istio

The steps for installing Istio on multiple clusters depend on your
requirements for network and control plane topology. Choose the steps
below that best fit your needs.

- [Multi-Primary](/docs/setup/install/multicluster/multi-primary)

- [Multi-Primary on Different Networks](/docs/setup/install/multicluster/multi-primary_multi-network)

- [Primary-Remote](/docs/setup/install/multicluster/primary-remote)

- [Primary-Remote on Different Networks](/docs/setup/install/multicluster/primary-remote_multi-network)

{{< tip >}}
Meshes spanning many clusters may employ more than one of these options.

See [deployment models](/docs/ops/deployment/deployment-models) for more
information.
{{< /tip >}}
