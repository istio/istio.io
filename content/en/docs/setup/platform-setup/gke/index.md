---
title: Google Kubernetes Engine
description: Instructions to set up a Google Kubernetes Engine cluster for Istio.
weight: 20
skip_seealso: true
aliases:
    - /docs/setup/kubernetes/prepare/platform-setup/gke/
    - /docs/setup/kubernetes/platform-setup/gke/
keywords: [platform-setup,kubernetes,gke,google]
owner: istio/wg-environments-maintainers
test: no
---

Follow these instructions to prepare a GKE cluster for Istio.

1. Create a new cluster.

    {{< text bash >}}
    $ export PROJECT_ID=`gcloud config get-value project` && \
      export M_TYPE=n1-standard-2 && \
      export ZONE=us-west2-a && \
      export CLUSTER_NAME=${PROJECT_ID}-${RANDOM} && \
      gcloud services enable container.googleapis.com && \
      gcloud container clusters create $CLUSTER_NAME \
      --cluster-version latest \
      --machine-type=$M_TYPE \
      --num-nodes 4 \
      --zone $ZONE \
      --project $PROJECT_ID
    {{< /text >}}

    {{< tip >}}
    The default installation of Istio requires nodes with >1 vCPU. If you are
    installing with the
    [demo configuration profile](/docs/setup/additional-setup/config-profiles/),
    you can remove the `--machine-type` argument to use the smaller `n1-standard-1` machine size instead.
    {{< /tip >}}

    {{< warning >}}
    To use the Istio CNI feature on GKE, please check the [CNI installation guide](/docs/setup/additional-setup/cni/#prerequisites)
    for prerequisite cluster configuration steps.
    {{< /warning >}}

    {{< warning >}}
    **For private GKE clusters**

    An automatically created firewall rule does not open port 15017. This is needed by the Pilot discovery validation webhook.

    To review this firewall rule for master access:

    {{< text bash >}}
    $ gcloud compute firewall-rules list --filter="name~gke-${CLUSTER_NAME}-[0-9a-z]*-master"
    {{< /text >}}

    To replace the existing rule and allow master access:

    {{< text bash >}}
    $ gcloud compute firewall-rules update <firewall-rule-name> --allow tcp:10250,tcp:443,tcp:15017
    {{< /text >}}

    {{< /warning >}}

1. Retrieve your credentials for `kubectl`.

    {{< text bash >}}
    $ gcloud container clusters get-credentials $CLUSTER_NAME \
        --zone $ZONE \
        --project $PROJECT_ID
    {{< /text >}}

1. Grant cluster administrator (admin) permissions to the current user. To
   create the necessary RBAC rules for Istio, the current user requires admin
   permissions.

    {{< text bash >}}
    $ kubectl create clusterrolebinding cluster-admin-binding \
        --clusterrole=cluster-admin \
        --user=$(gcloud config get-value core/account)
    {{< /text >}}

## Multi-cluster communication

In some cases, a firewall rule must be explicitly created to allow cross-cluster traffic.

{{< warning >}}
The following instructions will allow communication between *all* clusters in your project. Adjust the commands as needed.
{{< /warning >}}

1. Gather information about your clusters' network.

    {{< text bash >}}
    $ function join_by { local IFS="$1"; shift; echo "$*"; }
    $ ALL_CLUSTER_CIDRS=$(gcloud --project $PROJECT_ID container clusters list --format='value(clusterIpv4Cidr)' | sort | uniq)
    $ ALL_CLUSTER_CIDRS=$(join_by , $(echo "${ALL_CLUSTER_CIDRS}"))
    $ ALL_CLUSTER_NETTAGS=$(gcloud --project $PROJECT_ID compute instances list --format='value(tags.items.[0])' | sort | uniq)
    $ ALL_CLUSTER_NETTAGS=$(join_by , $(echo "${ALL_CLUSTER_NETTAGS}"))
    {{< /text >}}

1. Create the firewall rule.

    {{< text bash >}}
    $ gcloud compute firewall-rules create istio-multicluster-pods \
        --allow=tcp,udp,icmp,esp,ah,sctp \
        --direction=INGRESS \
        --priority=900 \
        --source-ranges="${ALL_CLUSTER_CIDRS}" \
        --target-tags="${ALL_CLUSTER_NETTAGS}" --quiet
    {{< /text >}}
