---
title: Oracle Cloud Infrastructure
description: Instructions to prepare a cluster for Istio using Oracle Container Engine for Kubernetes (OKE).
weight: 60
skip_seealso: true
aliases:
    - /docs/setup/kubernetes/prepare/platform-setup/oci/
    - /docs/setup/kubernetes/platform-setup/oci/
keywords: [platform-setup,kubernetes,oke,oci,oracle]
owner: istio/wg-environments-maintainers
test: no
---

This page was last updated September 20, 2021.

{{< boilerplate untested-document >}}

Follow these instructions to prepare an Oracle Container Engine for Kubernetes
(OKE) cluster for Istio.

## Create an OKE cluster

To create an OKE cluster, you must either belong to the tenancy's Administrator's
group or a group to which a policy grants the `CLUSTER_MANAGE` permission.

The simplest way to [create an OKE cluster][CREATE] is to use the
[Quick Create Workflow][QUICK] available in the
[Oracle Cloud Infrastructure (OCI) console][CONSOLE]. Other methods include the
[Custom Create Workflow][CUSTOM] and the [Oracle Cloud Infrastructure (OCI) API][API].

You can also create a cluster using the [OCI CLI][OCICLI] using the
following example:

{{< text bash >}}
$ oci ce cluster create \
      --name <oke-cluster-name> \
      --kubernetes-version <kubernetes-version> \
      --compartment-id <compartment-ocid> \
      --vcn-id <vcn-ocid>
{{< /text >}}

| Parameter             | Expected value                                              |
|-----------------------|------------------------------------------------------------ |
| `oke-cluster-name`    | A name to assign to your new OKE cluster                    |
| `kubernetes-version`  | A [supported version of Kubernetes][K8S] to deploy          |
| `compartment-ocid`    | The [OCID][CONCEPTS] of an existing [compartment][CONCEPTS] |
| `vcn-ocid`            | The [OCID][CONCEPTS] of an existing [virtual cloud network][CONCEPTS] (VCN) |

## Setting up local access to an OKE cluster

[Install `kubectl`][KUBECTL] and the [OCI CLI][OCICLI] (`oci`) to access an OKE
cluster from your local machine.

Use the following OCI CLI command to create or update your `kubeconfig` file to
include an `oci` command that dynamically generates and inserts a short-lived
authentication token which allows `kubectl` to access the cluster:

{{< text bash >}}
$ oci ce cluster create-kubeconfig \
      --cluster-id <cluster-ocid> \
      --file $HOME/.kube/config  \
      --token-version 2.0.0 \
      --kube-endpoint [PRIVATE_ENDPOINT|PUBLIC_ENDPOINT]
{{< /text >}}

{{< tip >}}
While an OKE cluster may have multiple endpoints exposed, only one can be targeted
in the `kubeconfig` file.
{{< /tip >}}

The supported values for `kube-endpoint` are either `PUBLIC_ENDPOINT` or `PRIVATE_ENDPOINT`.
You may also need to configure an SSH tunnel via a [bastion host][BASTION] to
access clusters that only have a private endpoint.

Replace `cluster-ocid` with the [OCID][CONCEPTS] of the target OKE cluster.

## Verify access to the cluster

Use the `kubectl get nodes` command to verify `kubectl` is able to connect to the
cluster:

{{< text bash >}}
$ kubectl get nodes
{{< /text >}}

You can now install Istio using [`istioctl`](../../install/istioctl/),
[Helm](../../install/helm/), or manually.

[CREATE]: https://docs.oracle.com/en-us/iaas/Content/ContEng/Tasks/contengcreatingclusterusingoke.htm
[API]: https://docs.oracle.com/en-us/iaas/Content/ContEng/Tasks/contengcreatingclusterusingoke_topic-Using_the_API.htm
[QUICK]: https://docs.oracle.com/en-us/iaas/Content/ContEng/Tasks/contengcreatingclusterusingoke_topic-Using_the_Console_to_create_a_Quick_Cluster_with_Default_Settings.htm
[CUSTOM]: https://docs.oracle.com/en-us/iaas/Content/ContEng/Tasks/contengcreatingclusterusingoke_topic-Using_the_Console_to_create_a_Custom_Cluster_with_Explicitly_Defined_Settings.htm
[OCICLI]: https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm
[K8S]: https://docs.oracle.com/en-us/iaas/Content/ContEng/Concepts/contengaboutk8sversions.htm
[KUBECTL]: https://kubernetes.io/docs/tasks/tools/
[CONCEPTS]: https://docs.oracle.com/en-us/iaas/Content/GSG/Concepts/concepts.htm
[BASTION]: https://docs.oracle.com/en-us/iaas/Content/ContEng/Tasks/contengdownloadkubeconfigfile.htm#localdownload
[CONSOLE]: https://docs.oracle.com/en-us/iaas/Content/GSG/Concepts/console.htm
