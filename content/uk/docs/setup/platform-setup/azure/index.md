---
title: Azure
description: Інструкція зі створення кластера Azure для Istio.
weight: 10
skip_seealso: true
aliases:
  - /uk/docs/setup/kubernetes/prepare/platform-setup/azure/
  - /uk/docs/setup/kubernetes/platform-setup/azure/
keywords: [platform-setup, azure]
owner: istio/wg-environments-maintainers
test: no
---

Слідуйте цим інструкціям для підготовки Azure кластера для Istio.

{{< tip >}}
Azure пропонує надбудову {{< gloss "Керована панель управління" >}}панелі управління{{< /gloss >}} для Azure Kubernetes Service (AKS), яку можна використовувати замість ручної установки Istio. Ознайомтеся з [Deploy Istio-based service mesh add-on for Azure Kubernetes Service](https://learn.microsoft.com/azure/aks/istio-deploy-addon) для отримання деталей та інструкцій.
{{< /tip >}}

Ви можете розгорнути Kubernetes кластер на Azure через [AKS](https://azure.microsoft.com/en-us/services/kubernetes-service/) або [Cluster API provider for Azure (CAPZ) для самостійно керованого Kubernetes або AKS](https://capz.sigs.k8s.io/), який повністю підтримує Istio.

## AKS

Ви можете створити кластер AKS через численні засоби, такі як [az cli](https://docs.microsoft.com/en-us/azure/aks/kubernetes-walkthrough), [портал Azure](https://docs.microsoft.com/en-us/azure/aks/kubernetes-walkthrough-portal), [az cli з Bicep](https://learn.microsoft.com/en-us/azure/aks/learn/quick-kubernetes-deploy-bicep?tabs=azure-cli) або [Terraform](https://learn.microsoft.com/en-us/azure/aks/learn/quick-kubernetes-deploy-terraform?tabs=bash).

Для варіанту з `az` cli виконайте автентифікацію через `az login` АБО використовуйте Cloud Shell, а потім виконайте наступні команди.

1. Визначте бажане імʼя регіону, який підтримує AKS

    {{< text bash >}}
    $ az provider list --query "[?namespace=='Microsoft.ContainerService'].resourceTypes[] | [?resourceType=='managedClusters'].locations[]" -o tsv
    {{< /text >}}

1. Перевірте підтримувані версії Kubernetes для вибраного регіону

    Замініть `my location` на значення регіону з попереднього кроку та виконайте:

    {{< text bash >}}
    $ az aks get-versions --location "my location" --query "orchestrators[].orchestratorVersion"
    {{< /text >}}

1. Створіть групу ресурсів і розгорніть кластер AKS

    Замініть `myResourceGroup` та `myAKSCluster` на бажані імена, `my location` на значення з кроку 1, `1.28.3` на підтримувану версію в регіоні та виконайте:

    {{< text bash >}}
    $ az group create --name myResourceGroup --location "my location"
    $ az aks create --resource-group myResourceGroup --name myAKSCluster --node-count 3 --kubernetes-version 1.28.3 --generate-ssh-keys
    {{< /text >}}

1. Отримайте облікові дані `kubeconfig` для AKS

   Замініть `myResourceGroup` та `myAKSCluster` на імена з попереднього кроку та виконайте:

    {{< text bash >}}
    $ az aks get-credentials --resource-group myResourceGroup --name myAKSCluster
    {{< /text >}}