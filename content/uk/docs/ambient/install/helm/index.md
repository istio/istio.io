---
title: Встановлення за допомогою Helm
description: Встановіть Istio з підтримкою режиму оточення за допомогою Helm.
weight: 4
aliases:
  - /uk/docs/ops/ambient/install/helm-installation
  - /uk/latest/docs/ops/ambient/install/helm-installation
  - /uk/docs/ambient/install/helm-installation
  - /uk/latest/docs/ambient/install/helm-installation
owner: istio/wg-environments-maintainers
test: yes
---

{{< tip >}}
Керуйтесь цим посібником для встановлення та налаштування Istio mesh з підтримкою ambient режиму. Якщо ви новачок в Istio і просто хочете спробувати його, дотримуйтесь [інструкцій для швидкого старту](/docs/ambient/getting-started) замість цього.
{{< /tip >}}

Ми рекомендуємо використовувати Helm для встановлення Istio для операційного використання в ambient режимі. Щоб дозволити контрольовані оновлення, компоненти панелі управління та панелі даних упаковані та встановлюються окремо. (Оскільки ambient data plane розділений на [два компоненти](/docs/ambient/architecture/data-plane), ztunnel та waypoints, оновлення включають окремі кроки для цих компонентів.)

## Попередні вимоги {#prerequisites}

1. Перевірте [платформо-специфічні вимоги](/docs/ambient/install/platform-prerequisites).

1. [Встановіть клієнт Helm](https://helm.sh/docs/intro/install/), версія 3.6 або вище.

1. Налаштуйте репозиторій Helm:

    {{< text syntax=bash snip_id=configure_helm >}}
    $ helm repo add istio https://istio-release.storage.googleapis.com/charts
    $ helm repo update
    {{< /text >}}

## Встановлення панелі управління {#install-the-control-plane}

Стандартні значення можна змінювати, використовуючи один або кілька параметрів `--set <parameter>=<value>`. Або ви можете вказати кілька параметрів у власному файлі значень, використовуючи аргумент `--values <file>`.

{{< tip >}}
Ви можете показати стандартні значення параметрів конфігурації, використовуючи команду `helm show values <chart>` або звернутися до документації на Artifact Hub для перегляду параметрів конфігурації [base](https://artifacthub.io/packages/helm/istio-official/base?modal=values), [istiod](https://artifacthub.io/packages/helm/istio-official/istiod?modal=values), [CNI](https://artifacthub.io/packages/helm/istio-official/cni?modal=values), [ztunnel](https://artifacthub.io/packages/helm/istio-official/ztunnel?modal=values) та [Gateway](https://artifacthub.io/packages/helm/istio-official/gateway?modal=values).
{{< /tip >}}

Повні відомості про те, як використовувати та налаштовувати установки Helm, доступні в [документації для установки Sidecar](/docs/setup/install/helm/).

На відміну від профілів [istioctl](/docs/ambient/install/istioctl/), які групують компоненти для встановлення або видалення, профілі Helm просто встановлюють групи параметрів конфігурації.

### Базові компоненти {#base-components}

Чарт `base` містить основні CRD та кластерні ролі, необхідні для налаштування Istio. Його слід встановити перед будь-якими іншими компонентами Istio.

{{< text syntax=bash snip_id=install_base >}}
$ helm install istio-base istio/base -n istio-system --create-namespace --wait
{{< /text >}}

### Встановіть або оновіть CRD Kubernetes Gateway API {#install-or-upgrade-the-kubernetes-gateway-api-crds}

{{< boilerplate gateway-api-install-crds >}}

### Панель управління istiod {#istiod-control-plane}

Чарт `istiod` встановлює версію Istiod. Istiod є компонентом панелі правління, який керує та налаштовує проксі для маршрутизації трафіку всередині mesh.

{{< text syntax=bash snip_id=install_istiod >}}
$ helm install istiod istio/istiod --namespace istio-system --set profile=ambient --wait
{{< /text >}}

### CNI агент вузла {#cni-node-agent}

Чарт `cni` встановлює агента вузла Istio CNI. Він відповідає за виявлення podʼів, які належать до ambient mesh, та налаштування перенаправлення трафіку між podʼами та проксі вузла ztunnel (який буде встановлений пізніше).

{{< text syntax=bash snip_id=install_cni >}}
$ helm install istio-cni istio/cni -n istio-system --set profile=ambient --wait
{{< /text >}}

## Встановлення панелі даних {#install-the-data-plane}

### DaemonSet ztunnel {#ztunnel-daemonset}

Чарт `ztunnel` встановлює DaemonSet ztunnel, який є компонентом проксі вузла в ambient режимі Istio.

{{< text syntax=bash snip_id=install_ztunnel >}}
$ helm install ztunnel istio/ztunnel -n istio-system --wait
{{< /text >}}

### Ingress gateway (додатково) {#ingress-gateway-optional}

Щоб встановити ingress gateway, виконайте команду нижче:

{{< text syntax=bash snip_id=install_ingress >}}
$ helm install istio-ingress istio/gateway -n istio-ingress --create-namespace --wait
{{< /text >}}

Якщо ваш кластер Kubernetes не підтримує тип сервісу `LoadBalancer` (`type: LoadBalancer`) з правильною зовнішньою IP-адресою, виконайте вищезазначену команду без параметра `--wait`, щоб уникнути нескінченного очікування. Див. [Встановлення шлюзів](/docs/setup/additional-setup/gateway/) для детальної документації про установку шлюзів.

## Налаштування {#configuration}

Щоб переглянути підтримувані параметри конфігурації та документацію, виконайте:

{{< text syntax=bash >}}
$ helm show values istio/istiod
{{< /text >}}

## Перевірка встановлення {#verify-the-installation}

### Перевірка статусу робочих навантажень {#verify-the-workload-status}

Після встановлення всіх компонентів ви можете перевірити статус установки Helm за допомогою:

{{< text syntax=bash snip_id=show_components >}}
$ helm ls -n istio-system
NAME            NAMESPACE       REVISION    UPDATED                                 STATUS      CHART           APP VERSION
istio-base      istio-system    1           2024-04-17 22:14:45.964722028 +0000 UTC deployed    base-{{< istio_full_version >}}     {{< istio_full_version >}}
istio-cni       istio-system    1           2024-04-17 22:14:45.964722028 +0000 UTC deployed    cni-{{< istio_full_version >}}      {{< istio_full_version >}}
istiod          istio-system    1           2024-04-17 22:14:45.964722028 +0000 UTC deployed    istiod-{{< istio_full_version >}}   {{< istio_full_version >}}
ztunnel         istio-system    1           2024-04-17 22:14:45.964722028 +0000 UTC deployed    ztunnel-{{< istio_full_version >}}  {{< istio_full_version >}}
{{< /text >}}

Ви можете перевірити статус розгорнутих podʼів за допомогою:

{{< text syntax=bash snip_id=check_pods >}}
$ kubectl get pods -n istio-system
NAME                             READY   STATUS    RESTARTS   AGE
istio-cni-node-g97z5             1/1     Running   0          10m
istiod-5f4c75464f-gskxf          1/1     Running   0          10m
ztunnel-c2z4s                    1/1     Running   0          10m
{{< /text >}}

### Перевірка з демонстраційним застосунком {#verify-with-the-sample-application}

Після встановлення ambient режиму за допомогою Helm ви можете слідувати [посібнику з розгортання демонстраційного застосунку](/docs/ambient/getting-started/deploy-sample-app/), щоб розгорнути демонстраційний застосунок і шлюзи ingress, а потім ви можете [додати ваш застосунок до ambient mesh](/docs/ambient/getting-started/secure-and-visualize/#add-bookinfo-to-the-mesh).

## Видалення {#uninstall}

Ви можете видалити Istio та його компоненти, видаливши чарти встановлені вище.

1. Перегляньте всі чарти Istio, встановлені в просторі імен `istio-system`:

    {{< text syntax=bash >}}
    $ helm ls -n istio-system
    NAME            NAMESPACE       REVISION    UPDATED                                 STATUS      CHART           APP VERSION
    istio-base      istio-system    1           2024-04-17 22:14:45.964722028 +0000 UTC deployed    base-{{< istio_full_version >}}     {{< istio_full_version >}}
    istio-cni       istio-system    1           2024-04-17 22:14:45.964722028 +0000 UTC deployed    cni-{{< istio_full_version >}}      {{< istio_full_version >}}
    istiod          istio-system    1           2024-04-17 22:14:45.964722028 +0000 UTC deployed    istiod-{{< istio_full_version >}}   {{< istio_full_version >}}
    ztunnel         istio-system    1           2024-04-17 22:14:45.964722028 +0000 UTC deployed    ztunnel-{{< istio_full_version >}}  {{< istio_full_version >}}
    {{< /text >}}

1. (Опційно) Видаліть будь-які установки чартів шлюзів Istio:

    {{< text syntax=bash snip_id=delete_ingress >}}
    $ helm delete istio-ingress -n istio-ingress
    $ kubectl delete namespace istio-ingress
    {{< /text >}}

1. Видаліть чарт ztunnel:

    {{< text syntax=bash snip_id=delete_ztunnel >}}
    $ helm delete ztunnel -n istio-system
    {{< /text >}}

1. Видаліть чарт Istio CNI:

    {{< text syntax=bash snip_id=delete_cni >}}
    $ helm delete istio-cni -n istio-system
    {{< /text >}}

1. Видаліть чарт панелі управління istiod:

    {{< text syntax=bash snip_id=delete_istiod >}}
    $ helm delete istiod -n istio-system
    {{< /text >}}

1. Видаліть чарт Istio base:

    {{< tip >}}
    Стандартно, видалення чартц через Helm не видаляє встановлені Custom
    Resource Definitions (CRDs), встановлені через чарт.
    {{< /tip >}}

    {{< text syntax=bash snip_id=delete_base >}}
    $ helm delete istio-base -n istio-system
    {{< /text >}}

1. Видаліть CRD, встановлені Istio (опційно)

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
