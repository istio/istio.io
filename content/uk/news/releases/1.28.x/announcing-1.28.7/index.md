---
title: Анонс Istio 1.28.7
linktitle: 1.28.7
subtitle: Патч-реліз
description: Патч-реліз Istio 1.28.7.
publishdate: 2026-05-18
release: 1.28.7
aliases:
    - /news/announcing-1.28.7
---

Цей реліз містить виправлення помилок для підвищення надійності. Ця примітка до релізу описує, що змінилося між Istio 1.28.6 та 1.28.7.

{{< relnote >}}

## Зміни {#changes}

- **Додано** підтримку Gateway API v1.4.1.

- **Додано** попередження `istioctl analyze` (IST0175) у разі, якщо ресурси `RequestAuthentication` існують, але параметр `BLOCKED_CIDRS_IN_JWKS_URIS` не налаштований в istiod.
  ([Тікет #59523](https://github.com/istio/istio/issues/59523))

- **Додано** прапорці функцій `PILOT_HBONE_INITIAL_STREAM_WINDOW_SIZE` та `PILOT_HBONE_INITIAL_CONNECTION_WINDOW_SIZE`. Вони дозволяють налаштовувати початкові розміри вікон потоку та з’єднання для з’єднань HBONE із кластерами вищого рівня (що генеруються для точок маршруту та шлюзів «схід-захід»). Ці параметри можна використовувати для зменшення небажаного буферизації.
  ([Тікет #59961](https://github.com/istio/istio/issues/59961))

- **Виправлено** проблему, через яку waypoints не додавали фільтр прослуховувача TLS-інспектора, коли були наявні лише TLS-порти, що призводило до збою маршрутизації на основі SNI для ресурсів `ServiceEntry` із символами-замінниками та параметром `resolution: DYNAMIC_DNS`.
  ([Тікет #59024](https://github.com/istio/istio/issues/59024))

- **Виправлено** проблему, при якій Istiod міг видавати leaf certificates із `NotAfter` часом, що перевищує термін дії сертифіката підписанта.
  ([Тікет #59768](https://github.com/istio/istio/issues/59768))

- **Виправлено** збій kubelet health probe для ambient mesh pods на AWS EKS при використанні Security Groups for Pods (branch ENI). istio-cni тепер детектує branch ENI pods та додає IP rules для маршрутизації probe traffic через veth pair замість VPC fabric. Це обмежено прапорцем функцій `AMBIENT_ENABLE_AWS_BRANCH_ENI_PROBE` (увімкнено за замовчуванням).

- **Виправлено**: точки доступу налагодження XDS (`istio.io/debug/syncz` та `istio.io/debug/config_dump`), що обслуговуються `StatusGen`, тепер забезпечують авторизацію в межах одного простору імен для несистемних викликів. Раніше авторизоване робоче навантаження з будь-якого простору імен могло перелічувати проксі-сервери та отримувати дампи конфігурації для робочих навантажень в інших просторах імен.

**Подяка**: Цю вразливість виявив і повідомив [1seal](https://github.com/1seal).

## Оновлення безпеки {#security-update}

- **Виправлено** обхід авторизації у `AuthorizationPolicy`, коли regex метасимволи у певних полях identity, вбудованих у згенерований Envoy `SafeRegex`, не екранувалися. Таким чином, легальні імена Kubernetes, що містять символи типу `.` або `[`, могли трактуватися як regex-символи, що дозволяло отримувати доступ ідентичностям поза намірами автора політики. Це впливало на `source.principals` (зокрема на суфіксні збіги, що починаються з `*`) та `source.namespaces`.
  ([Тікет #59992](https://github.com/istio/istio/issues/59992))

**Подяка**: Цю вразливість виявив і повідомив [Alex](https://github.com/Alex0Young).
