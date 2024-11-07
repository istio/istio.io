---
title: Використання політики безпеки 4-го рівня
description: Підтримуються функції безпеки, коли використовується лише захищений L4 overlay.
weight: 20
owner: istio/wg-networking-maintainers
test: no
---

Функції рівня 4 (L4) в політиках безпеки Istio [підтримуються](/docs/concepts/security) {{< gloss >}}ztunnel{{< /gloss >}}, і доступні в {{< gloss "ambient" >}}ambient режимі{{< /gloss >}}. [Kubernetes Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/) також продовжують працювати, якщо у вашому кластері є {{< gloss >}}CNI{{< /gloss >}} втулок, що їх підтримує, і можуть використовуватися для забезпечення глибокого захисту.

Шарування ztunnel та {{< gloss "waypoint" >}}waypoint проксі{{< /gloss >}} дає вам можливість вибирати, чи хочете ви увімкнути обробку рівня 7 (L7) для конкретного навантаження. Щоб використовувати L7 політики та функції маршрутизації трафіку Istio, ви можете [розгорнути waypoint](/docs/ambient/usage/waypoint) для своїх навантажень. Оскільки політику тепер можна застосовувати у двох місцях, є [міркування](#considerations), які потрібно розуміти.

## Застосування політики за допомогою ztunnel {#policy-enforcement-using-ztunnel}

Проксі ztunnel може здійснювати застосування політики авторизації, коли навантаження зареєстроване в {{< gloss "Захищений L4 Overlay" >}}режимі secure overlay{{< /gloss >}}. Точка застосування — це проксі-приймач (з боку сервера) ztunnel на шляху зʼєднання.

Основна політика авторизації L4 виглядає наступним чином:

{{< text yaml >}}
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
 name: allow-curl-to-httpbin
spec:
 selector:
   matchLabels:
     app: httpbin
 action: ALLOW
 rules:
 - from:
   - source:
       principals:
       - cluster.local/ns/ambient-demo/sa/curl
{{< /text >}}

Ця політика може використовуватися як в {{< gloss "sidecar" >}}sidecar режимі{{< /gloss >}}, так і в ambient режимі.

Особливості L4 (TCP) в API `AuthorizationPolicy` Istio мають таку саму функціональну поведінку в ambient режимі, як і в sidecar режимі. Коли політика авторизації не надана, стандартна дія — `ALLOW`. Після того, як політику створено, podʼи, на які вона поширюється, пропускають лише той трафік, який явно дозволено. У наведеному вище прикладі podʼи з міткою `app: httpbin` дозволяють трафік тільки з джерел з ідентичністю принципал `cluster.local/ns/ambient-demo/sa/curl`. Трафік з усіх інших джерел буде заборонено.

## Цільова політика {#targeting-policies}

Режим sidecar і L4 політики в ambient режимі *цілеспрямовані* однаково: вони охоплюються простором імен, у якому знаходиться об’єкт політики, та необов’язковим `selector` у `spec`. Якщо політика знаходиться в кореневому просторі імен Istio (традиційно `istio-system`), тоді вона буде охоплювати всі простори імен. Якщо вона знаходиться в іншому просторі імен, вона буде охоплювати лише цей простір імен.

L7 політики в ambient режимі застосовуються waypoint’ами, які налаштовуються за допомогою {{< gloss "gateway api" >}}Kubernetes Gateway API{{< /gloss >}}. Вони *прикріплюються* за допомогою поля `targetRef`.

## Дозволені атрибути політики {#allowed-policy-attributes}

Правила політики авторизації можуть містити вирази [source](/docs/reference/config/security/authorization-policy/#Source) (`from`), [operation](/docs/reference/config/security/authorization-policy/#Operation) (`to`) та [condition](/docs/reference/config/security/authorization-policy/#Condition) (`when`).

Цей список атрибутів визначає, чи політика вважається лише L4:

| Тип | Атрибут | Позитивний збіг | Негативний збіг |
| --- | --- | --- | --- |
| Source | Ідентичність учасника | `principals` | `notPrincipals` |
| Source | Простір імен | `namespaces` | `notNamespaces` |
| Source | IP блок | `ipBlocks` | `notIpBlocks` |
| Operation | Порт призначення | `ports` | `notPorts` |
| Condition | IP джерела | `source.ip` | n/a |
| Condition | Простір імен джерела | `source.namespace` | n/a |
| Condition | Ідентичність джерела | `source.principal` | n/a |
| Condition | Віддалений IP | `destination.ip` | n/a |
| Condition | Віддалений порт | `destination.port` | n/a |

### Політики з умовами рівня 7 {#policies-with-layer-7-conditions}

ztunnel не може застосовувати політики L7. Якщо політика з правилами, що відповідають атрибутам L7 (тобто тим, які не вказані в таблиці вище), націлена на те, щоб її застосовував приймальний ztunnel, вона буде безпечною, ставши політикою `DENY`.

Цей приклад додає перевірку методу HTTP GET:

{{< text yaml >}}
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
 name: allow-curl-to-httpbin
spec:
 selector:
   matchLabels:
     app: httpbin
 action: ALLOW
 rules:
 - from:
   - source:
       principals:
       - cluster.local/ns/ambient-demo/sa/curl
   to:
   - operation:
       methods: ["GET"]
EOF
{{< /text >}}

Навіть якщо ідентичність клієнтського podʼа є правильною, наявність атрибута L7 змушує ztunnel відмовити у зʼєднанні:

{{< text plain >}}
command terminated with exit code 56
{{< /text >}}

## Вибір точок застосування при додаванні waypoint {#considerations}

Коли до навантаження додається waypoint проксі, у вас тепер є два можливі місця, де можна застосувати політику L4. (Політику L7 можна застосувати лише в waypoint проксі.)

За наявності лише secure overlay трафік з’являється в цільовому ztunnel з ідентифікатором *джерела* навантаження.

Waypoint проксі не видають себе за джерело навантаження. Після того, як ви ввели waypoint у шлях трафіку, цільовий ztunnel буде бачити трафік з ідентичністю *waypoint’а*, а не джерела.

Це означає, що коли у вас встановлено waypoint, **ідеальне місце для застосування політики змінюється**. Навіть якщо ви бажаєте застосовувати політику лише до атрибутів L4, якщо ви залежите від ідентичності джерела, вам слід прикріпити свою політику до свого waypoint проксі. Друга політика може бути спрямована на ваше навантаження, щоб його ztunnel застосовував політики на зразок "внутрішній трафік сервісної мережі повинен надходити з мого waypoint’а, щоб досягти мого застосунку".

## Автентифікація учасників {#peer-authentication}

Політики [автентифікації учасників](/docs/concepts/security/#peer-authentication) Istio, які налаштовують режими взаємного TLS (mTLS), підтримуються ztunnel.

Стандартна політика для ambient режиму — `PERMISSIVE`, яка дозволяє podʼам приймати як mTLS-зашифрований трафік (зсередини mesh), так і незашифрований трафік (ззовні). Увімкнення режиму `STRICT` означає, що podʼи прийматимуть лише mTLS-зашифрований трафік.

Оскільки ztunnel і {{< gloss >}}HBONE{{< /gloss >}} передбачають використання mTLS, неможливо використовувати режим `DISABLE` в політиці. Такі політики будуть проігноровані.
