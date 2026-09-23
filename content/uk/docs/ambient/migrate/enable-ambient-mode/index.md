---
title: Увімкнення режиму ambient
description: Позначте простори імен, активуйте waypoints, видаліть інʼєкцію sidecar та перевірте міграцію.
weight: 4
owner: istio/wg-networking-maintainers
test: no
prev: /docs/ambient/migrate/migrate-policies
---

Увімкніть режим ambient по одному простору імен за раз. Це дозволяє вам перевірити кожен простір імен перед переходом до наступного, та відкотити один простір імен, якщо щось піде не так.

{{< warning >}}
**Якщо у вас є політики L7, наразі не існує шляху міграції без простою.** Під час переходу клієнти sidecar обходять waypoints повністю, тому політики L7, привʼязані до waypoint, не застосовуються для трафіку від джерел sidecar. Крім того, старі селектор-базові політики L7 мають бути видалені при перезапуску podʼа та замінені waypoint-базованими еквівалентами — існує короткий проміжок між цими двома операціями, де правила L7 не застосовуються. Це відома прогалина. Плануйте технічне вікно, якщо безперервне
застосування політик L7 обовʼязкове. Ця прогалина є відомим обмеженням і відстежується для покращення в майбутніх релізах.
{{< /warning >}}

## Міграція простору імен {#migrating-a-namespace}

### Вимоги до порядку дій {#ordering-requirements}

{{< warning >}}
Порядок операцій у цьому кроці є критичним. Точно слідуйте послідовності кроків нижче:

1. Активуйте waypoints **перед** увімкненням режиму ambient.
1. Увімкніть режим ambient (позначте простір імен).
1. Видаліть інʼєкцію sidecar **після** підтвердження роботи режиму ambient.
1. Перезапустіть podʼи **врешті-решт**.
{{< /warning >}}

Недотримання цієї послідовності може призвести до того, що трафік буде оброблятися ані sidecar, ані ztunnel, що спричинить порушення роботи ваших робочих навантажень.

### Крок 1: Активуйте waypoints {#step-1-activate-waypoints}

{{< tip >}}
Пропустіть цей крок, якщо ви не використовуєте waypoints.
{{< /tip >}}

Активуйте waypoints, розгорнуті на [попередньому кроці](/docs/ambient/migrate/install-ambient-components/), додавши мітку `istio.io/use-waypoint`.

Для активації waypoint для всього простору імен:

{{< text syntax=bash snip_id=none >}}
$ kubectl label namespace <namespace> istio.io/use-waypoint=waypoint
{{< /text >}}

Для активації waypoint для конкретного Service:

{{< text syntax=bash snip_id=none >}}
$ kubectl label service <service-name> -n <namespace> istio.io/use-waypoint=waypoint
{{< /text >}}

Перевірте, що waypoint готовий:

{{< text syntax=bash snip_id=none >}}
$ kubectl get gateway waypoint -n <namespace>
{{< /text >}}

Стовпець `READY` має показувати `True`.

### Крок 2: Увімкніть режим ambient для простору імен {#step-2-enable-ambient-mode-for-the-namespace}

Додайте мітку `istio.io/dataplane-mode=ambient` до простору імен. Це повідомляє CNI втулку, що нові та перезапущені podʼи в цьому просторі імен мають використовувати ztunnel замість (або поряд з) sidecar:

{{< text syntax=bash snip_id=none >}}
$ kubectl label namespace <namespace> istio.io/dataplane-mode=ambient
{{< /text >}}

Перевірте, що простір імен тепер зарахований у ambient mesh:

{{< text syntax=bash snip_id=none >}}
$ istioctl ztunnel-config workloads -n istio-system | grep <namespace>
{{< /text >}}

Робочі навантаження в просторі імен зʼявляться з `HBONE` як їхнім протоколом. Podʼи все ще мають свої sidecars на цьому етапі. Sidecar має пріоритет над ztunnel для podʼів, що мають обидва.

### Крок 3: Видаліть інʼєкцію sidecar {#step-3-remove-sidecar-injection}

Видаліть мітку інʼєкції sidecar з простору імен:

Якщо ви використовуєте стандартну мітку інʼєкції:

{{< text syntax=bash snip_id=none >}}
$ kubectl label namespace <namespace> istio-injection-
{{< /text >}}

Якщо ви використовуєте мітку ревізії:

{{< text syntax=bash snip_id=none >}}
$ kubectl label namespace <namespace> istio.io/rev-
{{< /text >}}

{{< warning >}}
Видалення мітки інʼєкції саме по собі не видаляє наявні sidecars. Podʼи мають бути перезапущені для введення змін у силу. Не перезапускайте podʼи, доки ви не підтвердили, що режим ambient активний (Крок 2 вище).
{{< /warning >}}

### Крок 4: Перезапустіть podʼи {#step-4-restart-pods}

Перезапустіть робочі навантаження в просторі імен. При перезапуску podʼи піднімуться без sidecar контейнерів і будуть використовувати ztunnel (та waypoint, якщо налаштовано) замість них:

{{< text syntax=bash snip_id=none >}}
$ kubectl rollout restart deployment -n <namespace>
$ kubectl rollout status deployment -n <namespace>
{{< /text >}}

### Крок 5: Видаліть старі sidecar політики {#step-5-remove-old-sidecar-policies}

{{< warning >}}
Зробіть це негайно після перезапуску podʼа, перед запуском будь-якої перевірки. Як тільки sidecars видалені, ztunnel бере на себе застосування політик. ztunnel розуміє лише атрибути L4 і мовчки відкидає будь-які умови L7 (методи HTTP, шляхи, заголовки, принципали запитів) з правил `AuthorizationPolicy`. Ефект залежить від дії політики:

- **Політика `ALLOW` з правилами L7**: ztunnel відкидає умови L7. Якщо кожне правило в політиці покладалося виключно на атрибути L7, отримана політика не має правил і не відповідає нічому, що змушує ztunnel **забороняти весь трафік** до цього робочого навантаження (політика `ALLOW` без правил відповідності нічого не дозволяє).
- **Політика `DENY` з правилами L7**: ztunnel відкидає умови L7. Якщо правило не мало L4 умов з самого початку (наприклад, воно відповідало лише на принципали запитів або HTTP шляхи), видалення частин L7 залишає порожнє співпадіння, яке застосовується до всього трафіку, ефективно **забороняючи весь трафік** до цього робочого навантаження.

У обох випадках, залишення старих селектор-базових політик L7 активними після видалення sidecars заблокує трафік. Видаліть їх негайно.
{{< /warning >}}

Видаліть будь-які ресурси `AuthorizationPolicy`, що використовували робоче навантаження `selector` з правилами L7, тепер, коли вони були замінені `targetRefs`-базованими еквівалентами:

{{< text syntax=bash snip_id=none >}}
$ kubectl delete authorizationpolicy <sidecar-policy-name> -n <namespace>
{{< /text >}}

Також видаліть ресурси `VirtualService` та `DestinationRule`, замінені `HTTPRoute`:

{{< text syntax=bash snip_id=none >}}
$ kubectl delete virtualservice <name> -n <namespace>
$ kubectl delete destinationrule <name> -n <namespace>
{{< /text >}}

Ресурси `AuthorizationPolicy` L4, що використовують `selector` (без правил L7), безпечно зберігати, ztunnel застосовує їх коректно.

### Крок 6: Перевірка {#step-6-validate}

Перевірте, що podʼи працюють без sidecar контейнерів:

{{< text syntax=bash snip_id=none >}}
$ kubectl get pods -n <namespace>
{{< /text >}}

Підтвердьте, що ztunnel керує робочими навантаженнями:

{{< text syntax=bash snip_id=none >}}
$ istioctl ztunnel-config workloads -n istio-system | grep <namespace>
{{< /text >}}

Якщо ви розгорнули waypoints, перевірте, що правила L7 політик та маршрутизації застосовуються waypoint, протестувавши конкретні поведінки (маршрутизація на основі заголовків, обмеження HTTP методів тощо), що визначають ваші ресурси `HTTPRoute` та `AuthorizationPolicy`.

## Повторіть для кожного простору імен {#repeat-for-each-namespace}

Повторіть кроки [Міграція простору імен](#migrating-a-namespace) для кожного простору імен, який ви хочете мігрувати. Простори імен, не позначені `istio.io/dataplane-mode=ambient`, продовжують використовувати свої sidecars і не зазнають впливу.

## Відкат {#rollback}

Кожен крок є незалежно зворотним. Використовуйте процедуру відкату, що відповідає тому, як далеко ви пройшли:

| Крок | Дія відкату |
|---|---|
| Після Кроку 1 (waypoints активовано) | `kubectl label namespace <ns> istio.io/use-waypoint-` |
| Після Кроку 2 (ambient увімкнено) | `kubectl label namespace <ns> istio.io/dataplane-mode-` |
| Після Кроку 3 (інʼєкцію видалено) | Повторно додайте мітку інʼєкції: `kubectl label namespace <ns> istio-injection=enabled` |
| Після Кроку 4 (podʼи перезапущено) | Повторно додайте мітку інʼєкції, потім `kubectl rollout restart deployment -n <ns>` |
| Після Кроку 5 (старі політики видалено) | `kubectl apply -f istio-config-backup.yaml` для відновлення з резервної копії |

Після будь-якого відкату, що включає перезапуск podʼів, перевірте, що podʼи показують 2/2 контейнери (що вказує на повторну інʼєкцію sidecar) та підтвердьте, що трафік тече, перед продовженням.

{{< warning >}}
Відкат після Кроку 5 за допомогою `kubectl apply -f istio-config-backup.yaml` відновлює оригінальні ресурси в стилі sidecar, але також **перезаписує будь-які нові ambient ресурси**, створені під час міграції (такі як правила `HTTPRoute` та `targetRefs`-базовані ресурси `AuthorizationPolicy`), що мають ту саму назву. Перед застосуванням резервної копії видаліть ambient ресурси спочатку, або використовуйте селективний `kubectl apply` на окремих ресурсах замість повного файлу резервної копії.
{{< /warning >}}

## Зміни в спостережовості після міграції {#post-migration-observability-changes}

Після переходу в режим ambient зверніть увагу на такі зміни в телеметрії:

**Метрики**: У режимі sidecar, метрики надаються з `reporter="source"` та `reporter="destination"`. У режимі ambient, метрики від ztunnel використовують `reporter="source"`, а метрики від waypoint проксі використовують `reporter="waypoint"`. Оновіть будь-які дашборди або правила алертингу, що покладаються на мітку `reporter`.

**Обʼєднання метрик**: У режимі sidecar, проксі-агент підтримує [обʼєднання метрик](/docs/ops/integrations/prometheus/#option-1-metrics-merging), яке поєднує метрики Istio та застосунку в єдину ціль сканування за допомогою стандартних анотацій `prometheus.io`. Ця функція недоступна в режимі ambient. Після міграції ви повинні налаштувати Prometheus на сканування компонентів Istio (podʼів ztunnel та waypoint) та ваших додаткових podʼів як окремих цілей. Оновіть будь-які ресурси `PodMonitor` або `ServiceMonitor`, що покладалися на єдину обʼєднану кінцеву точку.

**Трасування**: У режимі sidecar, кожен перехід генерує два відрізки (один від sidecar джерела, один від sidecar призначення). У режимі ambient з waypoints, один відрізок генерується на waypoint. Оновіть SLO на основі трасувань відповідно.

**`istioctl proxy-status`**: Ця команда не показує робочі навантаження ztunnel. Використовуйте `istioctl ztunnel-config workloads` замість цього для перевірки стану ambient проксі.

Для отримання додаткової інформації див.:

- [Вирішення проблем з ztunnel](/docs/ambient/usage/troubleshoot-ztunnel/)
- [Вирішення проблем з waypoints](/docs/ambient/usage/troubleshoot-waypoint/)
