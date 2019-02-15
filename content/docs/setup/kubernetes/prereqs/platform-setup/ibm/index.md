---
title: IBM Cloud
description: Instructions to setup an IBM Cloud cluster for Istio.
weight: 18
skip_seealso: true
keywords: [platform-setup,ibm,iks]
---

Follow these instructions to prepare an IBM Cloud cluster for Istio.

## IBM Cloud Kubernetes Service (IKS)

Replace `<cluster-name>` with the name of the cluster you want to use in the following instructions.

1. Create a new lite or paid Kubernetes cluster.

    Lite cluster:

    {{< text bash >}}
    $ ibmcloud cs cluster-create --name <cluster-name>
    {{< /text >}}

    Paid cluster:

    {{< text bash >}}
    $ ibmcloud cs cluster-create --location <location> --machine-type u2c.2x4 \
      --name <cluster-name>
    {{< /text >}}

1. Retrieve your credentials for `kubectl`.

    {{< text bash >}}
    $(ibmcloud cs cluster-config <cluster-name>|grep "export KUBECONFIG")
    {{< /text >}}

## IBM Cloud Private

[Configure `kubectl`](https://www.ibm.com/support/knowledgecenter/SSBS6K_2.1.0.3/manage_cluster/cfc_cli.html)
to access the IBM Cloud Private Cluster.
