---
title: Google Kubernetes Engine
description: Instructions to setup a Google Kubernetes Engine cluster for Istio.
weight: 9
keywords: [platform-setup,kubernetes,gke,google]
---

To setup the Google Kubernetes Engine cluster for Istio, follow these instructions:

1. Create a new cluster.

    {{< text bash >}}
    $ gcloud container clusters create <cluster-name> \
      --cluster-version=1.10.5-gke.0 \
      --zone <zone> \
      --project <project-id>
    {{< /text >}}

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

