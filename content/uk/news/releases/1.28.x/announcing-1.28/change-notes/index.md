---
title: Примітки до змін Istio 1.28.0
linktitle: 1.28.0
subtitle: Мінорний випуск
description: Примітки до змін Istio 1.28.0.
publishdate: 2025-11-05
release: 1.28.0
weight: 10
aliases:
    - /news/announcing-1.28.0
---
## Керування трафіком {#traffic-management}

- **Просування** підтримки Istio dual-stack до бета-версії.
  ([Тікет #54127](https://github.com/istio/istio/issues/54127))

- **Оновлено** стандартне значення максимальної кількості прийнятих зʼєднань на подію сокета. Тепер стандартне значення — 1 для вхідних та вихідних слухачів sidecar, які привʼязуються до портів явно. Слухачі без перехоплення iptables отримають кращу продуктивність при високій інтенсивності зʼєднань. Щоб повернутися до старої поведінки, можна задати `MAX_CONNECTIONS_PER_SOCKET_EVENT_LOOP` у нуль.

- **Додано** підтримку атрибутів файлів cookie у механізмі розподілу навантаження з використанням алгоритму «послідовного хешування». Тепер можна вказувати додаткові атрибути, такі як `SameSite`, `Secure` та `HttpOnly`. Це забезпечує більш безпечну та відповідну вимогам обробку файлів cookie у сценаріях розподілу навантаження.
  ([Тікет #56468](https://github.com/istio/istio/issues/56468)), ([Тікет #49870](https://github.com/istio/istio/issues/49870))

- **Додано** змінну середовища `DISABLE_SHADOW_HOST_SUFFIX` для керування поведінкою суфіксів тіньових хостів у політиках дзеркалювання. Якщо встановлено значення `true` (стандартно), суфікси тіньових хостів додаються до імен хостів дзеркальних запитів. Якщо встановлено значення `false`, суфікси тіньових хостів не додаються. Це забезпечує зворотну сумісність для користувачів, які оновлюють систему зі старих версій Istio, де суфікси тіньових хостів додавалися за замовчуванням через профілі сумісності.
  ([Тікет #57530](https://github.com/istio/istio/issues/57530))

- **Додано** підтримку параметра `sectionName` у `BackendTLSPolicy` API Gateway для налаштування TLS для конкретних портів. Це дозволяє вказувати конкретні порти сервісу за назвою, застосовуючи різні налаштування TLS для кожного порту. Наприклад, тепер можна налаштувати параметри TLS лише для порту `https` сервісу, не змінюючи налаштування інших портів.

- **Додано** підтримку `ServiceEntry` як `targetRef` у `BackendTLSPolicy`. Це дозволяє застосовувати налаштування TLS до зовнішніх сервісів, визначених ресурсами `ServiceEntry`.
  ([Тікет #57521](https://github.com/istio/istio/issues/57521))

- **Додано** підтримку native nftables при використанні режиму ambient Istio. Тепер можливо використовувати nftables замість iptables для управління мережевими правилами. Увімкнено задачею `--set values.global.nativeNftables=true` при встановленні Istio.
  ([Тікет #57324](https://github.com/istio/istio/issues/57324))

- **Додано** підтримку wildcard hosts у `ServiceEntry` ресурсах з `DYNAMIC_DNS` розвʼязанням. Підтримується тільки HTTP трафік наразі. Потребує режим ambient та waypoint, налаштований як egress gateway.
  ([Тікет #54540](https://github.com/istio/istio/issues/54540))

- **Додано** підтримку заголовків `X-Forwarded` у `ProxyConfig.ProxyHeaders`.

- **Увімкнено** waypoints для маршрутизації трафіку до віддалених мереж у багатокластерному середовищі ambient.
  ([Тікет #57537](https://github.com/istio/istio/issues/57537))

- **Виправлено** помилку, коли ztunnel неправильно використовував мапу портів `Service` при посиланні на імʼя порту `Service`. ([Тікет #56251](https://github.com/istio/istio/issues/56251))

- **Виправлено** проблему, через яку модуль спостереження за тегами не розцінював стандартну версію як стандартний тег. Це призводило до того, що шлюзи Kubernetes не налаштовувалися.
  ([Тікет #56767](https://github.com/istio/istio/issues/56767))

- **Виправлено** помилку, через яку номер порту `Service` для `InferencePool` починався з 543210 замість 54321. ([Тікет #57472](https://github.com/istio/istio/issues/57472))

- **Виправлено** проблему, через яку панель даних ambient не правильно обробляла `ServiceEntries` із параметром resolution, встановленим на `NONE`. Раніше така конфігурація містила VIP, але не мала точок доступу, що призводило до помилки «no healthy upstream». Тепер цей сценарій налаштовується як сервіс типу `PASSTHROUGH`, що означає, що адреси, на які звертається клієнт, будуть використовуватися як бекенд.
  ([Тікет #57656](https://github.com/istio/istio/issues/57656))

- **Виправлено** проблему, через яку налаштування пулу з’єднань HTTP/2 не застосовувалися під час увімкнення оновлень HTTP/2. ([Тікет #57583](https://github.com/istio/istio/issues/57583))

- **Виправлено** розгортання waypoint так, щоб вони використовували стандартне значення Kubernetes `terminationGracePeriodSeconds` (30 секунд) замість жорстко заданого значення 2 секунди.

- **Додано** підтримку `InferencePool` v1.
  ([Тікет #57219](https://github.com/istio/istio/issues/57219))

- **Видалено** підтримку alpha та release candidate версій `InferencePool`.

## Безпека {#security}

- **Покращено** обробку кореневих сертифікатів коли деякі сертифікати були невалідними. Тепер Istio відкидає невалідні сертифікати, замість відхилення всього пакунку.

- **Додано** поле `caCertCredentialName` у `ServerTLSSettings` для посилання на `Secret`/`ConfigMap`, що містить CA сертифікати для mTLS. Див. [використання](/docs/tasks/traffic-management/ingress/secure-ingress/#key-formats) або [reference](/docs/reference/config/networking/gateway/#ServerTLSSettings-ca_cert_credential_name) для додаткової інформації.
  ([Тікет #43966](https://github.com/istio/istio/issues/43966))

- **Додано** опціональне розгортання `NetworkPolicy` для istiod. Ви можете встановити `global.networkPolicy.enabled=true`, щоб розгорнути стандартну `NetworkPolicy` для istiod та шлюзів. Ми плануємо розширити цю функцію, щоб згодом включити також `NetworkPolicy` для istio-cni та ztunnel.
  ([Тікет #56877](https://github.com/istio/istio/issues/56877))

- **Додано** підтримку налаштування параметра `seccompProfile` у контейнерах `istio-validation` та `istio-proxy` у рамках шаблону інʼєкції sidecar. Тепер користувачі можуть встановити для параметра `seccompProfile.type` значення `RuntimeDefault` для забезпечення кращої відповідності вимогам безпеки.
  ([Тікет #57004](https://github.com/istio/istio/issues/57004))

- **Додано** підтримку `FrontendTLSValidation` (GEP-91) у Gateway API. Див. [використання](/docs/tasks/traffic-management/ingress/secure-ingress/#configure-a-mutual-tls-ingress-gateway) та [reference](https://gateway-api.sigs.k8s.io/reference/spec/#frontendtlsvalidation) для додаткової інформації.
  ([Тікет #43966](https://github.com/istio/istio/issues/43966))

- **Виправлено** конфігурацію фільтра JWT для підтримки заявок користувача, розділених пробілами. Тепер конфігурація фільтра JWT, окрім стандартних заявок («scope» та «permission»), правильно включає визначені користувачем заявки, розділені пробілами. Це гарантує, що фільтр Envoy JWT обробляє ці заявки як рядки, розділені пробілами, що дозволяє правильно перевіряти токени JWT, які містять ці заявки. Щоб налаштувати власні заявки, розділені пробілами, скористайтеся полем `spaceDelimitedClaims` у конфігурації правила JWT у ресурсі `RequestAuthentication`.
  ([Тікет #56873](https://github.com/istio/istio/issues/56873))

- **Видалено** використання MD5 для оптимізації порівнянь. Istio не використовував і не використовує MD5 для криптографічних цілей. Зміна лише для того, щоб код був легким для аудиту та працював у FIPS 140-3 mode.

## Телеметрія {#telemetry}

- **Оновлено** стандартне значення змінної середовища `PILOT_SPAWN_UPSTREAM_SPAN_FOR_GATEWAY` до `true`, що вмикає створення вхідних відрізків для запитів шлюзу.

- **Додано** підтримку аннотацій `sidecar.istio.io/statsFlushInterval` та `sidecar.istio.io/statsEvictionInterval`.

- **Додано** підтримку конфігурації `TraceContextOption` від Zipkin для забезпечення подвійного поширення заголовків B3/W3C. Налаштуйте параметр `trace_context_option: USE_B3_WITH_W3C_PROPAGATION` у розділі `extensionProviders` файлу MeshConfig, щоб переважно витягувати заголовки B3, у разі необхідності використовувати заголовки W3C `traceparent` та вставляти обидва типи заголовків у висхідний потік для кращої сумісності трасування. Див. [документацію Envoy](https://www.envoyproxy.io/docs/envoy/latest/api-v3/config/trace/v3/zipkin.proto#envoy-v3-api-enum-config-trace-v3-zipkinconfig-tracecontextoption), а також [довідку щодо `MeshConfig`](/docs/reference/config/istio.mesh.v1alpha1/) та [інструкції з використання](/docs/tasks/observability/distributed-tracing/).

- **Видалено** підтримку терміну дії метрик. Замість цього використовуйте `StatsEviction` у конфігурації завантаження.

## Розширюваність {#extensibility}

- **Виправлено** проблему, через яку `EnvoyFilter`, що використовував `targetRef` з типом `GatewayClass` та групою `gateway.networking.k8s.io` у кореневому просторі імен, не поширювався належним чином.

## Встановлення {#installation}

- **Оновлено** чарт Istiod Helm для створення ресурсів `EndpointSlice` замість `Endpoints` у разі віддалених інсталяцій Istiod, оскільки `Endpoints` стали застарілими, починаючи з версії Kubernetes 1.33.
  ([Тікет #57037](https://github.com/istio/istio/issues/57037))

- **Оновлено** надбудову Kiali до версії v2.17.0.

- **Додано** можливість повністю очистити resource limits або requests у чартах Helm.

- **Додано** підтримку "persona-based" інсталяцій у чартах Helm на основі scope згенерованого/застосованого ресурсу.
  - Якщо не встановлено `resourceScope`, встановляться всі ресурси. Це та сама поведінка, яку користувач очікує від чартів Istio 1.27.
  - Якщо `resourceScope` встановлено у `namespace`, встановляться тільки namespace-scoped ресурси.
  - Якщо для параметра `resourceScope` встановлено значення `cluster`, будуть встановлені лише ресурси на рівні кластера. Це дозволяє адміністратору Kubernetes керувати ресурсами в кластері, а адміністратору мережі — керувати ресурсами в мережі.
  Для чартів ztunnel, `resourceScope` є полем верхнього рівня. Для всіх інших чартів, це поле знаходиться під `global`.
  ([Тікет #57530](https://github.com/istio/istio/issues/57530))

- **Додано** підтримку змінної середовища `FORCE_IPTABLES_BINARY` для того, щоб замінити автоматичне визначення бекенду iptables та використовувати конкретний бінарний файл. ([Тікет #57827](https://github.com/istio/istio/issues/57827))

- **Додано** `.Values.podLabels` та `.Values.daemonSetLabels` до Helm чарту istio-cni.

- **Додано** параметр конфігурації `service.clusterIP` до чарту Gateway, щоб забезпечити можливість перезапису параметра `spec.clusterIP` ресурсу `Service`. Це може бути корисно у випадках, коли користувач бажає встановити конкретну IP-адресу кластера для сервісу Gateway, замість того щоб покладатися на автоматичне присвоєння.

- **Додано** нове представлення тегів ревізій із використанням сервісів кластерних IP-адрес, що має на меті припинити використання веб-хуків типу «mutating» у режимі ambient. Команда `istioctl tag set <tag> --revision <rev>` та значення Helm `revisionTags` створюватимуть як `MutatingWebhook` з використанням поточних специфікацій, так і `Service`, подібний до `Service` istiod, але з міткою `istio.io/tag` для зберігання відповідності.

- **Додано** параметр `internalTrafficPolicy` для сервісу шлюзу (необхідний, наприклад, під час встановлення ArgoCD із шлюзом, який є внутрішнім застосунком)

- **Виправлено** проблему, через яку PDB, створений під час стандартної інсталяції, блокував звільнення ресурсів вузлів Kubernetes.
  ([Тікет #12602](https://github.com/istio/istio/issues/12602))

- **Оновлено** підтримку Gateway API до v1.4. Це вводить підтримку `BackendTLSPolicy` v1.

## istioctl {#istioctl}

- **Додано** автоматичне визначення базової версії в командах `istioctl`. Якщо параметр `--revision` явно не вказано, автоматично використовуватиметься базова версія (налаштована за допомогою команди `istioctl tag set default`).
  ([Тікет #54518](https://github.com/istio/istio/issues/54518))

- **Додано** підтримку вказівки як `--level` та `--stack-trace-level` для `istioctl admin log`.
  ([Тікет #57007](https://github.com/istio/istio/issues/57007))

- **Додано** підтримку вказівки адміністративного порту проксі для команд `istioctl experimental authz`, `istioctl proxystatus`, `istioctl bug-report` та `istioctl experimental describe` за допомогою прапорця `--proxy-admin-port`.

- **Додано** прапорці для підтримки типів налагодження списку для команди `istioctl experimental internal-debug`.
  ([Тікет #57372](https://github.com/istio/istio/issues/57372))

- **Додано** підтримку відображення інформації про зʼєднання для `istioctl ztunnel-config all`.

- **Виправлено**: аналізатор IST0173 (`DestinationRuleSubsetNotSelectPods`) помилково позначав підмножини `DestinationRule` як такі, що не вибирають жодних подів, коли ці підмножини використовували мітки топології.
