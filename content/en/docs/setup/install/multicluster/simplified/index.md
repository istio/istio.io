---
title: Simplified Multicluster Install [Experimental]
description: Configure an Istio mesh spanning multiple Kubernetes clusters.
weight: 1
keywords: [kubernetes,multicluster]
---

{{< boilerplate experimental-feature-warning >}}

This guide describes how to configure an Istio mesh that includes multiple Kubernetes clusters using a simplified experimental approach.
We hope to continue developing this functionality in coming releases, so we'd love your feedback on the overall flow.

We focus here on the details of getting a multicluster mesh wired up, refer to [multicluster deployment model](/docs/ops/deployment/deployment-models/#multiple-clusters) for
additional background information. We'll show how to connect two clusters that are on the same network together, along
with a third cluster that's on a different network.

Using the approach shown in this guide results in an instance of the Istio control plane being deployed in every cluster
within the mesh. Although this is a common configuration, other more complex topologies are possible, but have to be done
using a more manual process, not described herein.

## Before you begin

The procedures we describe here are primarily intended to be used with relatively pristine clusters,
where Istio hasn't already been deployed. We hope to expand support in the future to existing clusters.

For the sake of explanation, this guide assumes you have created three Kubernetes clusters:

- A cluster named `cluster-east-1` on the network named `network-east`.
- A cluster named `cluster-east-2` on the network named `network-east`.
- A cluster named `cluster-west-1` on the network named `network-west`.

These clusters shouldn't have Istio on them yet. The first two clusters are on the same network and have
direct connectivity, while the third cluster is on a different network.
Take a look at the [platform setup instructions](/docs/setup/platform-setup)
for any special instructions for your particular environment.

## Initial preparations

You need to do a few one-time steps in order to be able to setup a multicluster mesh:

1. Ensure that all of your clusters are included in your [Kubernetes configuration file](https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/#define-clusters-users-and-contexts)
and create contexts for each cluster. Once you're done, your configuration file should include something similar to:

    {{< text syntax="yaml" downloadas="kubeconfig.yaml" >}}
    kind: Config
    apiVersion: v1
    clusters:
    - cluster:
      name: cluster-east-1
    - cluster:
      name: cluster-east-2
    - cluster:
      name: cluster-west-1
    contexts:
    - context:
        cluster: cluster-east-1
      name: context-east-1
    - context:
        cluster: cluster-east-2
      name: context-east-2
    - context:
        cluster: cluster-west-1
      name: context-west-1
    {{< /text >}}

1. Decide on what the name of your multicluster mesh will be. Something short but memorable is your best choice here:

    {{< text bash >}}
    $ export MESH_ID=mymeshname
    {{< /text >}}

1. Decide on the organization name to use in the root and intermediate certificates created to let the clusters communicate with one
another. This should generally be derived from your organization's DNS name:

    {{< text bash >}}
    $ export ORG_NAME=mymeshname.mycompanyname.com
    {{< /text >}}

1. Create a working directory where to store a number of files produced during the cluster
onboarding process:

    {{< text bash >}}
    $ export WORKDIR=mydir
    $ mkdir -p ${WORKDIR}
    $ cd ${WORKDIR}
    {{< /text >}}

1. Download the [setup script]({{< github_file >}}/samples/multicluster/setup-mesh.sh) to your working directory.
This script takes care of creating the requisite
certificates to enable cross-cluster communication, it prepares default configuration files for you,
and will deploy and configure Istio in each cluster.

1. And finally, prepare the mesh by running the download script. This will create a root key and certificate
that will be used to secure communication between the clusters in the mesh, along with a `base.yaml`
file which will be used to control the Istio configuration deployed on all the clusters:

    {{< text bash >}}
    $ ./setup-mesh.sh prep
    {{< /text >}}

    Note that this step doesn't actually do anything to the clusters, it is merely cresting a number of files within your
    working directory.

## Customizing Istio

Preparing the mesh above created a file called `base.yaml` in your working directory. This file defines the
basic [`IstioControlPlane`](/docs/reference/config/istio.operator.v1alpha12.pb/#IstioControlPlane) configuration that will be used when deploying Istio in your clusters (which will happen below). You
can [customize the `base.yaml`](/docs/setup/install/istioctl/#configure-the-feature-or-component-settings) file
to control exactly how Istio will be deployed in all the clusters.

The only values that shouldn't be modified are:

{{< text plain >}}
values.gateway.istio-ingressgateway.env.ISTIO_MESH_NETWORK
values.global.controlPlaneSecurityEnabled
values.global.multiCluster.clusterName
values.global.network
values.global.meshNetworks
values.pilot.meshNetworks=
{{< /text >}}

These values are set automatically by the procedures below, any manual setting will therefore be lost.

## Creating the mesh

You indicate which clusters to include in the mesh by editing the `topology.yaml` file
within your working directory. Add an entry for all three clusters such that the file will
look like:

{{< text yaml >}}
mesh_id: mymeshname
contexts:
  context-east-1:
    network: network-east
  content-east-2:
    network: network-east
  content-west-1:
    network: network-west
{{< /text >}}

The topology file holds the name of the mesh, as well as a mapping of contexts to networks.
Once the file has been saved, you can now create the mesh. This will deploy Istio in every
cluster and configure each instance to be able to securely communicate with one another:

{{< text bash >}}
$ ./setup-mesh apply
{{< /text >}}

To add and remove clusters from the mesh, just update the topology file accordingly and reapply the changes.

{{< warning >}}
Whenever you use `setup-mesh.sh apply` some secret material may be created in your working directory, in particular some private keys associated
with the different certificates. You should store and protect those secrets. The specific files to safeguard are:

{{< text plain >}}
certs/root-key.pem - the root's private key.
certs/intermediate-*/ca-key.pem - intermediates' private keys
{{< /text >}}

{{< /warning >}}

## Clean up

You can remove Istio from all the known clusters with:

{{< text bash >}}
$ ./setup-mesh.sh teardown
{{< /text >}}
