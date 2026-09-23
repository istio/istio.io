---
title: IBM Cloud
description: Інструкції для налаштування кластера IBM Cloud для Istio.
weight: 25
skip_seealso: true
aliases:
    - /uk/docs/setup/kubernetes/prepare/platform-setup/ibm/
    - /uk/docs/setup/kubernetes/platform-setup/ibm/
keywords: [platform-setup,ibm,iks]
owner: istio/wg-environments-maintainers
test: no
---

Дотримуйтесь цих інструкцій, щоб підготувати кластер для Istio за допомогою [IBM Cloud Kubernetes Service](https://cloud.ibm.com/docs/containers?topic=containers-getting-started).

{{< tip >}}
IBM пропонує надбудову {{< gloss "Керована панель управління">}}керованої панелі управління{{< /gloss >}} для IBM Cloud Kubernetes Service, яку ви можете використовувати замість ручної установки Istio. Деталі та інструкції можна знайти в [Istio на IBM Cloud Kubernetes Service](https://cloud.ibm.com/docs/containers?topic=containers-istio).
{{< /tip >}}

Щоб підготувати кластер перед ручною установкою Istio, виконайте наступні кроки:

1. [Встановіть IBM Cloud CLI, втулок IBM Cloud Kubernetes Service та Kubernetes CLI](https://cloud.ibm.com/docs/containers?topic=containers-cs_cli_install).

2. Створіть стандартний кластер Kubernetes за допомогою наступної команди. Замініть `<cluster-name>` на імʼя, яке ви хочете використовувати для вашого кластера, і `<zone-name>` на імʼя доступної зони.

    {{< tip >}}
    Ви можете переглянути доступні зони, виконавши команду `ibmcloud ks zones --provider classic`. Посібник [Locations Reference Guide](https://cloud.ibm.com/docs/containers?topic=containers-regions-and-zones) описує доступні зони та як їх вказати.
    {{< /tip >}}

    {{< text bash >}}
    $ ibmcloud ks cluster create classic --zone <zone-name> --machine-type b3c.4x16 \
      --workers 3 --name <cluster-name>
    {{< /text >}}

    {{< tip >}}
    Якщо у вас вже є приватний або публічний VLAN, ви повинні вказати їх у наведеній вище команді за допомогою опцій `--private-vlan` і `--public-vlan`. Інакше вони будуть автоматично створені для вас. Ви можете переглянути доступні VLAN, виконавши команду `ibmcloud ks vlans --zone <zone-name>`.
    {{< /tip >}}

3. Виконайте наступну команду, щоб завантажити конфігурацію вашого кластера.

    {{< text bash >}}
    $ ibmcloud ks cluster config --cluster <cluster-name>
    {{< /text >}}

    {{< warning >}}
    Переконайтеся, що ви використовуєте версію CLI `kubectl`, яка відповідає версії Kubernetes вашого кластера.
    {{< /warning >}}
