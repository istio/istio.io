---
title: Анонс Istio 1.26.0
linktitle: 1.26.0
subtitle: Основний випуск
description: Анонс випуску Istio 1.26.
publishdate: 2025-05-08
release: 1.26.0
aliases:
    - /uk/news/announcing-1.26
    - /uk/news/announcing-1.26.0
---

Ми раді повідомити про випуск Istio 1.26. Дякуємо всім нашим учасникам, тестувальникам, користувачам та ентузіастам за допомогу в публікації версії 1.26.0! Ми хотіли б подякувати менеджерам релізу, **Daniel Hawton** з Solo.io, **Faseela K** з Ericsson Software Technology та **Gustavo Meira** з Microsoft.

{{< relnote >}}

{{< tip >}}
Istio 1.26.0 офіційно підтримується на Kubernetes версій від 1.29 до 1.32. Ми очікуємо, що 1.33 також буде працювати, і плануємо додати тестування і підтримку до Istio 1.26.1.
{{< /tip >}}

## Примітка щодо підтримки `EnvoyFilter` в режимі ambient{#a-note-on-envoyfilter-support-in-ambient-mode}

`EnvoyFilter` — це API Istio для розширеної конфігурації проксі-серверів Envoy. Зверніть увагу, що *`EnvoyFilter` наразі не підтримується для жодної існуючої версії Istio з проксі waypoint*. Хоча в обмежених випадках можна використовувати `EnvoyFilter` з waypoint, його використання не підтримується і активно не рекомендується розробниками. Альфа-версія API може перестати працювати в майбутніх версіях у міру її розвитку. Ми очікуємо, що офіційна підтримка буде надана пізніше.

## Що нового? {#whats-new}

### Налаштування ресурсів, що надаються за допомогою API Gateway {#customization-of-resources-provisioned-by-the-gateway-api}

Коли ви створюєте шлюз або waypoint за допомогою API Gateway, автоматично створюються `Service` та `Deployment`. Було поширеним проханням дозволити кастомізацію цих обʼєктів, і тепер це підтримується у Istio 1.26 за допомогою вказівки `ConfigMap` параметрів. Якщо вказано конфігурацію для `HorizontalPodAutoscaler` або `PodDisruptionBudget`, ці ресурси також буде автоматично створено. [Дізнайтеся більше про налаштування згенерованих ресурсів API Gateway.](/docs/tasks/traffic-management/ingress/gateway-api/#automated-deployment)

### Нова підтримка API Gateway {#new-gateway-api-support}

[`TCPRoute`](https://gateway-api.sigs.k8s.io/guides/tcp/) тепер доступний у waypoints, що дозволяє перенаправляти TCP-трафік у режимі ambient.

Ми також додали підтримку експериментальної [`BackendTLSPolicy`](https://gateway-api.sigs.k8s.io/api-types/backendtlspolicy/) і почали реалізацію [`BackendTrafficPolicy`](https://gateway-api.sigs.k8s.io/api-types/backendtrafficpolicy/) у Gateway API 1.3, яка згодом дозволить встановлювати обмеження на повторні спроби.

### Підтримка нового `ClusterTrustBundle` в Kubernetes {#support-for-the-new-kubernetes-clustertrustbundle}

Ми додали експериментальну підтримку [експериментального ресурсу `ClusterTrustBundle` у Kubernetes](https://kubernetes.io/docs/reference/access-authn-authz/certificate-signing-requests/#cluster-trust-bundles), що дозволяє підтримувати новий метод обʼєднання сертифіката і його кореня довіри в один обʼєкт.

### Плюс багато-багато іншого {#plus-much-much-more}

* `istioctl analyze` тепер може виконувати конкретні перевірки!
* Агент вузла CNI більше не запускається стандартно у просторі імен `hostNetwork`, що зменшує ймовірність конфліктів портів з іншими сервісами, запущеними на хості!
* Необхідні ресурси `ResourceQuota` та значення `cniBinDir` встановлюються автоматично під час інсталяції на GKE!
* Фільтр `EnvoyFilter` тепер може співпадати з `VirtualHost` на доменному імені!

Про ці та інші зміни читайте у повному [release notes](change-notes/).

## Наздогнати проєкт Istio {#catch-up-with-the-istio-project}

Якщо ви перевіряєте нас тільки тоді, коли у нас зʼявляється новий реліз, ви могли пропустити, що [ми опублікували аудит безпеки ztunnel](/blog/2025/ztunnel-security-assessment/), [ми порівняли продуктивність пропускної здатності ambient-режиму та роботи в ядрі](/blog/2025/ambient-performance/), або що [у нас була велика презентація на KubeCon EU](/blog/2025/istio-at-kubecon-eu/). Перевірте ці пости!

## Оновлення до 1.26 {#upgrading-to-126}

Ми хотіли б почути від вас відгуки про ваш досвід роботи з Istio 1.26. Ви можете залишити відгук у каналі `#release-1.26` у нашому [Slack](https://slack.istio.io/).

Бажаєте взяти безпосередню участь у розробці Istio? Знайдіть і приєднайтеся до однієї з наших [Робочих груп](https://github.com/istio/community/blob/master/WORKING-GROUPS.md) і допоможіть нам покращити Istio.
