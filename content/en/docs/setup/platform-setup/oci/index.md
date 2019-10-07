---
title: Oracle Cloud Infrastructure
description: Instructions to setup an OKE cluster for Istio.
weight: 27
skip_seealso: true
aliases:
    - /docs/setup/kubernetes/prepare/platform-setup/oci/
    - /docs/setup/kubernetes/platform-setup/oci/
keywords: [platform-setup,kubernetes,oke,oci,oracle]
---

Follow these instructions to prepare an OKE cluster for Istio.

1. Create a new OKE cluster within your OCI tenancy. The simplest way to do this is by using the 'Quick Cluster' option within the [web console](https://docs.cloud.oracle.com/iaas/Content/ContEng/Tasks/contengcreatingclusterusingoke.htm). You may also use the [OCI cli](https://docs.cloud.oracle.com/iaas/Content/API/SDKDocs/cliinstall.htm) as shown below.

    {{< text bash >}}
    $ oci ce cluster create --name oke-cluster1 \
        --kubernetes-version <preferred version> \
        --vcn-id <vcn-ocid> \
        --service-lb-subnet-ids [] \
        ..
    {{< /text >}}

1. Retrieve your credentials for `kubectl` using the OCI cli.

    {{< text bash >}}
    $ oci ce cluster create-kubeconfig \
        --file <path/to/config> \
        --cluster-id <cluster-ocid>
    {{< /text >}}

1. Grant cluster administrator (admin) permissions to the current user. To create the necessary RBAC rules for Istio, the current user requires admin permissions.

    {{< text bash >}}
    $ kubectl create clusterrolebinding cluster-admin-binding \
        --clusterrole=cluster-admin \
        --user=<user_ocid>
    {{< /text >}}

