---
title: Примітки до змін Istio 1.30.0
linktitle: 1.30.0
subtitle: Minor Release
description: Примітки до релізу Istio 1.30.0.
publishdate: 2026-05-18
release: 1.30.0
weight: 10
aliases:
    - /news/announcing-1.30.0
---

## Керування трафіком {#traffic-management}

- **Оновлено** вибір точок доступу для багатомережевих середовищ, щоб використовувати шлюз для мережевих точок доступу, коли локальна мережа проксі не встановлена.

- **Оновлено** вибір простору імен сервісу для sidecar проксі. Під час налаштування sidecar проксі, якщо імʼя хосту існує в кількох просторах імен, Istio тепер надає перевагу сервісам Kubernetes і повертається до найстарішого не-Kubernetes сервісу (наприклад, `ServiceEntry`) за часом створення. Раніше вибирався перший видимий простір імен в алфавітному порядку.

- **Додано** опційний синтез `x-forwarded-client-cert` на waypoint у режимі ambient. Встановлення анотації `ambient.istio.io/xfcc-include-client-identity: "true"` на waypoint `Gateway` (або його `GatewayClass`) змушує waypoint перезаписувати XFCC у пересланих запитах записом, сформованим зі SPIFFE-ідентичності вихідного робочого навантаження, наданої ztunnel, щоб upstream застосунки могли бачити початкового клієнта. Будь-яке вхідне значення XFCC замінюється. Waypoint без анотації не змінюються.
  ([Тікет #54995](https://github.com/istio/istio/issues/54995))

- **Додано** підтримку термінування `TLSRoute` та змішаного режиму.
  ([Тікет #55728](https://github.com/istio/istio/issues/55728))

- **Додано** змінну середовища `PILOT_GATEWAY_TRANSPORT_SOCKET_CONNECT_TIMEOUT` для налаштування тайм-ауту підключення транспортного сокета на слухачах шлюзу. Стандартне значення залишається 15 секунд. Встановіть `0s`, щоб вимкнути тайм-аут для робочих навантажень, які потребують довшого часу TLS-рукопотискання.
  ([Тікет #56320](https://github.com/istio/istio/issues/56320))

- **Додано** можливість стиснення HTTP (`gzip`, `zstd`) до HTTP-сервера pilot-agent.
  ([Тікет #58697](https://github.com/istio/istio/issues/58697))

- **Додано** перевірку вводу для анотації `traffic.sidecar.istio.io/excludeInterfaces`, щоб гарантувати прийняття лише дійсних імен інтерфейсів Linux, запобігаючи інʼєкції параметрів `iptables`.
  ([Тікет #58781](https://github.com/istio/istio/issues/58781))

- **Додано** підтримку завантаження віддалених секретів мультикластера з локального шляху файлової системи, визначеного `PILOT_MULTICLUSTER_KUBECONFIG_PATH`. Коли встановлено, Istiod відстежує змонтовану теку (для ключів `.yaml` або `.yml`) і динамічно оновлює реєстрації віддалених кластерів. Якщо встановлені і `PILOT_MULTICLUSTER_KUBECONFIG_PATH`, і `LOCAL_CLUSTER_SECRET_WATCHER`, пріоритет має `PILOT_MULTICLUSTER_KUBECONFIG_PATH`.
  ([Тікет #58927](https://github.com/istio/istio/issues/58927))

- **Додано** експериментальну підтримку agentgateway в Istio. Конфігурацію agentgateway можна увімкнути через прапорець функції `PILOT_ENABLE_AGENTGATEWAY`. Istio підтримує конфігурацію agentgateway через ресурси Gateway API.
  ([Тікет #59209](https://github.com/istio/istio/issues/59209))

- **Додано** підтримку CIDR-адрес для `ServiceEntry` у режимі оточення. `ServiceEntries` з CIDR-адресами (наприклад, `10.0.0.0/24`) тепер передаються до ztunnel, вмикаючи маршрутизацію за найдовшим префіксом для трафіку, призначеного для діапазонів IP.
  ([Тікет #59797](https://github.com/istio/istio/issues/59797))

- **Додано** можливість налаштовувати початкові розміри вікна потоку та зʼєднання HTTP/2 для upstream кластерів HBONE CONNECT (створених для waypoint та шлюзів схід-захід) через прапорці функцій `PILOT_HBONE_INITIAL_STREAM_WINDOW_SIZE` та `PILOT_HBONE_INITIAL_CONNECTION_WINDOW_SIZE`. Їх можна використовувати для зменшення небажаного буферизування.
  ([Тікет #59961](https://github.com/istio/istio/issues/59961))

- **Додано** анотацію `istio.io/connect-strategy` до `ServiceEntries`, щоб дозволити різну семантику DNS-підключень. Користувачі можуть встановити її на `RACE_FIRST_TCP_CONNECT`, коли DNS-сервери повертають кілька A-записів і клієнт має перевірити кожну точку доступу та обрати першу, яка призводить до успішного TCP-підключення.
  ([Тікет #59083](https://github.com/istio/istio/issues/59083))

- **Додано** підтримку пріоритету відмовостійкості для DNS-кластерів.
  ([Тікет #58674](https://github.com/istio/istio/issues/58674))

- **Додано** налаштовуваний тайм-аут upstream DNS через змінну середовища `DNS_FORWARD_TIMEOUT`. Стандартний тайм-аут залишається 5 секунд. Користувачі можуть збільшити тайм-аут для DNS-серверів з високою затримкою або зменшити його, щоб скоротити затримку, яка впливає на користувачів, коли DNS-сервери не відповідають (швидше переходити до наступного сервера). Встановлюється через `DNS_FORWARD_TIMEOUT=10s` у контейнері `istio-proxy` або в масштабі мережі через `proxyMetadata`.
  ([Тікет #59813](https://github.com/istio/istio/issues/59813))

- **Додано** підтримку TLS passthrough слухачів на шлюзах схід-захід, що дозволяє відкривати не-HBONE порти через Gateway API (наприклад, для маршрутизації трафіку до API-сервера Kubernetes через межі мереж). Для цього потрібно увімкнути `AMBIENT_ENABLE_MULTI_NETWORK`.
  ([Тікет #59223](https://github.com/istio/istio/issues/59223))

- **Додано** анотацію розподілу трафіку на рівні простору імен. Сервіси успадковують розподіл трафіку з анотації простору імен, коли він не встановлений явно на сервісі.
  ([Тікет #58701](https://github.com/istio/istio/issues/58701))

- **Додано** підтримку wildcard `ServiceEntry` з `DYNAMIC_DNS` для sidecar проксі як для `MESH_INTERNAL`, так і для `MESH_EXTERNAL` розташувань. Вмикає L7 HTTP-маршрутизацію (через заголовок Host) та L4 TLS-маршрутизацію (через SNI) зі спостережуваністю для wildcard хостів (наприклад, `*.example.com`) у традиційному sidecar режимі. Зверніть увагу, що можна підробити SNI для TLS-зʼєднань, які відповідають wildcard хосту. Наприклад, клієнт, який підключається до `foo.example.com`, може підключитися через `ServiceEntry` `*.example.com`, маючи SNI, встановлений на `bar.example.com`.
  ([Тікет #58244](https://github.com/istio/istio/issues/58244))

- **Додано** [`TrafficExtension` API](/blog/2026/traffic-extension-api/) до пакета розширень, вмикаючи повноцінну підтримку розширюваності Lua.

- **Увімкнено** слухачі шлюзу з `protocol: TLS` за замовчуванням. Слухачі шлюзу з `protocol: TLS` (використовуються для TLS passthrough через `TLSRoute`) тепер приймаються без необхідності `PILOT_ENABLE_ALPHA_GATEWAY_API=true`, оскільки `TLSRoute` перейшов до GA у Gateway API `v1.5.0`.

- **Виправлено** проблему, яка перешкоджала використанню подів з User Namespaces Kubernetes (`hostUsers: false`) разом з istio-cni. Підтримка обмежена операційними системами з бінарним файлом `nsenter`. ([Тікет #58750](https://github.com/istio/istio/issues/58750))

- **Виправлено** обробку CORS у Gateway API: правильно розбирається заголовок `Origin`, коли використовуються wildcard походження, ігноруються невідповідні preflight запити та застосовується суворіший розбір заголовка `Origin` загалом.
  ([Тікет #59018](https://github.com/istio/istio/issues/59018), [Тікет #59026](https://github.com/istio/istio/issues/59026))

- **Виправлено** проблему, через яку waypoint не могли додати фільтр слухача TLS inspector, коли існували лише TLS-порти, що спричиняло збій SNI-маршрутизації для wildcard ресурсів `ServiceEntry` з `resolution: DYNAMIC_DNS`.
  ([Тікет #59024](https://github.com/istio/istio/issues/59024))

- **Виправлено** обгортання помилок у файловому сховищі конфігурацій для використання дієслова `%w`, вмикаючи належне поширення ланцюжка помилок за допомогою `errors.Is()` та `errors.As()`.
  ([Тікет #59078](https://github.com/istio/istio/issues/59078))

- **Виправлено** `tls.Options[gateway.istio.io/tls-terminate-mode]` у Gateway API, щоб правильно перевизначати TLS-режим після обробки `CACertificateRefs`.
  ([Тікет #59098](https://github.com/istio/istio/issues/59098))

- **Виправлено** розіменування нульового вказівника у валідації `ServiceEntry` для розвʼязання `DYNAMIC_DNS`, яке могло спричинити збій istiod.
  ([Тікет #59171](https://github.com/istio/istio/issues/59171))

- **Виправлено** поведінку агента `cni`, щоб він враховував конфігурацію `excludeNamespaces`, завдяки чому поведінка узгоджена між втулком та агентом.
  ([Тікет #59295](https://github.com/istio/istio/issues/59295))

- **Виправлено** збій istiod, коли `PILOT_ENABLE_AMBIENT=true`, але
  `AMBIENT_ENABLE_MULTI_NETWORK` не встановлено, і існує ресурс `WorkloadEntry` з мережею, відмінною від локального кластера.
  ([Тікет #59321](https://github.com/istio/istio/issues/59321))

- **Виправлено** проблему, яка перешкоджала мультикластерній маршрутизації waypoint з однією мережею (без шлюзу схід-захід). ([Тікет #58133](https://github.com/istio/istio/issues/58133))

- **Виправлено** проблему, через яку `HTTPRoute` без `backendRefs` повертав код стану HTTP 500 замість очікуваного 404. Відповідно до специфікації Gateway API, маршрути без жодних посилань на backend мають повертати 404, тоді як маршрути з посиланнями на backend, які всі мають нульову вагу, мають повертати 500.
  ([Тікет #59356](https://github.com/istio/istio/issues/59356))

- **Виправлено** спробу мультикластерних інсталяцій перевіряти неправильний домен довіри, коли панель управління не має оновленої `ClusterRole` `istio-reader`, що призводило до невдачі читання домену довіри з віддаленого `ConfigMap`. Тепер istiod повертатиметься до використання домену довіри, визначеного в локальній конфігурації мережі, доки не зможе прочитати віддалений.
  ([Тікет #59474](https://github.com/istio/istio/issues/59474))

- **Виправлено** застосування кількох ресурсів `VirtualService` для одного імені хосту до waypoint.
  ([Тікет #59483](https://github.com/istio/istio/issues/59483))

- **Виправлено** помилку, через яку шлюз схід-захід іноді маршрутизував HBONE-зʼєднання до неправильного сервісу через неправильний пул зʼєднань в Envoy.
  ([Тікет #58630](https://github.com/istio/istio/issues/58630))

- **Виправлено** відхилення контролером розгортання шлюзу типу `DaemonSet` під час узгодження.
  ([Тікет #59498](https://github.com/istio/istio/issues/59498))

- **Виправлено** проблему, через яку всі `Gateways` перезапускалися після перезапуску istiod.
  ([Тікет #59709](https://github.com/istio/istio/issues/59709))

- **Виправлено** збої перевірки працездатності kubelet для podів Ambient Mesh у AWS EKS під час використання груп безпеки для podів (branch ENI). istio-cni тепер виявляє podи з branch ENI та додає IP-правила для маршрутизації трафіку перевірки через пару veth замість структури VPC. Ця функція доступна за параметром `AMBIENT_ENABLE_AWS_BRANCH_ENI_PROBE` (стандартно увімкнено).

- **Виправлено** надсилання istiod недосяжних IPv6 точок доступу шлюзу до проксі лише з IPv4 (і навпаки) у багатомережевих мережах з dualstack балансувальниками навантаження шлюзу схід-захід.

- **Виправлено** гонитву, яка спричиняла паніку, коли `HTTPRoutes` додавалися, а потім одразу видалялися. Це могло статися, коли користувач застосовував `HTTPRoute`, а потім видаляв його до того, як контролер встигав його обробити.

- **Виправлено** проблему, яка перешкоджала співіснуванню `HTTPRoute` та `GRPCRoute` на одному імені хосту шлюзу без конфліктів.
  ([Тікет #59222](https://github.com/istio/istio/issues/59222))

- **Виправлено** повернення `GetAllAddressesForProxy` недосяжних адрес сервісів проксі, коли IP-сімейство `DefaultAddress` не збігається з підтримуваним проксі IP-сімейством.

- **Виправлено** поле `to` у `ReferenceGrant` для обробки кількох записів; раніше діяв лише останній запис, що спричиняло неправильний `RefNotPermitted` для посилань, які відповідали ранішому запису.

- **Виправлено** звітування статусу для ресурсів `Gateway` та `ListenerSet` для відповідності специфікації Gateway API `v1.5.0`. Змінює звітування статусу `Gateway`, щоб включати кількість `ListenerSets` у полі `AttachedListenerSets` ресурсу `Gateway`, замість кількості слухачів. Також змінює звітування статусу для `ListenerSets`, щоб звітувати кількість маршрутів, прикріплених до кожного слухача в `ListenerSet`.

- **Виправлено** помилку, через яку стандартний `percent` для `retryBudget` у `DestinationRule` був неправильно встановлений на 0.2% замість запланованих 20%. ([Тікет #59504](https://github.com/istio/istio/issues/59504))

- **Виправлено** помилку, через яку `retryBudget`, встановлений у верхньорівневому `trafficPolicy` `DestinationRule`, мовчки відкидався, коли призначення також мало підмножину з власним `trafficPolicy`. Крім того, `retryBudget`, визначений на рівні підмножини, також ігнорувався.
  ([Тікет #59667](https://github.com/istio/istio/issues/59667))

- **Виправлено** неочищення застарілих `status.addresses`, коли `ServiceEntry` оновлюється так, що він більше не відповідає критеріям автоматичного розподілу IP.
  ([Тікет #58974](https://github.com/istio/istio/issues/58974))

- **Виправлено** гонитву, яка спричиняла періодичні журнали помилок "proxy::h2 ping error: broken pipe".
  ([Тікет #59192](https://github.com/istio/istio/issues/59192)),([Тікет #1346](https://github.com/istio/ztunnel/issues/1346))

## Безпека {#security}

- **Додано** підтримку кількох CUSTOM провайдерів авторизації на робоче навантаження, вмикаючи різні схеми автентифікації (OAuth, LDAP, API keys) для різних API-шляхів.
  ([Тікет #57933](https://github.com/istio/istio/issues/57933)),([Тікет #55142](https://github.com/istio/istio/issues/55142)),([Тікет #34041](https://github.com/istio/istio/issues/34041))

- **Додано** можливість вказувати авторизовані простори імен для debug точок доступу, коли `ENABLE_DEBUG_ENDPOINT_AUTH=true`. Увімкніть, встановивши `DEBUG_ENDPOINT_AUTH_ALLOWED_NAMESPACES` на розділений комами список авторизованих просторів імен. Системний простір імен
  (зазвичай `istio-system`) завжди авторизований.

- **Виправлено** неправильне зіставлення `meshConfig.tlsDefaults.minProtocolVersion` з `tls_minimum_protocol_version` у downstream TLS-контексті.
  ([Тікет #58912](https://github.com/istio/istio/issues/58912))

- **Виправлено** регулярний вираз зіставлення `serviceAccount` у `AuthorizationPolicy`, щоб правильно екранувати імʼя службового облікового запису, дозволяючи коректне зіставлення службових облікових записів зі спеціальними символами в іменах. ([CVE-2026-39350](https://nvd.nist.gov/vuln/detail/CVE-2026-39350))
  ([Тікет #59700](https://github.com/istio/istio/issues/59700))

  **Авторство**: Цю вразливість виявив і повідомив Wernerina (<https://github.com/Wernerina>).

- **Виправлено** проблему, через яку Istiod міг видавати кінцеві сертифікати з часом `NotAfter` після закінчення терміну дії підписуючого сертифіката.
  ([Тікет #59768](https://github.com/istio/istio/issues/59768))

- **Виправлено** обхід авторизації у зіставленні `AuthorizationPolicy` для SPIFFE-ідентичностей та просторів імен. Метасимволи регулярних виразів у таких полях, як `source.principals` (зіставлення за суфіксом) та `source.namespaces`, не були належним чином екрановані у згенерованій конфігурації Envoy, що потенційно дозволяло непередбаченим ідентичностям відповідати правилам політики.
  ([Тікет #59992](https://github.com/istio/istio/issues/59992))

  **Авторство**: Цю вразливість виявив і повідомив Alex (<https://github.com/Alex0Young>).

- **Виправлено** помилку, через яку ротація пакета CA не відбувалася, коли сертифікати зʼявлялися в різному порядку. Під час порівняння враховуються лише стандартні PEM-блоки `CERTIFICATE`; інші типи блоків (наприклад, `TRUSTED CERTIFICATE`) ігноруються, що узгоджується з наявною обробкою пакета CA в Istio.
  ([Тікет #59909](https://github.com/istio/istio/issues/59909))

- **Виправлено** критичну вразливість безпеки, через яку через механізм резервного завантаження JWKS в Istio витікав приватний ключ RSA, дозволяючи зловмисникам підробляти JWT-токени та обходити автентифікацію, коли отримання JWKS не вдається. Деталі див. у  ([Advisory GHSA-v75c-crr9-733c](https://github.com/istio/istio/security/advisories/GHSA-v75c-crr9-733c))

  **Авторство**: Цю вразливість виявив і повідомив 1seal (<https://github.com/1seal>).

- **Виправлено** блокування CIDR для JWKS URI за допомогою спеціальної функції контролю в спеціальному `DialContext`. Функція контролю фільтрує зʼєднання після розвʼязання DNS, але перед встановленням зʼєднання, дозволяючи блокуванню слідувати за перенаправленнями та шляхом виявлення емітента. Це також зберігає функції стандартного `DialContext`, такі як happy eyeballs та `dialSerial` (спроба кожного розвʼязаного IP по порядку). ([CVE-2026-41413](https://nvd.nist.gov/vuln/detail/CVE-2026-41413))

  **Авторство**: Цю вразливість виявили і повідомили KoreaSecurity (<https://github.com/KoreaSecurity>), 1seal (<https://github.com/1seal>) та AKiileX (<https://github.com/AKiileX>).

- **Виправлено** XDS debug ендпоінти (`syncz`, `config_dump`), щоб вони вимагали автентифікації. Раніше вони були доступні без автентифікації на незашифрованому XDS порту 15010. Керується `ENABLE_DEBUG_ENDPOINT_AUTH` (той самий прапорець, що й для HTTP debug точок доступу). ([CVE-2026-31838](https://nvd.nist.gov/vuln/detail/CVE-2026-31838))

  **Авторство**: Цю вразливість виявив і повідомив 1seal (<https://github.com/1seal>).

- **Виправлено** XDS debug ендпоінти (`istio.io/debug/syncz`, `istio.io/debug/config_dump`), які обслуговуються `StatusGen`, щоб застосовувати авторизацію в межах одного простору імен для несистемних викликачів. Раніше автентифіковане робоче навантаження з будь-якого простору імен могло перелічувати проксі та отримувати config dump для робочих навантажень в інших просторах імен.

  **Авторство**: Цю вразливість виявив і повідомив 1seal (<https://github.com/1seal>).

- **Виправлено** потенційний SSRF у завантаженні образів `WasmPlugin` шляхом перевірки URL-адрес realm bearer-токенів.

  **Авторство**: Цю вразливість виявив і повідомив Sergey Kanibor з Luntry (<https://github.com/r0binak>).

- **Виправлено** відсутність `ReadHeaderTimeout` та `IdleTimeout` на HTTPS-сервері веб-хука istiod (порт 15017), узгоджуючи його з наявними тайм-аутами на HTTP-сервері (порт 8080).

- **Виправлено** XDS debug точку доступу для передачі простору імен викликача для належних перевірок авторизації.

## Телеметрія {#telemetry}

- **Додано** підтримку міток `app.kubernetes.io/name` та `service.istio.io/canonical-name` під час заповнення міток метрик `source_app` та `destination_app`. Порядок пріоритету: `app` (для зворотної сумісності), потім `app.kubernetes.io/name`, потім `service.istio.io/canonical-name`. Це дозволяє користувачам, які мають лише мітки `app.kubernetes.io/name`, отримувати належним чином заповнені метрики.
  ([Тікет #58436](https://github.com/istio/istio/issues/58436))

- **Додано** поле `disableContextPropagation` до Telemetry Tracing API, що дозволяє користувачам вимикати поширення заголовків контексту трасування (наприклад, `X-B3-*`, `traceparent`) незалежно від звітування span. Це корисно для запобігання витоку контексту трасування на вихідних шлюзах, зберігаючи внутрішню спостережуваність.
  ([Тікет #58871](https://github.com/istio/istio/issues/58871))

- **Додано** підтримку збагачення атрибутів сервісу, узгодженого з семантичними конвенціями OpenTelemetry, для span трасування. Коли `serviceAttributeEnrichment: OTEL_SEMANTIC_CONVENTIONS` встановлено на `OpenTelemetryTracingProvider` у `MeshConfig`, `service.name` обчислюється відповідно до ланцюжка резервних варіантів специфікації атрибутів сервісів OTel K8s. Крім того, `service.namespace`, `service.version` та `service.instance.id` впроваджуються як `OTEL_RESOURCE_ATTRIBUTES` на sidecar під час інʼєкції, а детектор ресурсів Environment автоматично вмикається, щоб Envoy підхоплював ці атрибути під час запуску.
  ([Тікет #55026](https://github.com/istio/istio/issues/55026))

- **Додано** панель Resource Usage до дашборда Ztunnel Grafana, що відображає активні TCP-зʼєднання, відкриті файлові дескриптори та відкриті сокети на екземпляр.

- **Виправлено** проблему, через яку виявлення метаданих peer на основі baggage заважало TLS або PROXY політикам трафіку. Як короткострокове виправлення ми вимикаємо виявлення метаданих на основі baggage для маршрутів з налаштованими TLS або PROXY політиками трафіку, що може призвести до неповної телеметрії в мультикластерних розгортаннях. Ми працюємо над усуненням цього обмеження в майбутніх релізах.
  ([Тікет #59117](https://github.com/istio/istio/issues/59117))

## Розширюваність {#extensibility}

- **Додано** підтримку налаштування ліміту розміру бінарного файлу Wasm через змінну середовища `ISTIO_WASM_MAX_BINARY_SIZE_BYTES`.
  ([Тікет #59322](https://github.com/istio/istio/issues/59322))

- **Виправлено** відсутність ліміту розміру для розпакованих gzip WASM-бінарних файлів, отриманих через HTTP, що узгоджується з лімітами, які вже застосовуються до інших шляхів отримання.

## Встановлення {#installation}

- **Додано** значення `useAppArmorAnnotation` до Helm чарту istio-cni. Стандартно `true`. Коли воно `true`, профіль appArmor встановлюється за допомогою анотації `container.apparmor.security.beta.kubernetes.io` (застаріло в Kubernetes 1.30). Інакше використовується поле `appArmorProfile` у `securityContext`.
  ([Тікет #54721](https://github.com/istio/istio/issues/54721))

- **Додано** `values.global.enableReaderRBAC` (стандартно: `true`) для керування встановленням `istio-reader-service-account` та повʼязаних з ним `ClusterRole`/`ClusterRoleBinding` `istio-reader` для мультикластерних робочих процесів з віддаленими секретами. Встановіть його на `false`, щоб вимкнути встановлення цих ресурсів. Під час встановлення з Helm встановіть `global.enableReaderRBAC=false` на обох чартах base та istiod, оскільки `ServiceAccount` рендериться чартом base, тоді як повʼязані `ClusterRole`/`ClusterRoleBinding` рендеряться чартом `istiod`.
  ([Тікет #56326](https://github.com/istio/istio/issues/56326))

- **Додано** підтримку Helm v4 (server-side apply). Виправлено конфлікт володіння полем `failurePolicy` веб-хука, який спричиняв збій `helm upgrade` з SSA.
  ([Тікет #58302](https://github.com/istio/istio/issues/58302)),([Тікет #59367](https://github.com/istio/istio/issues/59367))

- **Додано** налаштовувані перевизначення портів для сервісу network gateway через значення `networkGatewayPorts`.
  ([Тікет #59072](https://github.com/istio/istio/issues/59072))

- **Додано** валідацію шаблону для раннього збою, коли `service.ports` порожній і `networkGateway` не встановлено.
  ([Тікет #59072](https://github.com/istio/istio/issues/59072))

- **Додано** журналювання попереджень та помилок аналізу конфігурацій у журналах istiod для всіх типів ресурсів Istio (`DestinationRule`, `EnvoyFilter`, `Sidecar` тощо), щоб операторам більше не потрібно було перевіряти окремі поля статусу ресурсів, щоб виявляти неправильні конфігурації.
  ([Тікет #59105](https://github.com/istio/istio/issues/59105))

- **Додано** стан статусу `WaypointBound` до ресурсів `WorkloadEntry`, яка звітує, чи робоче навантаження успішно прикріплене до свого waypoint проксі, чи сталася помилка привʼязки.
  ([Тікет #59993](https://github.com/istio/istio/issues/59993))

- **Додано** прапорець `--tls-min-version` до `pilot-discovery` для налаштування мінімальної версії TLS для сервера та веб-хука istiod. Підтримувані значення: `1.2` (стандартно) та `1.3`.
  ([Тікет #58789](https://github.com/istio/istio/issues/58789))

- **Додано** `registry.istio.io` як стандартний реєстр для образів Istio.

- **Додано** поля `dnsPolicy` та `dnsConfig` до Helm чарту ztunnel для спеціальної конфігурації DNS у середовищах з нестандартними вимогами до DNS.

- **Виправлено** права доступу до конфігураційного файлу CNI, щоб стандартно використовувати 0600 замість 0644 для відповідності CIS Kubernetes benchmark `v1.12`. Доступ на читання для групи можна увімкнути, встановивши змінну середовища `values.cni.env.CNI_CONF_GROUP_READ=true` на `DaemonSet` istio-cni-node, що встановлює права 0640.
  ([Тікет #59071](https://github.com/istio/istio/issues/59071))

- **Виправлено** розіменування нульового вказівника, яке виникало під час процесу оновлення в розгортанні з кількома primary.
  ([Тікет #59153](https://github.com/istio/istio/issues/59153))

- **Виправлено** проблему, через яку встановлення лімітів або запитів ресурсів на `null` спричиняло помилки валідації (`cpu request must be less than or equal to cpu limit of 0`). Це впливало на інʼєкцію проксі, генерацію шлюзів та розгортання Helm чартів.
  ([Тікет #58805](https://github.com/istio/istio/issues/58805))

- **Виправлено** відсутність змінної середовища `PILOT_ENABLE_NODE_UNTAINT_CONTROLLERS` у розгортанні `istiod` під час увімкнення контролера untaint.
  ([Тікет #52050](https://github.com/istio/istio/issues/52050))

- **Виправлено** непотрібні узгодження Helm, спричинені `from: []` у вхідних правилах `NetworkPolicy`.

- **Виправлено** конфлікт field manager для `ValidatingWebhookConfiguration` під час `helm upgrade` з server-side apply в інструментах, які враховують `.Release.IsUpgrade` (Helm 4, Flux). Поле `failurePolicy` тепер опускається з шаблону веб-хука під час оновлення, зберігаючи значення, встановлене під час виконання контролером веб-хука. Для інструментів, які використовують `helm template` з SSA, встановіть `base.validationFailurePolicy: Fail`, щоб уникнути конфлікту.

## istioctl {#istioctl}

- **Оновлено** продуктивність команди `istioctl bug-report`.

- **Додано** прапорці `--skip-cluster-dump`, `--skip-analyze`, `--skip-proxy-debug`, `--skip-netstat` та `--skip-coredumps` до команди `istioctl bug-report`, щоб дозволити пропускати дорогі розділи звіту.

- **Виправлено** отримання журналів з підтримкою фільтрації включення та виключення для вибору подів.

- **Додано** прапорець `--tail` для встановлення максимальної кількості рядків журналу, які отримуються на контейнер. Стандартно все ще без обмежень.

- **Оновлено** мінімальну підтримувану версію Kubernetes до `1.32.x`.

- **Додано** валідацію портів у командах `istioctl`, щоб запобігти недійсним значенням поза діапазоном 1-65535.
  ([Тікет #58584](https://github.com/istio/istio/issues/58584))

- **Додано** підтримку `istioctl proxy-status -oyaml/json` для виведення статусу проксі одного простору імен.
  ([Тікет #59377](https://github.com/istio/istio/issues/59377))

- **Додано** попередження `istioctl analyze` (IST0175), коли існують ресурси `RequestAuthentication`, але `BLOCKED_CIDRS_IN_JWKS_URIS` не налаштовано на istiod.
  ([Тікет #59523](https://github.com/istio/istio/issues/59523))

- **Додано** опції виводу JSON та YAML до підкоманди `istioctl proxy-status`.
  ([Тікет #56880](https://github.com/istio/istio/issues/56880))

- **Додано** підтримку фільтрації виводу `istioctl ztunnel-config workload` та `istioctl ztunnel-config connections` за іменем pod робочого навантаження.

- **Виправлено** проблему, через яку `istioctl` помилково повідомляв про помилку для `EnvoyFilter` з операцією `REPLACE` на `VIRTUAL_HOST`.
  ([Тікет #59495](https://github.com/istio/istio/issues/59495))

- **Виправлено** помилку сортування в `istioctl ztunnel-config connections`, яка спричиняла недетерміноване сортування виводу.
  ([Тікет #59775](https://github.com/istio/istio/pull/59775))

- **Виправлено** проблему, через яку JSON та YAML вивід `istioctl ztunnel-config service` не включав поле `canonical` з config dump ztunnel.
  ([Тікет #59962](https://github.com/istio/istio/issues/59962))

- **Виправлено** проблему, через яку JSON та YAML вивід `istioctl ztunnel-config service` не включав `cidrVips` з config dump ztunnel.
  ([Тікет #59962](https://github.com/istio/istio/issues/59962))

- **Виправлено** проблему, через яку distroless контейнери `istioctl` збиралися з неправильним базовим образом.

## Зміни в документації {#documentation-changes}

- **Оновлено** розташування документації Gateway API Inference Extension; тепер вона в розділі архітектури.
  ([Тікет #56948](https://github.com/istio/istio/issues/56948))
