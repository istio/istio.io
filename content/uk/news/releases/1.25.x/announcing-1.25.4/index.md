---
title: Анонс Istio 1.25.4
linktitle: 1.25.4
subtitle: Патч-реліз
description: Патч-реліз Istio 1.25.4.
publishdate: 2025-08-08
release: 1.25.4
---

Цей реліз містить виправлення помилок для покращення надійності. Ця примітка до релізу описує, що змінилося між Istio 1.25.3 та Istio 1.25.4.

{{< relnote >}}

## Зміни {#changes}

- **Виправлено** проблему, через яку оновлення Istio з 1.24 до 1.25 викликало порушення роботи сервісу через попередньо наявні правила iptables. Логіка виявлення двійкових файлів iptables була вдосконалена для перевірки наявності базової підтримки ядра, а також для віддання переваги `nft` у ситуаціях "нічиєї".

- **Виправлено** проблему, через яку `istioctl analyze` помилково видавав IST0134, навіть коли `PILOT_ENABLE_IP_AUTOALLOCATE` було встановлено в `true`.
  ([Issue #56083](https://github.com/istio/istio/issues/56083))

- **Виправлено** паніку в `istioctl manifest translate`, коли конфігурація IstioOperator містила кілька шлюзів.
  ([Issue #56223](https://github.com/istio/istio/issues/56223))

- **Виправлено** індекс ambient для фільтрації конфігурацій за версією.
  ([Issue #56477](https://github.com/istio/istio/issues/56477))

- **Виправлено** неправильне призначення UID та GID для контейнерів `istio-proxy` та `istio-validation` на OpenShift, коли режим TPROXY був увімкнений.

- **Виправлено** логіку для правильного ігнорування мітки `topology.istio.io/network` на системному просторі імен, коли використовуються `discoverySelectors`.
  ([Issue #56687](https://github.com/istio/istio/issues/56687))

- **Виправлено** проблему, через яку журнали доступу не оновлювалися, коли запитуваний сервіс був створений пізніше, ніж ресурс Telemetry.  ([Issue #56825](https://github.com/istio/istio/issues/56825))
