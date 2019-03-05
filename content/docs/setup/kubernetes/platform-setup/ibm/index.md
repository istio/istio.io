---
title: IBM Cloud
description: Instructions to setup an IBM Cloud cluster for Istio.
weight: 18
skip_seealso: true
aliases:
    - /docs/setup/kubernetes/platform-setup/ibm/
keywords: [platform-setup,ibm,iks]
---

Follow these instructions to prepare an IBM Cloud cluster for Istio.

You can use the [Managed Istio add-on for IBM Cloud Kubernetes Service](#managed-istio-add-on) in IBM Cloud Public, use Helm to install Istio in [IBM Cloud Public](#ibm-cloud-public), or install Istio in [IBM-Cloud-Private](#ibm-cloud-private).

## Managed Istio add-on

Istio on IBM Cloud Kubernetes Service provides a seamless installation of Istio, automatic updates and lifecycle management of Istio control plane components, and integration with platform logging and monitoring tools. With one click, you can get all Istio core components, additional tracing, monitoring, and visualization, and the Bookinfo sample app up and running. Istio on IBM Cloud Kubernetes Service is offered as a managed add-on, so IBM Cloud automatically keeps all your Istio components up to date.

To install the managed Istio add-on in IBM Cloud Public, see the [IBM Cloud Kubernetes Service documentation](https://cloud.ibm.com/docs/containers/cs_istio.html).

## IBM Cloud Public

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
    $(ibmcloud cs cluster-config <cluster-name> --export)
    {{< /text >}}

## IBM Cloud Private

[Configure `kubectl`](https://www.ibm.com/support/knowledgecenter/SSBS6K_2.1.0.3/manage_cluster/cfc_cli.html)
to access the IBM Cloud Private Cluster.
