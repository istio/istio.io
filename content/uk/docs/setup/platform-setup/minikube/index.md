---
title: Minikube
description: Інструкції для налаштування minikube для використання з Istio.
weight: 50
skip_seealso: true
aliases:
    - /uk/docs/setup/kubernetes/prepare/platform-setup/minikube/
    - /uk/docs/setup/kubernetes/platform-setup/minikube/
keywords: [platform-setup,kubernetes,minikube]
owner: istio/wg-environments-maintainers
test: no
---

Виконайте ці інструкції, щоб підготувати minikube для встановлення Istio з достатніми ресурсами для запуску Istio та базових додатків.

## Попередні умови {#prerequisites}

- Для запуску minikube потрібні адміністративні привілеї.

- Щоб увімкнути [Secret Discovery Service](https://www.envoyproxy.io/docs/envoy/latest/configuration/security/secret#sds-configuration) (SDS) для вашої mesh-мережі, потрібно додати [додаткові конфігурації](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/#service-account-token-volume-projection) до вашого розгортання Kubernetes. Дивіться [документацію api-server](https://kubernetes.io/docs/reference/command-line-tools-reference/kube-apiserver/) для актуальних налаштувань.

## Кроки встановлення {#installation-steps}

1. Встановіть останню версію [minikube](https://kubernetes.io/docs/tasks/tools/#minikube) та [драйвера hypervisor для minikube](https://minikube.sigs.k8s.io/docs/start/#install-a-hypervisor).

2. Якщо ви не використовуєте стандартний драйвер, встановіть драйвер hypervisor для minikube.

    Наприклад, якщо ви встановили hypervisor KVM, встановіть `driver` в конфігурації minikube за допомогою наступної команди:

    {{< text bash >}}
    $ minikube config set driver kvm2
    {{< /text >}}

3. Запустіть minikube з 16384 `MB` оперативної памʼяті та 4 `CPU`. У цьому прикладі використовується версія Kubernetes **1.26.1**. Ви можете змінити версію на будь-яку іншу, що підтримується Istio, змінивши значення `--kubernetes-version`:

    {{< text bash >}}
    $ minikube start --memory=16384 --cpus=4 --kubernetes-version=v1.26.1
    {{< /text >}}

    Залежно від hypervisor і платформи, на якій він працює, мінімальні вимоги до памʼяті можуть змінюватися. 16384 `MB` достатньо для запуску Istio і bookinfo.

    {{< tip >}}
    Якщо у вас недостатньо оперативної памʼяті, виділеної для віртуальної машини minikube, можуть виникнути наступні помилки:

    - помилки під час завантаження образів
    - тайм-аут перевірки справності
    - помилки kubectl на хості
    - загальна нестабільність мережі віртуальної машини та хосту
    - повне зависання віртуальної машини
    - перезавантаження хосту через NMI watchdog

    Ефективний спосіб моніторингу використання памʼяті в minikube — `ssh` в віртуальну машину minikube та запуск команди top:

    {{< text bash >}}
    $ minikube ssh
    {{< /text >}}

    {{< text bash >}}
    $ top
    GiB Mem : 12.4/15.7
    {{< /text >}}

    Це показує, що використовується 12.4 GiB з доступних 15.7 GiB RAM у віртуальній машині. Ці дані отримані при використанні hypervisor VMWare Fusion на Macbook Pro 13" з 16 GiB RAM, на якому запущено Istio 1.2 з встановленим bookinfo.
    {{< /tip >}}

4. (Необовʼязково, рекомендується) Якщо ви хочете, щоб minikube надавав балансувальник навантаження для використання з Istio, ви можете використовувати [minikube tunnel](https://minikube.sigs.k8s.io/docs/tasks/loadbalancer/#using-minikube-tunnel). Запустіть цю команду в іншому терміналі, оскільки функція tunnel minikube блокує ваш термінал для виведення діагностичної інформації про мережу:

    {{< text bash >}}
    $ minikube tunnel
    {{< /text >}}

    {{< warning >}}
    Іноді minikube не очищає мережу tunnel належним чином. Щоб примусово виконати правильне очищення:

    {{< text bash >}}
    $ minikube tunnel --cleanup
    {{< /text >}}

    {{< /warning >}}
