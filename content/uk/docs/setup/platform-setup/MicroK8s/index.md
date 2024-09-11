---
title: MicroK8s
description: Інструкції для налаштування MicroK8s для використання з Istio.
weight: 45
skip_seealso: true
aliases:
    - /uk/docs/setup/kubernetes/prepare/platform-setup/MicroK8s/
    - /uk/docs/setup/kubernetes/platform-setup/MicroK8s/
keywords: [platform-setup,kubernetes,MicroK8s]
owner: istio/wg-environments-maintainers
test: no
---

Ця сторінка була останній раз оновлена 28 серпня 2019 року.

{{< boilerplate untested-document >}}

Виконайте ці інструкції, щоб підготувати MicroK8s для використання з Istio.

{{< warning >}}
Для запуску MicroK8s потрібні адміністративні привілеї.
{{< /warning >}}

1. Встановіть останню версію [MicroK8s](https://microk8s.io) за допомогою команди:

    {{< text bash >}}
    $ sudo snap install microk8s --classic
    {{< /text >}}

1. Увімкніть Istio за допомогою наступної команди:

    {{< text bash >}}
    $ microk8s.enable istio
    {{< /text >}}

1. Коли буде запропоновано, виберіть, чи потрібно застосовувати взаємну TLS автентифікацію між sidecars. Якщо у вас змішане розгортання з не-Istio та Istio сервісами або ви не впевнені, виберіть "Ні".

Запустіть наступну команду, щоб перевірити прогрес розгортання:

    {{< text bash >}}
    $ watch microk8s.kubectl get all --all-namespaces
    {{< /text >}}
