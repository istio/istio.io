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

Follow these instructions to prepare a GKE cluster for Istio.

{{< tip >}}
Google offers a {{< gloss >}}managed control plane{{< /gloss >}} add-on for GKE,
which you can use instead of installing Istio manually.
Refer to [Istio on GKE](https://cloud.google.com/istio/docs/istio-on-gke/overview)
for details and instructions.
{{< /tip >}}

1. Create a new cluster.

    {{< text bash >}}
    $ gcloud container clusters create <cluster-name> \
      --cluster-version latest \
      --num-nodes 4 \
      --zone <zone> \
      --project <project-id>
    {{< /text >}}

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
