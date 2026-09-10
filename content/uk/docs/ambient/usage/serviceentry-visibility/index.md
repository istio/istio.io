---
title: Видимість ServiceEntry
description: Керуйте тим, які простори імен можуть виявляти та визначати кожен ServiceEntry.
weight: 40
keywords: [ambient,serviceentry,visibility]
owner: istio/wg-networking-maintainers
test: no
---

[`ServiceEntry`](/docs/reference/config/networking/service-entry/) додає сервіс до внутрішнього реєстру сервісів Istio. Зазвичай, `ServiceEntry` видимий для кожного робочого навантаження в mesh: будь-хто, хто може створити `ServiceEntry` в *будь-якому* просторі імен, може визначити *будь-яку* назву хоста, наприклад `example.com`, і вплинути на те, як весь mesh визначає та маршрутизує до нього.

Поле [`exportTo`](/docs/ops/configuration/mesh/configuration-scoping/) не захищає від цього, оскільки воно оголошується самим автором `ServiceEntry`: воно дозволяє власнику сервісу визначати область дії того, що він публікує, але не встановлює жорстких обмежень. Раніше адміністратору мережі потрібно було обмежувати створення `ServiceEntry` за допомогою зовнішнього контролю доступу, такого як `ValidatingAdmissionPolicy` у Kubernetes або веб-хук.

Починаючи з Istio 1.31, налаштування mesh [`serviceEntryVisibility`](/docs/reference/config/istio.mesh.v1alpha1/#ServiceEntryVisibility) дає адміністратору mesh цей контроль з одного місця. {{< gloss >}}ambient{{< /gloss >}} data plane ({{< gloss >}}ztunnel{{< /gloss >}} та {{< gloss "waypoint" >}}waypoints{{< /gloss >}}) враховує видимість, коли вона налаштована; sidecars та gateways можуть [підключитися](#extending-visibility-to-sidecars-and-gateways). Функція є інертною, якщо не налаштована: якщо `serviceEntryVisibility` не встановлено, нічого не змінюється.

Ця конструкція навмисно відтворює звичний шаблон Kubernetes: `RoleBinding` діє лише в межах власного простору імен, тоді як створення ефекту на рівні всього кластера за допомогою `ClusterRoleBinding` зарезервовано для адміністраторів кластера. `serviceEntryVisibility` дозволяє адміністратору мережі застосовувати ту саму модель до `ServiceEntry`: встановивши `defaultVisibility: NAMESPACE`, адміністратор змушує кожен `ServiceEntry` поводитися як будь-який інший ресурс у межах простору імен, а видимість за межами власного простору імен `ServiceEntry` стає можливістю, яку адміністратор надає явно.

## Як визначається видимість {#how-visibility-is-resolved}

Коли `serviceEntryVisibility` налаштовано, istiod визначає видимість для кожного `ServiceEntry`:

1. Список `policies` оцінюється по черзі. Перша політика, чиї `matchingRules` всі відповідають (AND семантика), визначає видимість.
1. Якщо жодна політика не відповідає, застосовується `defaultVisibility`.

Сьогодні єдине правило відповідності — `namespaceSelector`: стандартний Kubernetes label selector, що оцінюється проти міток **простору імен, в якому визначено `ServiceEntry`**.

{{< tip >}}
Кожен простір імен автоматично несе мітку `kubernetes.io/metadata.name`, тому `namespaceSelector` може відповідати простору імен за назвою.
{{< /tip >}}

`ServiceEntry` вирішується до однієї з трьох видимостей:

| Видимість | Значення |
| --- | --- |
| `PUBLIC` | Видимий для кожного робочого навантаження, підключеного до цієї панелі управління. Це наявна поведінка, і стандартне значення, коли `defaultVisibility` не встановлено. |
| `NAMESPACE` | Видимий лише в межах простору імен, де визначено `ServiceEntry`. |
| `NONE` | Не видимий нікому: `ServiceEntry` може бути записаний, але Istio не налаштовує для нього панель даних. Корисно для явної заборони класу `ServiceEntry`. |

Див. [довідник конфігурації mesh](/docs/reference/config/istio.mesh.v1alpha1/#ServiceEntryVisibility) для повної документації полів.

## Налаштування видимості {#configure-visibility}

Наступна конфігурація тримає кожен `ServiceEntry` приватним у власному просторі імен, дозволяючи ресурсам `ServiceEntry` в `istio-system`, просторі імен, до якого має доступ лише адміністратор mesh, бути публікованими у всьому mesh:

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    serviceEntryVisibility:
      # ServiceEntries, що не відповідають жодній політиці нижче, залишаються в своєму просторі імен.
      defaultVisibility: NAMESPACE
      policies:
        # ServiceEntries в istio-system видимі mesh-wide.
        - visibility: PUBLIC
          matchingRules:
            - namespaceSelector:
                matchLabels:
                  kubernetes.io/metadata.name: istio-system
{{< /text >}}

Політики також можуть надавати видимість групам просторів імен. Наприклад, політика, що відповідає мітці простору імен `trusted: "true"`, дозволяє делегувати здатність публікувати mesh-wide `ServiceEntry` ресурси шляхом позначення просторів імен.

## Видимість у режимі ambient {#visibility-in-ambient-mode}

Коли `serviceEntryVisibility` налаштовано, ambient data plane завжди враховує її. Istiod визначає видимість кожного `ServiceEntry` та розподіляє її з визначенням сервісу; ztunnel потім застосовує її на стороні клієнта, на основі простору імен робочого навантаження, що робить запит:

* `PUBLIC` сервіс поводиться саме як раніше.
* `NAMESPACE` сервіс може бути виявлений та визначений робочими навантаженнями у власному просторі імен. Для робочих навантажень у кожному іншому просторі імен, це так, ніби `ServiceEntry` ніколи не існував.
* `NONE` сервіс ніколи не доставляється до жодного data plane.

### Приховане означає відсутнє, а не заблоковане {#hidden-means-absent-not-blocked}

{{< warning >}}
Видимість приховує `ServiceEntry`; вона не блокує трафік. Клієнти поза простором імен не отримують відповідей `NXDOMAIN` чи відмов у зʼєднанні — вони поводяться саме так, ніби `ServiceEntry` ніколи не було створено.
{{< /warning >}}

Це зроблено навмисно: якби ztunnel, навпаки, відхиляв DNS-запити щодо прихованих імен хостів, то `ServiceEntry`, що заявляє про `example.com` в одному просторі імен, призвів би до порушення роботи `example.com` у всій мережі — саме цю проблему й покликана вирішувати ця функція. Конкретно, для клієнта, що знаходиться поза простором імен `ServiceEntry`:

* **DNS**: запит для прихованого хостнейму перенаправляється до upstream резолвера, повертаючи реальну відповідь (або реальний `NXDOMAIN`, якщо назва не існує публічно).
* **Адреси**: трафік до IP адреси, яку претендує лише прихований `ServiceEntry`, обробляється як невідомий трафік і пропускається до його оригінального призначення.
* **Спільні хостнейми**: якщо прихований `ServiceEntry` та `PUBLIC` визначають однакову назву хоста, клієнти поза простором імен прихованого запису завжди обслуговуються `PUBLIC` визначенням.

### Waypoints

Привʼязка waypoint з іншого простору імен до `NAMESPACE`-видимості `ServiceEntry` дозволила б трафіку та конфігурації вийти за межі простору імен, тому control plane відмовляє в [cross-namespace waypoint](/docs/ambient/usage/waypoint/#usewaypointnamespace) привʼязках для них. Відмова повідомляється в статусі `ServiceEntry` з умовою `istio.io/WaypointBound: False` та причиною `CrossNamespaceWaypointForbidden`.

Привʼязка waypoint в *тому самому* просторі імен працює нормально, а ресурси `PUBLIC` `ServiceEntry` не зазнають впливу.

## Розширення видимості на sidecars та gateways {#extending-visibility-to-sidecars-and-gateways}

У {{< gloss >}}sidecar{{< /gloss >}} режимі, власники сервісів вже обмежують свої ресурси `ServiceEntry` за допомогою `exportTo`, тому врахування видимості є opt-in для sidecars, дозволяючи інкрементальне прийняття під час ambient міграції без зміни робочого sidecar розгортання:

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    serviceEntryVisibility:
      defaultVisibility: NAMESPACE
      applyToSidecars: true
{{< /text >}}

З увімкненим `applyToSidecars`, визначена видимість діє як потолок на `exportTo` `ServiceEntry`: ефективна область — це перетин оголошеного `exportTo` та отриманої видимості. Незважаючи на назву поля, це застосовується до всіх Envoy-базових проксі, включаючи ingress та egress gateways.

Видимість може звужувати те, що оголошує `exportTo`, але ніколи не розширює його. У режимі sidecar, `exportTo` є [механізмом scoping конфігурації](/docs/ops/configuration/mesh/configuration-scoping/), що контролює, скільки конфігурації istiod надсилає до кожного проксі. Розширення його для відповідності ширшій видимості відправило б конфігурацію `ServiceEntry` назад у проксі, які його власник навмисно виключив з scoping. Видимість є тому лише обмеженням: `ServiceEntry` з `exportTo` вузьшим за свою видимість зберігає свою вузьшу область.

{{< tip >}}
Клієнти sidecar можуть маршрутизувати до `ServiceEntry` з авто-розподіленою адресою лише якщо увімкнено [DNS proxying](/docs/ops/configuration/traffic-management/dns-proxy/). У режимі ambient, ztunnel надає цю DNS обробку автоматично.
{{< /tip >}}

## Перевірка видимості {#verify-visibility}

Коли `serviceEntryVisibility` налаштовано, istiod повідомляє видимість, яку отримав data plane, як умову статусу `ServiceEntry` типу `istio.io/VisibilityApplied`, з причиною, що вказує на застосовану видимість:

{{< text syntax=bash >}}
$ kubectl get serviceentry my-service -n team-a -o jsonpath='{.status.conditions[?(@.type=="istio.io/VisibilityApplied")].reason}'
Namespace
{{< /text >}}

Статус стану завжди `True`; поле `reason` несе визначену видимість (`Public` або `Namespace`). Коли `serviceEntryVisibility` не налаштовано, умова не записується.

{{< warning >}}
`NONE` `ServiceEntry` наразі не отримує жодного стану. Це відоме обмеження: не використовуйте відсутність стану для висновку, що видимість не застосовується.
{{< /warning >}}

Ви також можете перевірити видимість, яку ztunnel застосовує для кожного сервісу, про який він знає. JSON та YAML виводи `istioctl ztunnel-config service` включають поле `visibility`:

{{< text syntax=bash >}}
$ istioctl ztunnel-config service --service-namespace team-a -o yaml
{{< /text >}}

Kubernetes `Service`и завжди повідомляють `Public`; `ServiceEntry`-backed сервіси повідомляють свою визначену видимість. Крім того, ztunnel логує на рівні `debug` щоразу, коли він приховує сервіс від клієнта під час резолвингу.

## Що видимість НЕ робить {#what-visibility-does-not-do}

* **Видимість не є авторизацією.** Видимість контролює, чи клієнт може *виявити та визначити* сервіс; вона не вирішує, чи дозволений вхідний запит. Використовуйте [`AuthorizationPolicy`](/docs/reference/config/security/authorization-policy/) для контролю того, які клієнти можуть отримати доступ до робочого навантаження — див. [Layer 4 security policy](/docs/ambient/usage/l4-policy/).
* **Видимість не є секретністю.** Зменшення видимості `ServiceEntry` регулює, які клієнтські робочі навантаження виконують визначення; вона не приховує існування сервісу. Ресурс залишається читабельним через Kubernetes API відповідно до RBAC, і сервіс все ще зʼявляється в дампах конфігурації data plane, таких як `istioctl ztunnel-config service`.
* **Вона застосовується лише до `ServiceEntry`.** Kubernetes `Service`и завжди видимі mesh-wide в режимі ambient.
* **Немає audit або warn-only режиму.** Коли налаштовано, видимість завжди набирає чинності.

## Дивіться також {#see-also}

* [Довідник з конфігурації mesh `ServiceEntryVisibility`](/docs/reference/config/istio.mesh.v1alpha1/#ServiceEntryVisibility)
* [Область дії конфігурації](/docs/ops/configuration/mesh/configuration-scoping/) — `exportTo` та `Sidecar` для режиму sidecar, а також `discoverySelectors`, які застосовуються в будь-якому режимі площини даних
* [Проксі-сервери DNS](/docs/ops/configuration/traffic-management/dns-proxy/)
* [Налаштування проксі-серверів Waypoint](/docs/ambient/usage/waypoint/)
