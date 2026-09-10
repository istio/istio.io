---
title: Міграція політик
description: Перетворіть політики трафіку та авторизації sidecar для використання в режимі ambient.
weight: 3
owner: istio/wg-networking-maintainers
test: no
prev: /docs/ambient/migrate/install-ambient-components
next: /docs/ambient/migrate/enable-ambient-mode
---

{{< tip >}}
**Ви можете пропустити цю сторінку.** Якщо ви використовуєте лише правила `AuthorizationPolicy` L4 (без відповідності `methods`, `paths` або `headers`), не маєте ресурсів `VirtualService` або `DestinationRule`, і не маєте ресурсів `EnvoyFilter`, `WasmPlugin` або `RequestAuthentication`, ваші наявні політики працюватимуть в режимі ambient без змін. Перейдіть безпосередньо до [Увімкнення режиму ambient](/docs/ambient/migrate/enable-ambient-mode/).
{{< /tip >}}

У режимі ambient, керування трафіком L7 обробляється {{< gloss >}}waypoint{{< /gloss >}} проксі замість sidecar проксі. Це змінює те, як політики виражаються та застосовуються:

- **`VirtualService`** підтримка з waypoints є **Alpha**. Хоча це може працювати в окремих випадках, наполегливо рекомендується перейти на використання `HTTPRoute`. Змішування `VirtualService` та `HTTPRoute` для одного робочого навантаження не підтримується і призводить до невизначеної поведінки.
- **`DestinationRule`** політики трафіку (налаштування пулу зʼєднань, виявлення викидів, TLS) підтримуються waypoints і не вимагають змін. Проте, `HTTPRoute` використовує Kubernetes Services як `backendRefs` для маршрутизації замість підмножин DestinationRule, тому версійне розділення трафіку в `HTTPRoute` вимагає окремих Services для кожної версії.
- **`AuthorizationPolicy`** ресурси, що використовують правила L7 (методи HTTP, шляхи або заголовки), або що використовують `action: CUSTOM` або `action: AUDIT`, мають використовувати `targetRefs` (замість робочого навантаження `selector`) для привʼязки політики до підтримуваних ресурсів, для отримання додаткової інформації перевірте [документацію AuthorizationPolicy](/docs/reference/config/security/authorization-policy/#AuthorizationPolicy-targetRefs).
- **`RequestAuthentication`** та **`WasmPlugin`** ресурси вимагають waypoint проксі і мають бути цілеспрямовані за допомогою `targetRefs` для вказівки на waypoint.
- **`EnvoyFilter`** ресурси **не підтримуються на waypoints**. Якщо у вас є ресурси `EnvoyFilter`, що конфігурують поведінку sidecar проксі, вони будуть мовчки ігноруватися після міграції і мають бути оброблені перед продовженням:
  - Якщо фільтр додає власну функціональність Envoy, оцініть, чи може `WasmPlugin` забезпечити еквівалентну поведінку на waypoint.
  - Якщо фільтр більше не потрібен, видаліть його.
  - Якщо немає ambient-сумісної альтернативи, це є блокером міграції. Не продовжуйте, доки залежність не буде вирішена.

## Аудит ваших наявних політик {#audit-your-existing-policies}

Почніть з переліку всіх L7 ресурсів у вашому кластері:

{{< text syntax=bash snip_id=none >}}
$ kubectl get virtualservice,destinationrule -A
{{< /text >}}

Визначте ресурси `AuthorizationPolicy`, що знадобляться waypoint (правила L7 або `CUSTOM`/`AUDIT` дії):

{{< text syntax=bash snip_id=none >}}
$ kubectl get authorizationpolicy -A --no-headers | while read ns name rest; do
    if kubectl get authorizationpolicy "$name" -n "$ns" -o yaml | grep -qE "(methods:|paths:|headers:|action: CUSTOM|action: AUDIT)"; then
      echo "$ns/$name"
    fi
  done
{{< /text >}}

Визначте ресурси `DestinationRule` з підмножинами (вони вимагають версійно-специфічних Services в режимі ambient):

{{< text syntax=bash snip_id=none >}}
$ kubectl get destinationrule -A --no-headers | while read ns name rest; do
    if kubectl get destinationrule "$name" -n "$ns" -o yaml | grep -q "subsets:"; then
      echo "$ns/$name"
    fi
  done
{{< /text >}}

## Міграція VirtualService на HTTPRoute {#migrate-virtualservice-to-httproute}

{{< warning >}}
Підтримка `VirtualService` з waypoints є Alpha і може зламатися в майбутніх релізах. Мігруйте ваші ресурси `VirtualService` на `HTTPRoute` перед завершенням міграції. Не слід залишати ресурси `VirtualService` та `HTTPRoute`, які спрямовані на одне й те саме робоче навантаження, оскільки це призводить до непередбачуваної поведінки.
{{< /warning >}}

`HTTPRoute` є стабільним, підтримуваним API маршрутизації L7 для режиму ambient.

{{< tip >}}
Інструмент спільноти [ingress2gateway](https://github.com/kubernetes-sigs/ingress2gateway) може автоматизувати частину цього перетворення. Його [Istio провайдер](https://github.com/kubernetes-sigs/ingress2gateway/blob/main/pkg/i2gw/providers/istio/README.md) перетворює ресурси `VirtualService` на `HTTPRoute`, `TLSRoute` та `TCPRoute`, і генерує ресурси `ReferenceGrant` для cross-namespace посилань. Поля, що не можуть бути перетворені безпосередньо, логуються та пропускаються, тому завжди переглядайте згенерований вивід перед застосуванням до вашого кластера. Зверніть увагу, що також ресурси `IngressGateway` перетворюються на ресурси Gateway API Gateway, тому цей інструмент може бути використаний для міграції як VirtualService, так і Gateway ресурсів.
{{< /tip >}}

### Приклад: Маршрутизація на основі заголовків {#example-header-based-routing}

Наступний `VirtualService` маршрутизує запити з `end-user: jason` на `reviews` версію 2, а всі інші запити на версію 1, використовуючи підмножини:

{{< text syntax=yaml snip_id=none >}}
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: reviews
spec:
  hosts:
  - reviews
  http:
  - match:
    - headers:
        end-user:
          exact: jason
    route:
    - destination:
        host: reviews
        subset: v2
  - route:
    - destination:
        host: reviews
        subset: v1
{{< /text >}}

Оскільки `HTTPRoute` не підтримує підмножини DestinationRule, ви маєте спочатку створити версійно-специфічні Services:

{{< text syntax=yaml snip_id=none >}}
apiVersion: v1
kind: Service
metadata:
  name: reviews-v1
  namespace: bookinfo
spec:
  selector:
    app: reviews
    version: v1
  ports:
  - port: 9080
    name: http
---
apiVersion: v1
kind: Service
metadata:
  name: reviews-v2
  namespace: bookinfo
spec:
  selector:
    app: reviews
    version: v2
  ports:
  - port: 9080
    name: http
{{< /text >}}

Потім замініть `VirtualService` на `HTTPRoute`, що привʼязується до `reviews` Service безпосередньо (використовуючи `kind: Service` як `parentRef`). Це правильна модель привʼязки для режиму ambient — waypoint використовує Service як анкер маршрутизації:

{{< text syntax=yaml snip_id=none >}}
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: reviews
  namespace: bookinfo
spec:
  parentRefs:
  - group: ""
    kind: Service
    name: reviews
    port: 9080
  rules:
  - matches:
    - headers:
      - name: end-user
        value: jason
    backendRefs:
    - name: reviews-v2
      port: 9080
  - backendRefs:
    - name: reviews-v1
      port: 9080
{{< /text >}}

Для повного довідника з можливостей `HTTPRoute`, див. [документацію з керування трафіком](/docs/tasks/traffic-management/).

## Міграція AuthorizationPolicy для правил L7 {#migrate-authorizationpolicy-for-l7-rules}

У режимі sidecar, ресурси `AuthorizationPolicy` використовують `selector` для цілеспрямування на podʼи безпосередньо. У режимі ambient, політики авторизації L7 мають бути застосовані waypoint проксі і тому мають використовувати `targetRefs` для цілеспрямування на батьківський `Service` waypoint або сам `Gateway`.

### Політики L4 (змін не потрібно) {#l4-policies-no-change-required}

L4 ресурси `AuthorizationPolicy`, що відповідають лише на принципали джерела, простори імен або IP діапазони, працюють в режимі ambient без модифікації. Вони застосовуються ztunnel.

{{< text syntax=yaml snip_id=none >}}
# Ця політика L4 не вимагає змін для режиму ambient
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: allow-frontend
  namespace: bookinfo
spec:
  selector:
    matchLabels:
      app: reviews
  action: ALLOW
  rules:
  - from:
    - source:
        principals: ["cluster.local/ns/bookinfo/sa/productpage"]
{{< /text >}}

### Політики L7 {#l7-policies}

{{< warning >}}
Міграція L7 політик включає короткий проміжок без застосування. Старі селектор-базовані політики мають бути видалені перед або при перезапуску podʼа, а нові waypoint-базовані політики набирають чинності негайно після створення. Між цими двома операціями правила L7 не застосовуються. Якщо безперервне застосування політик L7 обовʼязкове, плануйте технічне вікно. Ця прогалина є відомим обмеженням і відстежується для покращення в майбутніх релізах.
{{< /warning >}}

Політики, які фільтруються за методами HTTP, шляхами або заголовками, або які використовують `action: CUSTOM` чи `action: AUDIT`, повинні бути спрямовані на проксі-сервер Waypoint. Замініть `selector` на `targetRefs`, що вказують на `Service`, який захищає Waypoint, або на сам ресурс `Gateway` Waypoint:

{{< text syntax=yaml snip_id=none >}}
# До: sidecar-стиль (на основі селектора)
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: allow-get-reviews
  namespace: bookinfo
spec:
  selector:
    matchLabels:
      app: reviews
  action: ALLOW
  rules:
  - to:
    - operation:
        methods: ["GET"]
{{< /text >}}

{{< text syntax=yaml snip_id=none >}}
# Після: ambient-стиль (targetRefs до Service)
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: allow-get-reviews
  namespace: bookinfo
spec:
  targetRefs:
  - kind: Service
    group: ""
    name: reviews
  action: ALLOW
  rules:
  - to:
    - operation:
        methods: ["GET"]
{{< /text >}}

Крім того, ви можете безпосередньо вказати на ресурс waypoint `Gateway`. У цьому випадку політика застосовуватиметься до всього трафіку, що обробляється цим waypoint, незалежно від Service призначення:

{{< text syntax=yaml snip_id=none >}}
# Після: ambient-стиль (targetRefs до waypoint Gateway)
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: allow-get-reviews
  namespace: bookinfo
spec:
  targetRefs:
  - kind: Gateway
    group: gateway.networking.k8s.io
    name: waypoint
  action: ALLOW
  rules:
  - to:
    - operation:
        methods: ["GET"]
{{< /text >}}

Спрямування на `Service` є більш точним варіантом і рекомендується, коли політика має застосовуватися до окремого сервісу. Спрямування на `Gateway` корисне, коли політика має застосовуватися до всіх сервісів у просторі імен.

## Запобігання оминання waypoint {#prevent-waypoint-bypass}

Коли waypoint використовується, переконайтеся, що робочі навантаження не можуть бути досягнуті шляхом його оминання. Використовуйте робоче навантаження `selector` DENY політику, що застосовується **ztunnel** (на pod призначення). Оскільки ця політика перевіряє лише принципала джерела (атрибут L4), ztunnel може застосувати її коректно.

{{< warning >}}
Не використовуйте `targetRefs` для цієї політики. Політика DENY на основі `targetRefs` застосовується waypoint, який бачить ідентифікатор вихідного клієнта, а не власний ідентифікатор waypoint. Це призведе до того, що waypoint відхилятиме весь трафік клієнта ще до того, як буде виконана політика ALLOW.
{{< /warning >}}

### Визначте, коли застосувати запобігання оминання {#decide-when-to-apply-bypass-prevention}

Під час поетапної міграції деякі робочі навантаження джерела можуть все ще перебувати в режимі sidecar. Робочі навантаження в режимі sidecar оминають waypoint і підключаються безпосередньо до ztunnel у пункті призначення, тому ztunnel сприймає ідентифікатор sidecar як принципал джерела, а не ідентифікатор waypoint. Політика DENY, що передбачає використання виключно waypoint, відхилить їхній трафік.

Оберіть один з наступних варіантів перед застосуванням політики:

**Варіант 1: Відкладіть запобігання оминання, доки всі джерела не будуть мігровані.** Не застосовуйте DENY політику, доки кожне робоче навантаження, яке викликає цей сервіс, не перейде в режим ambient. Це простіший підхід, коли ви контролюєте всіх викликачів.

**Варіант 2: Дозвольте трафік як від waypoint, так і від sidecar принципалів.** Застосуйте політику негайно, але додайте службові облікові записи решти робочих навантажень-sidecar до списку винятків `notPrincipals` разом із waypoint. Вилучайте кожен принципал sidecar зі списку по мірі його міграції. Коли всі викликачі перейдуть у режим ambient, у списку має залишитися лише принципал waypoint.

### Застосуйте політику запобігання омиання {#apply-the-bypass-prevention-policy}

Знайдіть службовий обліковий запис, що використовується вашим waypoint:

{{< text syntax=bash snip_id=none >}}
$ kubectl get pod -n <namespace> -l gateway.istio.io/managed=istio.io-mesh-controller \
    -o jsonpath='{.items[0].spec.serviceAccountName}'
{{< /text >}}

Для Варіанту 1, застосуйте політику лише після міграції всіх викликачів:

{{< text syntax=yaml snip_id=none >}}
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: deny-waypoint-bypass
  namespace: bookinfo
spec:
  selector:
    matchLabels:
      app: reviews
  action: DENY
  rules:
  - from:
    - source:
        notPrincipals:
        - "cluster.local/ns/bookinfo/sa/waypoint"
{{< /text >}}

Для Варіанту 2, включіть принципалів sidecar у список винятків під час міграції:

{{< text syntax=yaml snip_id=none >}}
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: deny-waypoint-bypass
  namespace: bookinfo
spec:
  selector:
    matchLabels:
      app: reviews
  action: DENY
  rules:
  - from:
    - source:
        notPrincipals:
        - "cluster.local/ns/bookinfo/sa/waypoint"
        - "cluster.local/ns/bookinfo/sa/productpage"
{{< /text >}}

{{< warning >}}
Зберігайте ваші поточні sidecar ресурси `AuthorizationPolicy` активними до перезапуску podʼів без sidecars. Проте, **видаліть їх негайно після перезапуску podʼа** — не чекайте повної перевірки. Будь-який `AuthorizationPolicy`, що використовує робоче навантаження `selector` з правилами L7 (методи HTTP, шляхи або заголовки), що залишається активним після видалення sidecars, буде підхоплений ztunnel, який не може застосовувати правила L7 і перетворить його на політику `DENY` для всього трафіку до цього робочого навантаження.
{{< /warning >}}

## Наступні кроки {#next-steps}

Перейдіть до [Увімкнення режиму ambient](/docs/ambient/migrate/enable-ambient-mode/) для позначення просторів імен, активації waypoints та видалення інʼєкції sidecar.
