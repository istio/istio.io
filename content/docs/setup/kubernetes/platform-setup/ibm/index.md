---
title: IBM Cloud
description: Instructions to setup an IBM Cloud cluster for Istio.
weight: 18
skip_seealso: true
aliases:
    - /docs/setup/kubernetes/prepare/platform-setup/ibm/
keywords: [platform-setup,ibm,iks]
---

Follow these instructions to prepare an IBM Cloud cluster for Istio.

You can use the [Managed Istio add-on for IBM Cloud Kubernetes Service](#managed-istio-add-on) in IBM Cloud Public, use Helm to install Istio in [IBM Cloud Public](#ibm-cloud-public), or install Istio in [IBM Cloud Private](#ibm-cloud-private).

## Managed Istio add-on

Istio on IBM Cloud Kubernetes Service provides a seamless installation of Istio, automatic updates and lifecycle management of Istio control plane components, and integration with platform logging and monitoring tools. With one click, you can get all Istio core components, additional tracing, monitoring, and visualization, and the Bookinfo sample app up and running. Istio on IBM Cloud Kubernetes Service is offered as a managed add-on, so IBM Cloud automatically keeps all your Istio components up to date.

To install the managed Istio add-on in IBM Cloud Public, see the [IBM Cloud Kubernetes Service documentation](https://cloud.ibm.com/docs/containers/cs_istio.html).

## IBM Cloud Public

1. [Install the IBM Cloud CLI, the IBM Cloud Kubernetes Service plug-in, and the Kubernetes CLI](https://cloud.ibm.com/docs/containers?topic=containers-cs_cli_install).

1. Create a standard Kubernetes cluster. Replace `<cluster-name>` with the name of the cluster you want to use in the following instructions.

    {{< tip >}}
    To see available zones, run `ibmcloud ks zones`. Zones are isolated from each other, which ensures no shared single point of failure. IBM Cloud Kubernetes Service [Regions and zones](https://cloud.ibm.com/docs/containers?topic=containers-regions-and-zones) describes regions, zones, and how to specify the region and zone for your new cluster.
    {{< /tip >}}

    {{< tip >}}
    The command below does not contain the `--private-vlan value` and `--public-vlan value` options. To see available VLANs, run `ibmcloud ks vlan-ls --zone <zone-name>`. If you do not have a private and public VLAN yet, they will be automatically created for you. If you already have VLANs, they need to be specified using the `--private-vlan value` and `--public-vlan value` options.
    {{< /tip >}}

    {{< text bash >}}
    $ ibmcloud ks cluster-create --zone <zone-name> --machine-type b2c.4x16 \
      --name <cluster-name>
    {{< /text >}}

1. Retrieve your credentials for `kubectl`.

    {{< text bash >}}
    $(ibmcloud ks cluster-config <cluster-name> --export)
    {{< /text >}}

{{< warning >}}
Make sure to use the `kubectl` CLI version that matches the Kubernetes version of your cluster.
{{< /warning >}}

## IBM Cloud Private

[Configure `kubectl`](https://www.ibm.com/support/knowledgecenter/SSBS6K_3.2.0/manage_cluster/install_kubectl.html)
to access the IBM Cloud Private Cluster.
