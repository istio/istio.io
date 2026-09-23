---
title: Анонс Istio 1.27.4
linktitle: 1.27.4
subtitle: Патч-реліз
description: Патч-реліз Istio 1.27.4.
publishdate: 2025-12-03
release: 1.27.4
aliases:
    - /news/announcing-1.27.4
---

Цей реліз містить виправлення помилок для покращення надійності. Ця примітка до релізу описує, що змінилося між Istio 1.27.3 та Istio 1.27.4.

Цей реліз впроваджує оновлення безпеки, описані в нашому дописі від 3 грудня, [`ISTIO-SECURITY-2025-003`](/news/security/istio-security-2025-003).

{{< relnote >}}

## Зміни {#changes}

- **Виправлено** конфлікти статусів ресурсів Route у разі встановлення декількох версій Istio.
  ([Тікет #57734](https://github.com/istio/istio/issues/57734))

- **Виправлено** проблему з waypoints, де `EnvoyFilter` з `targetRef` kind `GatewayClass` та group `gateway.networking.k8s.io` у кореневому namespace не працював.

- **Виправлено** збій у роботі `istio-init` під час використання вбудованих nftables у режимі TPROXY, коли анотація `traffic.sidecar.istio.io/includeInboundPorts` була порожньою.
  ([Тікет #58135](https://github.com/istio/istio/issues/58135))

- **Виправлено** проблему, через яку ресурси Envoy Secret могли застрягати у стані `WARMING`, коли на один і той самий секрет Kubernetes посилалися об’єкти Istio Gateway, використовуючи як формат `secret-name`, так і формат `namespace/secret-name`.
  ([Тікет #58146](https://github.com/istio/istio/issues/58146))

- **Виправлено** створення таблиці імен DNS для сервісів без графічного інтерфейсу, де записи про поди не враховували наявність у подів декількох IP-адрес.
  ([Тікет #58397](https://github.com/istio/istio/issues/58397))

- **Виправлено** проблему, через яку HTTPS-сервери, що оброблялися першими, не дозволяли HTTP-серверам створювати маршрути на тому самому порту з різними адресами прив’язки.
  ([Тікет #57706](https://github.com/istio/istio/issues/57706))

- **Виправлено** помилку, при якій експериментальні ресурси `XListenerSet` не могли отримати доступ до TLS Secrets.
