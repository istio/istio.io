---
title: Azure
description: Instructions to set up an Azure cluster for Istio.
weight: 10
skip_seealso: true
aliases:
  - /docs/setup/kubernetes/prepare/platform-setup/azure/
  - /docs/setup/kubernetes/platform-setup/azure/
keywords: [platform-setup, azure]
owner: istio/wg-environments-maintainers
test: no
---

Follow these instructions to prepare an Azure cluster for Istio.

{{< tip >}}
Azure offers a {{< gloss >}}managed control plane{{< /gloss >}} add-on for the Azure Kubernetes Service (AKS),
which you can use instead of installing Istio manually.
Please refer to [Deploy Istio-based service mesh add-on for Azure Kubernetes Service](https://learn.microsoft.com/azure/aks/istio-deploy-addon)
for details and instructions.
{{< /tip >}}

You can deploy a Kubernetes cluster to Azure via [AKS](https://azure.microsoft.com/en-us/services/kubernetes-service/) or [Cluster API provider for Azure (CAPZ) for self-managed Kubernetes or AKS](https://capz.sigs.k8s.io/) which fully supports Istio.

## AKS

You can create an AKS cluster via numerous means such as [the az cli](https://docs.microsoft.com/en-us/azure/aks/kubernetes-walkthrough), [the Azure portal](https://docs.microsoft.com/en-us/azure/aks/kubernetes-walkthrough-portal), [az cli with Bicep](https://learn.microsoft.com/en-us/azure/aks/learn/quick-kubernetes-deploy-bicep?tabs=azure-cli), or [Terraform](https://learn.microsoft.com/en-us/azure/aks/learn/quick-kubernetes-deploy-terraform?tabs=bash)

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

1. Create the resource group and deploy the AKS cluster

    Replace `myResourceGroup` and `myAKSCluster` with desired names, `my location` using the value from step 1, `1.28.3` if not supported in the region, and then execute:

    {{< text bash >}}
    $ az group create --name myResourceGroup --location "my location"
    $ az aks create --resource-group myResourceGroup --name myAKSCluster --node-count 3 --kubernetes-version 1.28.3 --generate-ssh-keys
    {{< /text >}}

1. Get the AKS `kubeconfig` credentials

   Replace `myResourceGroup` and `myAKSCluster` with the names from the previous step and execute:

    {{< text bash >}}
    $ az aks get-credentials --resource-group myResourceGroup --name myAKSCluster
    {{< /text >}}
