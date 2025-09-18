---
title: Анонс Istio 1.27.1
linktitle: 1.27.1
subtitle: Патч-реліз
description: Патч-реліз Istio 1.27.1.
publishdate: 2025-09-03
release: 1.27.1
aliases:
    - /news/announcing-1.27.1
---

Цей реліз містить виправлення помилок для покращення надійності. Ця примітка до релізу описує, що змінилося між Istio 1.27.0 та 1.27.1.

This release implements the security updates described in our 3rd of September post, [`ISTIO-SECURITY-2025-001`](/news/security/istio-security-2025-001).

{{< relnote >}}

## Зміни {#changes}

- **Виправлено** проблему, через яку `istio-iptables` іноді ігнорував стан IPv4 на користь стану IPv6 під час прийняття рішення про необхідність застосування нових правил iptables.
  ([Issue #56587](https://github.com/istio/istio/issues/56587))

- **Виправлено** помилку, через яку наш код спостереження за теґами не вважав стандартну ревізію такою ж, як стандартний теґ. Це могло спричинити проблеми, через які шлюзи Kubernetes не програмувалися.
  ([Issue #56767](https://github.com/istio/istio/issues/56767))

- **Виправлено** проблему, що спричиняла помилки під час інсталяції чарту Gateway у Helm v3.18.5 через більш суворий валідатор схеми JSON. Схема чарту була оновлена для забезпечення сумісності.
  ([Issue #57354](https://github.com/istio/istio/issues/57354))

- **Виправлено** проблему, через яку опція `PreserveHeaderCase` перевизначала інші опції протоколу HTTP/1.x, такі як HTTP/1.0.
  ([Issue #57528](https://github.com/istio/istio/issues/57528))

- **Виправлено** зміну у виводі команди `istioctl proxy-status`, щоб вона була більш сумісною з попередніми версіями.
  ([Issue #57339](https://github.com/istio/istio/issues/57339))

- **Виправлено** логіку виявлення iptables, щоб перейти до `iptables-nft`, коли модуль `iptable_nat` відсутній.
  ([Issue #57380](https://github.com/istio/istio/issues/57380))

- **Виправлено** помилку, яка неправильно відхиляла політики трафіку, коли було встановлено лише `retry_budget`.
