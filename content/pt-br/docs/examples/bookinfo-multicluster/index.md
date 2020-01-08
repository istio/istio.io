---
title: Bookinfo Application - Multicluster
description: Deploys a sample application across a multicluster mesh.
weight: 11
keywords: [multicluster]
---

{{< boilerplate experimental-feature-warning >}}

This example complements the [simplified multicluster setup procedure](/pt-br/docs/setup/install/multicluster/simplified).
It shows you how to deploy Istio's classic [Bookinfo](/pt-br/docs/examples/bookinfo) sample application across
a multicluster mesh.

## Getting it running

1. Start by following [these instructions](/pt-br/docs/setup/install/multicluster/simplified) which will show you how to
configure a 3 cluster mesh.

1. Download the [`setup-bookinfo.sh` script]({{< github_file >}}/samples/multicluster/setup-bookinfo.sh) and saved it into
the working directory created in the previous step.

1. Run the downloaded script:

    {{< text bash >}}
    $ ./setup-bookinfo.sh install
    {{< /text >}}

    This will deploy Bookinfo on all the clusters in the mesh.

## Showing that its working

Now that Bookinfo has been deployed to all clusters, we can disable some of its service in some of its clusters,
and then see that the overall app continues to be responsive, indicating that traffic transparently flows between
clusters as needed.

Let's disable a few services:

{{< text bash >}}
$ for DEPLOYMENT in details-v1 productpage-v1 reviews-v2 reviews-v3; do
$    kubectl --context=context-east-1 scale deployment ${DEPLOYMENT} --replicas=0
$ done
$ for DEPLOYMENT in details-v1 reviews-v2 reviews-v3 ratings-v1; do
$    kubectl --context=context-east-2 scale deployment ${DEPLOYMENT} --replicas=0
$ done
$ for DEPLOYMENT in productpage-v1 reviews-v2 reviews-v1 ratings-v1; do
$    kubectl --context=context-west-1 scale deployment ${DEPLOYMENT} --replicas=0
$ done
{{< /text >}}

Now use [Bookinfo normally](/pt-br/docs/examples/bookinfo) to demonstrate that the multicluster deployment is working properly.

## Clean up

You can remove Bookinfo from all clusters with:

{{< text bash >}}
$ ./setup-bookinfo.sh uninstall
{{< /text >}}
