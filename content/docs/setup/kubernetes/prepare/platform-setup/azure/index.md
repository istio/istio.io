---
title: Azure
description: Instructions to setup an Azure cluster for Istio.
weight: 9
skip_seealso: true
aliases:
    - /docs/setup/kubernetes/platform-setup/azure
keywords: [platform-setup,azure]
---

Follow these instructions to prepare an Azure cluster for Istio.

You can deploy a Kubernetes cluster to Azure via [AKS](https://azure.microsoft.com/en-us/services/kubernetes-service/) or [ACS-Engine](https://github.com/azure/acs-engine) which fully supports Istio.

## AKS

You can create an AKS cluster via [the az cli](https://docs.microsoft.com/en-us/azure/aks/kubernetes-walkthrough) or [the Azure portal](https://docs.microsoft.com/en-us/azure/aks/kubernetes-walkthrough-portal).

For the `az` cli option, complete `az login` authentication OR use cloud shell, then run the following commands below.

1. Determine the desired region name which supports AKS

    {{< text bash >}}
    $ az provider list --query "[?namespace=='Microsoft.ContainerService'].resourceTypes[] | [?resourceType=='managedClusters'].locations[]" -o tsv
    {{< /text >}}

1. Verify the supported Kubernetes versions for the desired region

    Replace `my location` using the desired region value from the above step, and then execute:

    {{< text bash >}}
    $ az aks get-versions --location "my location" --query "orchestrators[].orchestratorVersion"
    {{< /text >}}

    Ensure a minimum of `1.10.5` is listed.

1. Create the resource group and deploy the AKS cluster

    Replace `myResourceGroup` and `myAKSCluster` with desired names, `my location` using the value from step 1, `1.10.5` if not supported in the region, and then execute:

    {{< text bash >}}
    $ az group create --name myResourceGroup --location "my location"
    $ az aks create --resource-group myResourceGroup --name myAKSCluster --node-count 3 --kubernetes-version 1.10.5 --generate-ssh-keys
    {{< /text >}}

1. Get the AKS `kubeconfig` credentials

    Replace `myResourceGroup` and `myAKSCluster` with the names from the previous step and execute:

    {{< text bash >}}
    $ az aks get-credentials --resource-group myResourceGroup --name myAKSCluster
    {{< /text >}}

## ACS-Engine

1. [Follow the instructions](https://github.com/Azure/acs-engine/blob/master/docs/acsengine.md#install) to get and install the `acs-engine` binary.

1. Download the `acs-engine` API model definition that supports deploying Istio:

    {{< text bash >}}
    $ wget https://raw.githubusercontent.com/Azure/acs-engine/master/examples/service-mesh/istio.json
    {{< /text >}}

    Note: It is possible to use other api model definitions which will work with Istio.  The MutatingAdmissionWebhook and ValidatingAdmissionWebhook admission control flags and RBAC are enabled by default. See [acs-engine api model default values](https://github.com/Azure/acs-engine/blob/master/docs/clusterdefinition.md) for further information.

1. Deploy your cluster using the `istio.json` template. You can find references
   to the parameters in the
   [official docs](https://github.com/Azure/acs-engine/blob/master/docs/kubernetes/deploy.md#step-3-edit-your-cluster-definition).

    | Parameter                             | Expected value             |
    |---------------------------------------|----------------------------|
    | `subscription_id`                     | Azure Subscription Id      |
    | `dns_prefix`                          | Cluster DNS Prefix         |
    | `location`                            | Cluster Location           |

    {{< text bash >}}
    $ acs-engine deploy --subscription-id <subscription_id> \
      --dns-prefix <dns_prefix> --location <location> --auto-suffix \
      --api-model istio.json
    {{< /text >}}

    {{< tip >}}
    After a few minutes, you can find your cluster on your Azure subscription
    in a resource group called `<dns_prefix>-<id>`. Assuming `dns_prefix` has
    the value `myclustername`, a valid resource group with a unique cluster
    ID is `mycluster-5adfba82`. The `acs-engine` generates your `kubeconfig`
    file in the `_output` folder.
    {{< /tip >}}

1. Use the `<dns_prefix>-<id>` cluster ID, to copy your `kubeconfig` to your
   machine from the `_output` folder:

    {{< text bash >}}
    $ cp _output/<dns_prefix>-<id>/kubeconfig/kubeconfig.<location>.json \
        ~/.kube/config
    {{< /text >}}

    For example:

    {{< text bash >}}
    $ cp _output/mycluster-5adfba82/kubeconfig/kubeconfig.westus2.json \
      ~/.kube/config
    {{< /text >}}
