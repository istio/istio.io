---
title: Before you begin
description: Initial steps before installing Istio on multiple clusters.
weight: 1
keywords: [kubernetes,multicluster]
test: n/a
owner: istio/wg-environments-maintainers
---
Before you begin a multicluster installation, review the
[deployment models guide](/docs/ops/deployment/deployment-models)
which describes the foundational concepts used throughout this guide.

In addition, review the requirements and perform the initial steps below.

## Requirements

### Cluster

This guide requires that you have two Kubernetes clusters with any of the
[supported Kubernetes versions:](/docs/releases/supported-releases#support-status-of-istio-releases) {{< supported_kubernetes_versions >}}.

### API Server Access

The API Server in each cluster must be accessible to the other clusters in the
mesh. Many cloud providers make API Servers publicly accessible via network
load balancers (NLB). If the API Server is not directly accessible, you will
have to modify the installation procedure to enable access. For example, the
[east-west](https://en.wikipedia.org/wiki/East-west_traffic) gateway used in
the multi-network and primary-remote configurations could also be used
to enable access to the API Server.

## Environment Variables

This guide will refer to two clusters: `cluster1` and `cluster2`. The following
environment variables will be used throughout to simplify the instructions:

Variable | Description
-------- | -----------
`CTX_CLUSTER1` | The context name in the default [Kubernetes configuration file](https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/) used for accessing the `cluster1` cluster.
`CTX_CLUSTER2` | The context name in the default [Kubernetes configuration file](https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/) used for accessing the `cluster2` cluster.

Set the two variables before proceeding:

{{< text syntax=bash snip_id=none >}}
$ export CTX_CLUSTER1=<your cluster1 context>
$ export CTX_CLUSTER2=<your cluster2 context>
{{< /text >}}

## Configure Trust

A multicluster service mesh deployment requires that you establish trust
between all clusters in the mesh. Depending on the requirements for your
system, there may be multiple options available for establishing trust.
See [certificate management](/docs/tasks/security/cert-management/) for
detailed descriptions and instructions for all available options.
Depending on which option you choose, the installation instructions for
Istio may change slightly.

{{< tip >}}
If you are planning to deploy only one primary cluster (i.e., one of the
Primary-Remote installations, below), you will only have a single CA
(i.e., `istiod` on `cluster1`) issuing certificates for both clusters.
In that case, you can skip the following CA certificate generation step
and simply use the default self-signed CA for the installation.
{{< /tip >}}

This guide will assume that you use a common root to generate intermediate
certificates for each primary cluster.
Follow the [instructions](/docs/tasks/security/cert-management/plugin-ca-cert/)
to generate and push a CA certificate secret to both the `cluster1` and `cluster2`
clusters.

{{< tip >}}
If you currently have a single cluster with a self-signed CA (as described
in [Getting Started](/docs/setup/getting-started/)), you need to
change the CA using one of the methods described in
[certificate management](/docs/tasks/security/cert-management/). Changing the
CA typically requires reinstalling Istio. The installation instructions
below may have to be altered based on your choice of CA.
{{< /tip >}}

## Next steps

You're now ready to install an Istio mesh across multiple clusters. The
particular steps will depend on your requirements for network and
control plane topology.

Choose the installation that best fits your needs:

- [Install Multi-Primary](/docs/setup/install/multicluster/multi-primary)

- [Install Primary-Remote](/docs/setup/install/multicluster/primary-remote)

- [Install Multi-Primary on Different Networks](/docs/setup/install/multicluster/multi-primary_multi-network)

- [Install Primary-Remote on Different Networks](/docs/setup/install/multicluster/primary-remote_multi-network)

{{< tip >}}
For meshes that span more than two clusters, you may need to use more than
one of these options. For example, you may have a primary cluster per region
(i.e. multi-primary) where each zone has a remote cluster that uses the
control plane in the regional primary (i.e. primary-remote).

See [deployment models](/docs/ops/deployment/deployment-models) for more
information.
{{< /tip >}}
