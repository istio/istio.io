---
title: Oracle Cloud Infrastructure
description: Інструкції з підготовки кластера для Istio за допомогою Oracle Container Engine for Kubernetes (OKE).
weight: 60
skip_seealso: true
aliases:
    - /uk/docs/setup/kubernetes/prepare/platform-setup/oci/
    - /uk/docs/setup/kubernetes/platform-setup/oci/
keywords: [platform-setup,kubernetes,oke,oci,oracle]
owner: istio/wg-environments-maintainers
test: no
---

Цю сторінку востаннє оновлено 20 вересня 2021 року.

{{< boilerplate untested-document >}}

Виконайте ці інструкції, щоб підготувати кластер Oracle Container Engine for Kubernetes (OKE) для Istio.

## Створення кластера OKE {#create-an-oke-cluster}

Щоб створити кластер OKE, ви повинні належати до групи адміністраторів або до групи, якій політика надає дозвіл `CLUSTER_MANAGE`.

Найпростіший спосіб [створити кластер OKE][CREATE] — скористатися [Швидким створенням][QUICK], доступним у [консолі Oracle Cloud Infrastructure (OCI)][CONSOLE]. Інші методи включають [Самостійне створення][CUSTOM] та [API Oracle Cloud Infrastructure (OCI)][API].

Ви також можете створити кластер, використовуючи [OCI CLI][OCICLI] за допомогою наступного прикладу:

{{< text bash >}}
$ oci ce cluster create \
      --name <oke-cluster-name> \
      --kubernetes-version <kubernetes-version> \
      --compartment-id <compartment-ocid> \
      --vcn-id <vcn-ocid>
{{< /text >}}

| Параметр             | Очікуване значення                                                 |
|----------------------|------------------------------------------------------------------- |
| `oke-cluster-name`   | Імʼя, яке ви хочете присвоїти новому кластеру OKE                  |
| `kubernetes-version` | [Підтримувана версія Kubernetes][K8S], яку ви хочете встановити    |
| `compartment-ocid`   | [OCID][CONCEPTS] існуючого [відсіку][CONCEPTS]                    |
| `vcn-ocid`           | [OCID][CONCEPTS] існуючої [віртуальної хмарної мережі (VCN)][CONCEPTS] |

## Налаштування локального доступу до кластера OKE {#setting-up-local-access-to-an-oke-cluster}

[Встановіть `kubectl`][KUBECTL] та [OCI CLI][OCICLI] (`oci`) для доступу до кластера OKE з вашої локальної машини.

Використовуйте наступну команду OCI CLI для створення або оновлення вашого файлу `kubeconfig`, щоб включити команду `oci`, яка динамічно створює та вставляє короткостроковий автентифікаційний токен, що дозволяє `kubectl` отримувати доступ до кластера:

{{< text bash >}}
$ oci ce cluster create-kubeconfig \
      --cluster-id <cluster-ocid> \
      --file $HOME/.kube/config  \
      --token-version 2.0.0 \
      --kube-endpoint [PRIVATE_ENDPOINT|PUBLIC_ENDPOINT]
{{< /text >}}

{{< tip >}}
Хоча кластер OKE може мати кілька точок доступу, лише одна може бути вказана у файлі `kubeconfig`.
{{< /tip >}}

Підтримувані значення для `kube-endpoint` — `PUBLIC_ENDPOINT` або `PRIVATE_ENDPOINT`. Можливо, вам також доведеться налаштувати SSH-тунель через [бастіон-хост][BASTION] для доступу до кластерів, які мають лише приватну точку доступу.

Замініть `cluster-ocid` на [OCID][CONCEPTS] цільового кластера OKE.

## Перевірка доступу до кластера {#verifying-access-to-the-cluster}

Використовуйте команду `kubectl get nodes`, щоб перевірити, чи може `kubectl` підʼєднатися до кластера:

{{< text bash >}}
$ kubectl get nodes
{{< /text >}}

Тепер ви можете встановити Istio, використовуючи [`istioctl`](../../install/istioctl/), [Helm](../../install/helm/), або вручну.

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
