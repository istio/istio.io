---
title: IBM Cloud
description: Instructions to setup an IBM Cloud cluster for Istio.
weight: 18
skip_seealso: true
aliases:
    - /docs/setup/kubernetes/prepare/platform-setup/ibm/
keywords: [platform-setup,ibm,iks]
---

Follow these instructions to prepare an IBM Cloud cluster for Istio. You can install Istio in [IBM Cloud Public](#ibm-cloud-public) or [IBM Cloud Private](#ibm-cloud-private).

## IBM Cloud Public

1. [Install the IBM Cloud CLI, the IBM Cloud Kubernetes Service plug-in, and the Kubernetes CLI](https://cloud.ibm.com/docs/containers?topic=containers-cs_cli_install).

1. Create a standard Kubernetes cluster. Replace `<cluster-name>` with the name of the cluster you want to use in the following instructions.

    {{< tip >}}
    To see available zones, run `ibmcloud ks zones`. Zones are isolated from each other, which ensures no shared single point of failure. IBM Cloud Kubernetes Service [Locations](https://cloud.ibm.com/docs/containers?topic=containers-regions-and-zones) describes available zones and how to specify the zone for your new cluster.
    {{< /tip >}}

    {{< tip >}}
    The command below does not contain the `--private-vlan value` and `--public-vlan value` options. To see available VLANs, run `ibmcloud ks vlans --zone <zone-name>`. If you do not have a private and public VLAN yet, they will be automatically created for you. If you already have VLANs, specify them by using the `--private-vlan value` and `--public-vlan value` options.
    {{< /tip >}}

    {{< text bash >}}
    $ ibmcloud ks cluster-create --zone <zone-name> --machine-type b3c.4x16 \
      --workers 3 --name <cluster-name>
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
