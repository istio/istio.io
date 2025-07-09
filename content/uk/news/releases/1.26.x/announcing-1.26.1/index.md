---
title: Анонс Istio 1.26.1
linktitle: 1.26.1
subtitle: Патч-реліз
description: Патч-реліз Istio 1.26.1.
publishdate: 2025-05-29
release: 1.26.1
---

Цей реліз містить виправлення помилок для покращення надійності. Ця примітка до релізу описує, що змінилося між Istio 1.26.0 та 1.26.1.

## Управління трафіком {#traffic-management}

- **Оновлено** версію Gateway API до `1.3.0` з `1.3.0-rc.1`. ([Issue #56310](https://github.com/istio/istio/issues/56310))

- **Виправлено** регресію в Istio 1.26.0, яка викликала паніку в istiod при обробці імен хостів Gateway API. ([Issue #56300](https://github.com/istio/istio/issues/56300))

## Безпека {#security}

- **Виправлено** проблему в функції `pluginca`, коли `istiod` просто повертався до самопідписного CA, якщо наданий пакет `cacerts` був неповним. Система тепер правильно перевіряє наявність усіх необхідних файлів CA і завершує з помилкою, якщо пакет неповний.

## Встановлення {#installation}

- **Виправлено** паніку в `istioctl manifest translate`, коли конфігурація `IstioOperator` містила кілька шлюзів. ([Issue #56223](https://github.com/istio/istio/issues/56223))

## istioctl

- **Виправлено** хибні спрацьовування, коли `istioctl analyze` викликав помилку `IST0134`, навіть коли `PILOT_ENABLE_IP_AUTOALLOCATE` було встановлено в `true`. ([Issue #56083](https://github.com/istio/istio/issues/56083))
