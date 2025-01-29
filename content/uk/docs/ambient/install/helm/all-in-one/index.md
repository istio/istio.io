---
title: Встановлення за допомогою Helm (просте)
description: Встановлення Istio з підтримкою ambient mode за допомогою Helm, використовуючи єдиний чарт.
weight: 4
owner: istio/wg-environments-maintainers
test: yes
draft: true
---

{{< tip >}}
Слідуйте цьому керівництву для встановлення та налаштування Istio mesh з підтримкою ambient mode. Якщо ви новачок в Istio і просто хочете спробувати його, дотримуйтесь інструкцій для [швидкого старту](/docs/ambient/getting-started) замість цього.
{{< /tip >}}

Ми рекомендуємо використовувати Helm для встановлення Istio для промислового використання в ambient mode. Для контрольованих оновлень компоненти панелі управління та панелі даних упаковані та встановлюються окремо. (Оскільки панель даних ambient розділена на [два компоненти](/docs/ambient/architecture/data-plane), ztunnel та waypoints, оновлення включають окремі кроки для цих компонентів.)

## Передумови {#prerequisites}

1. Перевірте [Платформо-специфічні передумови](/docs/ambient/install/platform-prerequisites).

1. [Встановіть клієнт Helm](https://helm.sh/docs/intro/install/), версії 3.6 або вище.

1. Налаштуйте репозиторій Helm:

    {{< text syntax=bash snip_id=configure_helm >}}
    $ helm repo add istio https://istio-release.storage.googleapis.com/charts
    $ helm repo update
    {{< /text >}}

<!-- ### Base components -->

<!-- The `base` chart contains the basic CRDs and cluster roles required to set up Istio. -->
<!-- This should be installed prior to any other Istio component. -->

<!-- {{< text syntax=bash snip_id=install_base >}} -->
<!-- $ helm install istio-base istio/base -n istio-system --create-namespace --wait -->
<!-- {{< /text >}} -->

### Install or upgrade the Kubernetes Gateway API CRDs {#install-or-upgrade-the-kubernetes-gateway-api-crds}

{{< boilerplate gateway-api-install-crds >}}

### Встановлення панелі управління та панелі даних для Istio ambient {#install-the-isito-ambient-control-plane-and-data-plane}

Чарт `ambient` встановлює всі компоненти панелі даних та панелі управління Istio, необхідні для ambient, використовуючи Helm wrapper chart, який складається з чартів окремих компонентів.

{{< warning >}}
Зверніть увагу, що якщо ви встановлюєте все як частину цього wrapper chart, ви можете оновлювати або видаляти ambient тільки через цей wrapper chart; ви не можете оновлювати або видаляти компоненти окремо.
{{< /warning >}}

{{< text syntax=bash snip_id=install_ambient_aio >}}
$ helm install istio-ambient istio/ambient --namespace istio-system --create-namespace --wait
{{< /text >}}

### Вхідний шлюз (опціонально) {#ingress-gateway-optional}

{{< tip >}}
{{< boilerplate gateway-api-future >}}
Якщо ви використовуєте Gateway API, вам не потрібно встановлювати та керувати чартом вхідного шлюзу Helm, як описано нижче. Зверніться до [завдання Gateway API](/docs/tasks/traffic-management/ingress/gateway-api/#automated-deployment) за подробицями.
{{< /tip >}}

Щоб встановити вхідний шлюз, виконайте наступну команду:

{{< text syntax=bash snip_id=install_ingress >}}
$ helm install istio-ingress istio/gateway -n istio-ingress --create-namespace --wait
{{< /text >}}

Якщо ваш кластер Kubernetes не підтримує тип сервісу `LoadBalancer` (`type: LoadBalancer`) з належним зовнішнім IP, виконайте команду вище без параметра `--wait`, щоб уникнути нескінченного очікування. Дивіться [Встановлення шлюзів](/docs/setup/additional-setup/gateway/) для детальної документації щодо встановлення шлюзів.

## Налаштування {#configuration}

Wrapper chart ambient складається з наступних чартів Helm компонентів:

- base
- istiod
- istio-cni
- ztunnel

Значення стандартної конфігурації можна змінити, використовуючи один або більше аргументів `--set <parameter>=<value>`. Альтернативно, ви можете вказати кілька параметрів у файлі власних значень, використовуючи аргумент `--values <file>`.

Ви можете перевизначити налаштування на рівні компонентів через wrapper chart так само як і при встановленні компонентів окремо, додаючи префікс до шляху значення з назвою компонента.

Приклад:

{{< text syntax=bash snip_id=none >}}
$ helm install istiod istio/istiod --set hub=gcr.io/istio-testing
{{< /text >}}

Стає:

{{< text syntax=bash snip_id=none >}}
$ helm install istio-ambient istio/ambient --set istiod.hub=gcr.io/istio-testing
{{< /text >}}

при встановленні через wrapper chart.

Щоб переглянути підтримувані параметри конфігурації та документацію для кожного компонента, виконайте:

{{< text syntax=bash >}}
$ helm show values istio/istiod
{{< /text >}}

для кожного компонента, який вас цікавить.

Повні деталі щодо використання та налаштування встановлень Helm доступні в [документації з встановлення sidecar](/docs/setup/install/helm/).

## Перевірка встановлення {#verify-the-installation}

### Перевірка статусу робочого навантаження {#verify-the-workload-status}

Після встановлення всіх компонентів ви можете перевірити статус розгортання Helm за допомогою:

{{< text syntax=bash snip_id=show_components >}}
$ helm ls -n istio-system
NAME            NAMESPACE       REVISION    UPDATED                                 STATUS      CHART           APP VERSION
istio-ambient      istio-system    1           2024-04-17 22:14:45.964722028 +0000 UTC deployed    ambient-{{< istio_full_version >}}     {{< istio_full_version >}}
{{< /text >}}

Ви можете перевірити статус розгорнутих podʼів за допомогою:

{{< text syntax=bash snip_id=check_pods >}}
$ kubectl get pods -n istio-system
NAME                             READY   STATUS    RESTARTS   AGE
istio-cni-node-g97z5             1/1     Running   0          10m
istiod-5f4c75464f-gskxf          1/1     Running   0          10m
ztunnel-c2z4s                    1/1     Running   0          10m
{{< /text >}}

### Перевірка за допомогою демонстраційного застосунку {#verify-with-the-sample-application}

Після встановлення ambient mode за допомогою Helm, ви можете слідувати [керівництву з розгортання демонстраційного застосунку](/docs/ambient/getting-started/deploy-sample-app/), щоб розгорнути демонстраційний застосунок та вхідні шлюзи, а потім ви можете [додати ваш застосунок до ambient mesh](/docs/ambient/getting-started/secure-and-visualize/#add-bookinfo-to-the-mesh).

## Видалення {#uninstall}

Ви можете видалити Istio та його компоненти, видаливши чарт встановлений вище.

1. Видаліть всі компоненти Istio

    {{< text syntax=bash snip_id=delete_ambient_aio >}}
    $ helm delete istio-ambient -n istio-system
    {{< /text >}}

1. (Опціонально) Видаліть будь-які встановлення чарту шлюзу Istio:

    {{< text syntax=bash snip_id=delete_ingress >}}
    $ helm delete istio-ingress -n istio-ingress
    $ kubectl delete namespace istio-ingress
    {{< /text >}}

1. Видаліть CRD, встановлені Istio (опціонально)

    {{< warning >}}
    Це видалить всі створені ресурси Istio.
    {{< /warning >}}

    {{< text syntax=bash snip_id=delete_crds >}}
    $ kubectl get crd -oname | grep --color=never 'istio.io' | xargs kubectl delete
    {{< /text >}}

1. Видаліть простір імен `istio-system`:

    {{< text syntax=bash snip_id=delete_system_namespace >}}
    $ kubectl delete namespace istio-system
    {{< /text >}}
