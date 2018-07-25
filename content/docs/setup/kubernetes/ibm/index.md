---
title: Platform setup for IBM Cloud Kubernetes Service
description: Instructions to setup the IBM Cloud Kubernetes Service (IKS) cluster for Istio.
weight: 12
keywords: [ibm,iks]
---

To setup the IBM Cloud Kubernetes Service (IKS) cluster for Istio, follow these instructions:

## IBM Cloud Kubernetes Service (IKS)

1. Create a new lite cluster.

    {{< text bash >}}
    $ bx cs cluster-create --name <cluster-name> --kube-version 1.9.7
    {{< /text >}}

    Alternatively, you can create a new paid cluster:

    {{< text bash >}}
    $ bx cs cluster-create --location location --machine-type u2c.2x4 \
      --name <cluster-name> --kube-version 1.9.7
    {{< /text >}}

1. Retrieve your credentials for `kubectl`. Replace `<cluster-name>` with the
   name of the cluster you want to use:

    {{< text bash >}}
    $(bx cs cluster-config <cluster-name>|grep "export KUBECONFIG")
    {{< /text >}}

## IBM Cloud Private

[Configure the kubectl CLI](https://www.ibm.com/support/knowledgecenter/SSBS6K_2.1.0/manage_cluster/cfc_cli.html)
to access the IBM Cloud Private Cluster.
