---
title: Google Kubernetes Engine
description: Instructions to setup a Google Kubernetes Engine cluster for Istio.
weight: 15
skip_seealso: true
aliases:
    - /docs/setup/kubernetes/prepare/platform-setup/gke/
    - /docs/setup/kubernetes/platform-setup/gke/
keywords: [platform-setup,kubernetes,gke,google]
---

{{< tip >}}
To enable SDS in Istio, use Kubernetes 1.13 or above.
{{< /tip >}}

Follow these instructions to prepare an GKE cluster for Istio.

1. Create a new cluster.

    {{< text bash >}}
    $ gcloud container clusters create <cluster-name> \
      --cluster-version latest \
      --machine-type=n1-standard-2 \
      --num-nodes 4 \
      --zone <zone> \
      --project <project-id>
    {{< /text >}}

    {{< tip >}}
    The default installation of Mixer requires nodes with >1 vCPU. If you are
    installing with the
    [demo configuration profile](/docs/setup/additional-setup/config-profiles/),
    you can remove the `--machine-type` argument to use the smaller `n1-standard-1` machine size instead.
    {{< /tip >}}
    
    {{< warning >}}
    To use the Istio CNI feature, the
    [network-policy](https://cloud.google.com/kubernetes-engine/docs/how-to/network-policy)
    GKE feature must be enabled in the cluster.  Use the `--enable-network-policy` flag in
    the `gcloud container clusters create` command.
    {{< /warning >}}

1. Retrieve your credentials for `kubectl`.

    {{< text bash >}}
    $ gcloud container clusters get-credentials <cluster-name> \
        --zone <zone> \
        --project <project-id>
    {{< /text >}}

1. Grant cluster administrator (admin) permissions to the current user. To
   create the necessary RBAC rules for Istio, the current user requires admin
   permissions.

    {{< text bash >}}
    $ kubectl create clusterrolebinding cluster-admin-binding \
        --clusterrole=cluster-admin \
        --user=$(gcloud config get-value core/account)
    {{< /text >}}

