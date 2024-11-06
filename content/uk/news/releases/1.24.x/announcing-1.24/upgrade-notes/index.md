---
title: Примітки до оновлення Istio 1.24
description: Важливі зміни, на які слід звернути увагу при оновленні до Istio 1.24.0.
weight: 20
publishdate: 2024-11-07
---

Коли ви оновлюєтесь з Istio 1.23.x до Istio 1.24.x, будь ласка, зверніть увагу на зміни на цій сторінці. Ці примітки деталізують зміни, які навмисно порушують зворотну сумісність з Istio 1.23.x. Примітки також згадують зміни, які зберігають зворотну сумісність, одночасно вводячи нову поведінку. Зміни включені лише в тому випадку, якщо нова поведінка може бути несподіваною для користувача Istio 1.23.x.

## Оновлені профілі сумісності {#updated-compatibility-profiles}

Для підтримки сумісності зі старішими версіями, Istio 1.24 вводить новий профіль сумісності 1.23 [профіль сумісності](/docs/setup/additional-setup/compatibility-versions/) та оновлює інші профілі для врахування змін в Istio 1.24.

Цей профіль встановлює такі значення:

{{< text yaml >}}
ENABLE_INBOUND_RETRY_POLICY: "false"
EXCLUDE_UNSAFE_503_FROM_DEFAULT_RETRY: "false"
PREFER_DESTINATIONRULE_TLS_FOR_EXTERNAL_SERVICES: "false"
ENABLE_ENHANCED_DESTINATIONRULE_MERGE: "false"
PILOT_UNIFIED_SIDECAR_SCOPE: "false"
ENABLE_DEFERRED_STATS_CREATION: "false"
BYPASS_OVERLOAD_MANAGER_FOR_STATIC_LISTENERS: "false"
{{< /text >}}

Дивіться індивідуальні примітки щодо змін та оновлень для отримання додаткової інформації.

## Istio CRD стандартно шаблонізовані та можуть бути встановлені та оновлені через `helm install istio-base` {#istio-crds-are-templated-by-default-and-can-be-installed-and-upgraded-via-helm-install-istio-base}

Це змінює спосіб оновлення CRD. Раніше ми рекомендували:

- Встановлення: `helm install istio-base`
- Оновлення: `kubectl apply -f manifests/charts/base/files/crd-all.gen.yaml` або подібне.
- Видалення: `kubectl get crd -oname | grep --color=never 'istio.io' | xargs kubectl delete`

Ця зміна дозволяє:

- Встановлення: `helm install istio-base`
- Оновлення: `helm upgrade istio-base`
- Видалення: `kubectl get crd -oname | grep --color=never 'istio.io' | xargs kubectl delete`

Раніше це працювало лише за певних умов, і при використанні певних прапорців встановлення могло призводити до генерації CRD, які не можна було оновити через Helm і потребували ручного втручання для виправлення.

Як наслідок цього, мітки на CRD змінено для відповідності іншим ресурсам, встановленим через Helm.

Якщо ви раніше встановлювали або оновлювали CRD за допомогою `kubectl apply`, а не Helm, ви можете продовжити робити це.

Якщо ви раніше встановлювали CRD за допомогою `helm install istio-base` АБО `kubectl apply`, ви можете почати безпечно оновлювати Istio CRD за допомогою `helm upgrade istio-base` з цієї та всіх наступних версій, після того як ви виконаєте нижче вказані команди kubectl для одноразової міграції:

- `kubectl label $(kubectl get crds -l chart=istio -o name && kubectl get crds -l app.kubernetes.io/part-of=istio -o name) "app.kubernetes.io/managed-by=Helm"`
- `kubectl annotate $(kubectl get crds -l chart=istio -o name && kubectl get crds -l app.kubernetes.io/part-of=istio -o name) "meta.helm.sh/release-name=istio-base"` (замініть на фактичну назву релізу `istio-base`)
- `kubectl annotate $(kubectl get crds -l chart=istio -o name && kubectl get crds -l app.kubernetes.io/part-of=istio -o name) "meta.helm.sh/release-namespace=istio-system"` (замініть на фактичний простір імен istio)

Якщо бажано, можна згенерувати застарілі мітки, встановивши `base.enableCRDTemplates=false` під час `helm install base`, але ця опція буде видалена в наступних версіях.

## Чарт `istiod-remote` замінено на профіль `remote` {#istiod-remote-chart-replaced-with-remote-profile}

Встановлення кластерів istio з віддаленою/зовнішньою панеллю управління через Helm ніколи не було офіційно задокументовано або стабільним. Це змінює спосіб встановлення кластерів, які використовують віддалений екземпляр istio, підготовляючи документацію з цього питання.

Чарт `istiod-remote` був обʼєднаний з регулярним чартом `istio-discovery`.

Раніше:

- `helm install istiod-remote istio/istiod-remote`

З цією зміною:

- `helm install istiod istio/istiod --set profile=remote`

Зверніть увагу, що, як зазначено у попередній примітці щодо оновлень, тепер встановлення чарта `istio-base` є обовʼязковим як для локальних, так і для віддалених кластерів.

## Зміни у сфері дії `Sidecar` {#sidecar-scoping-changes}

Під час обробки сервісів Istio має різні стратегії вирішення конфліктів. Історично ці стратегії дещо відрізнялися, коли користувач мав ресурс `Sidecar`, порівняно з тим, коли він його не мав. Це застосовувалося навіть у випадку, якщо ресурс `Sidecar` містив лише `egress: "*/*"`, що повинно було бути тим самим, як не мати його взагалі.

У цій версії поведінка між двома варіантами була уніфікована:

*Багато сервісів, визначених з одним і тим самим ім'ям хоста*

Поведінка раніше, без `Sidecar`: надавати перевагу Kubernetes `Service` (а не `ServiceEntry`), інакше вибрати будь-який випадковий. Поведінка раніше, з `Sidecar`: надавати перевагу сервісу в тій самій простору імен, що і проксі, інакше вибрати будь-який випадковий. Нова поведінка: надавати перевагу сервісу в тій самій простору імен, що і проксі, потім Kubernetes Service (не ServiceEntry), інакше вибрати будь-який випадковий.

*Багато маршрутів API Gateway, визначених для одного сервісу*

Поведінка раніше, без `Sidecar`: надавати перевагу локальному простору імен проксі для дозволу перевизначення споживачами. Поведінка раніше, з `Sidecar`: випадковий порядок. Нова поведінка: надавати перевагу локальному простору імен проксі для дозволу перевизначення споживачами.

Стару поведінку можна зберегти тимчасово, встановивши `PILOT_UNIFIED_SIDECAR_SCOPE=false`.

## Стандартизація атрибутів метаданих учасників {#standardization-of-the-peer-metadata-attributes}

Вирази CEL в API телеметрії повинні використовувати стандартні [атрибути Envoy](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/advanced/attributes) замість власних розширених атрибутів Wasm.

Метадані учасників тепер зберігаються в `filter_state.downstream_peer` та `filter_state.upstream_peer` замість `filter_state["wasm.downstream_peer"]` та `filter_state["wasm.upstream_peer"]`. Метадані вузлів зберігаються в `xds.node` замість `node`. Атрибути Wasm повинні бути повністю кваліфікованими, наприклад, використовуйте `filter_state["wasm.istio_responseClass"]` замість `istio_responseClass`.

Оператор присутності можна використовувати для сумісних виразів у змішаному проксі-сценарії, наприклад, `has(filter_state.downstream_peer) ? filter_state.downstream_peer.namespace : filter_state["wasm.downstream_peer"].namespace`, щоб отримати простір імен учасника.

Метадані учасників використовують кодування багажу з наступними атрибутами полів:

- `namespace`
- `cluster`
- `service`
- `revision`
- `app`
- `version`
- `workload`
- `type` (наприклад, `"deployment"`)
- `name` (наприклад, `"pod-foo-12345"`)
