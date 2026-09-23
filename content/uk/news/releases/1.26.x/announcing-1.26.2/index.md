---
title: Анонс Istio 1.26.2
linktitle: 1.26.2
subtitle: Патч-реліз
description: Патч-реліз Istio 1.26.2.
publishdate: 2025-06-20
release: 1.26.2
aliases:
    - /news/announcing-1.26.2
---

Цей реліз містить виправлення помилок для покращення надійності. Ця примітка до релізу описує, що змінилося між Istio 1.26.1 та 1.26.2.

{{< relnote >}}

## Зміни {#changes}

- **Виправлено** неправильне призначення UID та GID для контейнерів `istio-proxy` та `istio-validation` на OpenShift, коли увімкнено режим TPROXY.

- **Виправлено** проблему, через яку зміна обʼєкта `HTTPRoute` могла призвести до аварійного завершення `istiod`.
  ([Issue #56456](https://github.com/istio/istio/issues/56456))

- **Виправлено** стан перегонів, через який оновлення статусу для обʼєктів Kubernetes могли бути пропущені `istiod`.
  ([Issue #56401](https://github.com/istio/istio/issues/56401))
