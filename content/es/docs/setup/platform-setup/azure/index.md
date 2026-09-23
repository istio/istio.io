---
title: Azure
description: Instrucciones para configurar un cluster de Azure para Istio.
weight: 10
skip_seealso: true
aliases:
  - /docs/setup/kubernetes/prepare/platform-setup/azure/
  - /docs/setup/kubernetes/platform-setup/azure/
keywords: [platform-setup, azure]
owner: istio/wg-environments-maintainers
test: no
---

Sigue estas instrucciones para preparar un cluster de Azure para Istio.

{{< tip >}}
Azure ofrece una extensión del {{< gloss >}}control plane gestionado{{< /gloss >}} para Azure Kubernetes Service (AKS),
que puedes usar en lugar de instalar Istio manualmente.
Por favor consulta [Implementar el complemento de mesh de servicios basada en Istio para el servicio de Kubernetes de Azure](https://learn.microsoft.com/azure/aks/istio-deploy-addon)
para detalles e instrucciones.
{{< /tip >}}

Puedes desplegar un cluster de Kubernetes en Azure a través de [AKS](https://azure.microsoft.com/en-us/services/kubernetes-service/) o [Cluster API provider for Azure (CAPZ) para Kubernetes autogestionado o AKS](https://capz.sigs.k8s.io/) que soporta completamente Istio.

## AKS

Puedes crear un cluster AKS a través de numerosos medios como [la CLI az](https://docs.microsoft.com/en-us/azure/aks/kubernetes-walkthrough), [el portal de Azure](https://docs.microsoft.com/en-us/azure/aks/kubernetes-walkthrough-portal), [CLI az con Bicep](https://learn.microsoft.com/en-us/azure/aks/learn/quick-kubernetes-deploy-bicep?tabs=azure-cli), o [Terraform](https://learn.microsoft.com/en-us/azure/aks/learn/quick-kubernetes-deploy-terraform?tabs=bash)

Para la opción de CLI `az`, completa la autenticación `az login` O usa cloud shell, luego ejecuta los siguientes comandos a continuación.

1. Determina el nombre de región deseado que soporta AKS

    {{< text bash >}}
    $ az provider list --query "[?namespace=='Microsoft.ContainerService'].resourceTypes[] | [?resourceType=='managedClusters'].locations[]" -o tsv
    {{< /text >}}

1. Verifica las versiones soportadas de Kubernetes para la región deseada

    Reemplaza `my location` usando el valor de región deseado del paso anterior, y luego ejecuta:

    {{< text bash >}}
    $ az aks get-versions --location "my location" --query "orchestrators[].orchestratorVersion"
    {{< /text >}}

1. Crea el grupo de recursos y despliega el cluster AKS

    Reemplaza `myResourceGroup` y `myAKSCluster` con nombres deseados, `my location` usando el valor del paso 1, `1.28.3` si no está soportado en la región, y luego ejecuta:

    {{< text bash >}}
    $ az group create --name myResourceGroup --location "my location"
    $ az aks create --resource-group myResourceGroup --name myAKSCluster --node-count 3 --kubernetes-version 1.28.3 --generate-ssh-keys
    {{< /text >}}

1. Obtén las credenciales de `kubeconfig` del AKS

   Reemplaza `myResourceGroup` y `myAKSCluster` con los nombres del paso anterior y ejecuta:

    {{< text bash >}}
    $ az aks get-credentials --resource-group myResourceGroup --name myAKSCluster
    {{< /text >}}
