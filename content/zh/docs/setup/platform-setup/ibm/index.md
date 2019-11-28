---
title: IBM Cloud
description: Instructions to setup an IBM Cloud cluster for Istio.
weight: 18
skip_seealso: true
aliases:
    - /docs/setup/kubernetes/prepare/platform-setup/ibm/
    - /docs/setup/kubernetes/platform-setup/ibm/
keywords: [platform-setup,ibm,iks]
---

Follow these instructions to prepare a cluster for Istio using the
[IBM Cloud Kubernetes Service](https://cloud.ibm.com/docs/containers?topic=containers-getting-started).
To install Istio on IBM Cloud Private, refer to
[Istio on IBM Cloud Private](https://www.ibm.com/support/knowledgecenter/en/SSBS6K_3.2.1/manage_cluster/istio.html)
instead.

{{< tip >}}
IBM offers a {{< gloss >}}managed control plane{{< /gloss >}} add-on for the IBM Cloud Kubernetes Service,
which you can use instead of installing Istio manually.
Refer to [Istio on IBM Cloud Kubernetes Service](https://cloud.ibm.com/docs/containers?topic=containers-istio)
for details and instructions.
{{< /tip >}}

To prepare a cluster before manually installing Istio, proceed as follows:

1.  [Install the IBM Cloud CLI, the IBM Cloud Kubernetes Service plug-in, and the Kubernetes CLI](https://cloud.ibm.com/docs/containers?topic=containers-cs_cli_install).

1.  Create a standard Kubernetes cluster using the following command.
    Replace `<cluster-name>` with the name you want to use for your cluster and `<zone-name>` with the name of an
    available zone.

    {{< tip >}}
    You can display your available zones by running `ibmcloud ks zones`.
    The IBM Cloud Kubernetes Service [Locations Reference Guide](https://cloud.ibm.com/docs/containers?topic=containers-regions-and-zones)
    describes the available zones and how to specify them.
    {{< /tip >}}

    {{< text bash >}}
    $ ibmcloud ks cluster-create --zone <zone-name> --machine-type b3c.4x16 \
      --workers 3 --name <cluster-name>
    {{< /text >}}

    {{< tip >}}
    If you already have a private and a public VLAN, you can specify them in the above command
    using the `--private-vlan` and `--public-vlan` options. Otherwise, they will be automatically created for you.
    You can view your available VLANs by running `ibmcloud ks vlans --zone <zone-name>`.
    {{< /tip >}}

1.  Run the following command to download your cluster configuration for `kubectl` and then
    set the `KUBECONFIG` environment variable as specified in the command output.

    {{< text bash >}}
    $ ibmcloud ks cluster-config <cluster-name>
    {{< /text >}}

    {{< warning >}}
    Make sure to use the `kubectl` CLI version that matches the Kubernetes version of your cluster.
    {{< /warning >}}
