---
title: Як розпочати
description: Початкові кроки перед установкою Istio на кількох кластерах.
weight: 1
keywords: [kubernetes,multicluster,ambient]
test: n/a
owner: istio/wg-environments-maintainers
next: /docs/ambient/install/multicluster/multi-primary_multi-network
prev: /docs/ambient/install/multicluster
---

{{< boilerplate alpha >}}

Перш ніж розпочинати встановлення мультикластеру, ознайомтеся з [посібником з моделей розгортання](/docs/ops/deployment/deployment-models), в якому описано основні поняття, що використовуються в цьому посібнику.

Крім того, перегляньте вимоги та виконайте початкові кроки нижче.

## Вимоги {#requirements}

### Кластер {#cluster}

Цей посібник вимагає наявності двох кластерів Kubernetes з підтримкою LoadBalancer `Services` на будь-якій з [підтримуваних версій Kubernetes:](/docs/releases/supported-releases#support-status-of-istio-releases) {{< supported_kubernetes_versions >}}.

### Доступ до API Server {#api-server-access}

API Server у кожному кластері повинен бути доступний для інших кластерів у мережі. Багато постачальників хмарних послуг роблять API Server загальнодоступними через мережеві балансувальники навантаження (NLB). Шлюз схід-захід ambient не може бути використаний для експонування API Server, оскільки він підтримує лише подвійний HBONE-трафік. Може бути використаний не-ambient шлюз [схід-захід](https://en.wikipedia.org/wiki/East-west_traffic) для надання доступу до API Server.

## Змінні середовища {#environment-variables}

Цей посібник буде посилатися на два кластери: `cluster1` і `cluster2`. Протягом усього посібника будуть використовуватися такі змінні середовища для спрощення інструкцій:

Змінна | Опис
-------- | -----------
`CTX_CLUSTER1` | Імʼя контексту у стандартному [файлі конфігурації Kubernetes](https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/) для доступу до кластера `cluster1`.
`CTX_CLUSTER2` | Імʼя контексту у стандартному [файлі конфігурації Kubernetes](https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/) для доступу до кластера `cluster2`.

Встановіть ці дві змінні перед продовженням:

{{< text syntax=bash snip_id=none >}}
$ export CTX_CLUSTER1=<your cluster1 context>
$ export CTX_CLUSTER2=<your cluster2 context>
{{< /text >}}

## Налаштування довіри {#configure-trust}

Для розгортання мультикластерної сервісної мережі необхідно встановити довіру між усіма кластерами в мережі. Залежно від вимог до вашої системи, для встановлення довіри може бути доступно кілька варіантів. Детальний опис та інструкції щодо всіх доступних варіантів див. у розділі [управління сертифікатами](/docs/tasks/security/cert-management/). Залежно від обраного варіанту, інструкції з встановлення Istio можуть дещо відрізнятися.

У цьому посібнику передбачається, що ви використовуєте загальний корінь для генерації проміжних сертифікатів для кожного основного кластера. Дотримуйтесь [інструкцій](/docs/tasks/security/cert-management/plugin-ca-cert/) для генерації та передачі секрету сертифіката CA до кластерів `cluster1` та `cluster2`.

{{< tip >}}
Якщо ви зараз маєте один кластер із самопідписним CA (як описано в [Початку роботи](/docs/setup/getting-started/)), вам потрібно змінити CA, використовуючи один із методів, описаних в [управління сертифікатами](/docs/tasks/security/cert-management/). Зміна CA зазвичай вимагає перевстановлення Istio. Інструкції з встановлення, наведені нижче, можуть потребувати змін залежно від вашого вибору CA.
{{< /tip >}}

## Наступні кроки {#next-steps}

Тепер ви готові встановити Istio ambient mesh на кількох кластерах.

- [Встановлення Multi-Primary на різних мережах](/docs/ambient/install/multicluster/multi-primary_multi-network)

{{< tip >}}
Якщо ви плануєте встановити Istio мультикластер за допомогою Helm, спочатку дотримуйтесь [попередніх вимог Helm](/docs/setup/install/helm/#prerequisites) у посібнику з встановлення Helm.
{{< /tip >}}
