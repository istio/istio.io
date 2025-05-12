---
title: Анонс Istio 1.23.6
linktitle: 1.23.6
subtitle: Патч-реліз
description: Патч-реліз Istio 1.23.6.
publishdate: 2025-04-07
release: 1.23.6
aliases:
    - /uk/news/announcing-1.23.6
---

Цей реліз містить виправлення помилок для покращення надійності. Ця примітка до релізу описує, що змінилося між Istio 1.23.5 та Istio 1.23.6.

{{< relnote >}}

## Оновлення безпеки {#security-updates}

- [CVE-2025-30157](https://nvd.nist.gov/vuln/detail/CVE-2025-30157) (CVSS Score 6.5, Medium): Envoy аварійно завершує роботу, коли HTTP `ext_proc` обробляє локальні відповіді.

Для цілей Istio ця CVE може бути використана лише у випадку, коли `ext_proc` налаштовано через `EnvoyFilter`.

## Зміни {#changes}

- **Виправлено** проблему, яка полягала у тому, що налаштування імені сокета ідентифікатора робочого навантаження SDS
  через `WORKLOAD_IDENTITY_SOCKET_FILE` не працювало через те, що не було оновлено завантажувач Envoy.
  ([Тікет #51979](https://github.com/istio/istio/issues/51979))

- **Виправлено** проблему, через яку Istiod виходив з ладу з помилкою LDS для проксі <1.23, коли `meshConfig.accessLogEncoding` встановлено у `JSON`.
  ([Тікет #55116](https://github.com/istio/istio/issues/55116))

- **Виправлено** проблему, коли шаблон інʼєкції `gateway` не враховував контейнер `kubectl.kubernetes.io/default-logs-container` та `kubectl.kubernetes.io/default-logs-container`.
  та `kubectl.kubernetes.io/default-container` анотації.

- **Виправлено** проблему, яка призводила до відхилення валідаційного веб-хука, якщо він мав `connectionPool.tcp.IdleTimeout=0s`.
  ([Тікет #55409](https://github.com/istio/istio/issues/55409))

- **Виправлено** проблему, яка полягала у тому, що веб-хук перевірки некоректно повідомляв про попередження, коли `ServiceEntry` налаштовував `workloadSelector` з роздільною здатністю DNS.
  ([Тікет #50164](https://github.com/istio/istio/issues/50164))

- **Виправлено** проблему, через яку вхідні шлюзи не використовували виявлення WDS для отримання метаданих для пунктів призначення ambient.

- **Виправлено** трафік DNS (UDP і TCP) тепер впливає на анотації трафіку, такі як `traffic.sidecar.istio.io/excludeOutboundIPRanges` і `traffic.sidecar.istio.istio.io/excludeOutboundPorts`. Раніше UDP/DNS трафік однозначно ігнорував ці анотації трафіку, навіть якщо був вказаний порт DNS, через структуру правил. Зміна поведінки фактично відбулася у серії випусків 1.23, але її не було зазначено у примітках до випуску 1.23.
  ([Тікет #53949](https://github.com/istio/istio/issues/53949))
