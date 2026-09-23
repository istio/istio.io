---
title: Анонс Istio 1.28.1
linktitle: 1.28.1
subtitle: Патч-реліз
description: Патч-реліз Istio 1.28.1.
publishdate: 2025-12-03
release: 1.28.1
aliases:
    - /news/announcing-1.28.1
---

Цей реліз містить виправлення помилок для покращення надійності. Ця примітка до релізу описує, що змінилося між Istio 1.28.0 та 1.28.1.

{{< relnote >}}

## Зміни {#changes}

- **Виправлено** підтримку кількох `targetPorts` у `InferencePool`. Можливість мати >1 `targetPort` була додана як частина GIE v1.1.0.
  ([Тікет #57638](https://github.com/istio/istio/issues/57638))

- **Виправлено** конфлікти статусу на Route ресурсах, коли встановлені кілька ревізій Istio.
  ([Тікет #57734](https://github.com/istio/istio/issues/57734))

- **Виправлено** `ServiceEntry` ресурси з перекриваючими hostname в одному namespace, що призводить до непередбачуваної поведінки у режимі ambient.
  ([Тікет #57291](https://github.com/istio/istio/issues/57291))

- **Виправлено** збій у роботі `istio-init` під час використання вбудованих nftables у режимі TPROXY, коли анотація `traffic.sidecar.istio.io/includeInboundPorts` була порожньою.
  ([Тікет #58135](https://github.com/istio/istio/issues/58135))

- **Виправлено** проблему, через яку код генерації EDS не враховував область дії сервісу, внаслідок чого в конфігурацію waypoint потрапляли віддалені точки доступу кластера, доступ до яких не мав бути дозволений.
  ([Тікет #58139](https://github.com/istio/istio/issues/58139))

- **Виправлено** проблему, при якій через неправильне кешування EDS у pilot, ambient E/W gateway або waypoints налаштовувалися з непрацюючими точками доступу EDS.
  ([Тікет #58141](https://github.com/istio/istio/issues/58141))

- **Виправлено** проблему, через яку ресурси Envoy Secret могли застрягати у стані `WARMING`, коли на один і той самий секрет Kubernetes посилалися об’єкти Istio Gateway, використовуючи як формат `secret-name`, так і формат `namespace/secret-name`.
  ([Тікет #58146](https://github.com/istio/istio/issues/58146))

- **Виправлено** проблему, при якій правила nftables для IPv6 програмувалися, коли IPv6 явно вимкнено у режимі ambient.
  ([Тікет #58249](https://github.com/istio/istio/issues/58249))

- **Виправлено** створення таблиці імен DNS для headless сервісів, де записи podʼів не враховували, що podʼи можуть мати кілька IP-адрес.
  ([Тікет #58397](https://github.com/istio/istio/issues/58397))

- **Виправлено** проблему, при якій зʼєднання ambient multi-network вдавалося зламати при використанні довірного домену на кшталт кастомного.
  ([Тікет #58427](https://github.com/istio/istio/issues/58427))

- **Виправлено** проблему, через яку HTTPS-сервери, що оброблялися першими, заважали HTTP-серверам створювати маршрути на тому самому порту з різними адресами прив’язки.
  ([Тікет #57706](https://github.com/istio/istio/issues/57706))

- **Виправлено** проблему, при якій експериментальні ресурси `XListenerSet` не могли отримати доступ до TLS Secret.
