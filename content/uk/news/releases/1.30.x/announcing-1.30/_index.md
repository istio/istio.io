---
title: Анонс Istio 1.30
linktitle: 1.30.0
subtitle: Основний випуск Istio 1.30
description: Оголошення про випуск Istio 1.30.
publishdate: 2026-05-18
release: 1.30.0
aliases:
    - /news/announcing-1.30
    - /news/announcing-1.30.0
---

Ми раді оголосити про випуск Istio 1.30. Дякуємо всім нашим учасникам, тестувальникам, користувачам та ентузіастам за допомогу в публікації версії 1.30.0! Ми хотіли б подякувати менеджерам з випуску цієї версії: **Petr McAllister** з Solo.io, **Jacek Ewertowski** з Red Hat та **Jackson Greer** з Microsoft.

{{< relnote >}}

{{< tip >}}
Istio 1.30.0 офіційно підтримується у версіях Kubernetes від 1.32 до 1.36.
{{< /tip >}}

## Що нового? {#whats-new}

### Agentgateway: експериментальна нова реалізація шлюзу {#agentgateway-experimental-new-gateway-implementation}

Istio 1.30 поставляє експериментальну підтримку [agentgateway](https://agentgateway.dev) як реалізацію Gateway API. Agentgateway — це новий data plane проксі, побудований для трафіку AI агентів та MCP серверів; коли увімкнено, він замінює Envoy на pod шлюзу. У цьому релізі він підключений як єдиний `GatewayClass` (`istio-agentgateway`) і підтримується лише як Gateway API шлюз, не як sidecar чи waypoint. Увімкніть його, встановивши `PILOT_ENABLE_AGENTGATEWAY=true` на istiod. Див. [документацію agentgateway Kubernetes](https://agentgateway.dev/docs/kubernetes/latest/) для деталей встановлення та конфігурації. Ця функція перебуває на стадії раннього доступу. Можливі деякі недоліки; будемо раді отримати ваші відгуки.

### Покращення Gateway API та TLSRoute {#gateway-api-and-tlsroute-improvements}

У цьому випуску додано підтримку термінації [`TLSRoute`](https://gateway-api.sigs.k8s.io/api-types/tlsroute/) та змішаного режиму, підтримку пропускних прослуховувачів TLS на шлюзах типу схід-захід, а також звіти про приєднані `ListenerSets` та маршрути у статусі `Gateway`. У сукупності ці зміни наближають реалізацію API шлюзу Istio до функціональної відповідності специфікації, що входить до основного коду, та покращують експлуатаційну ефективність у сценаріях з багатокористувацькими шлюзами.

### Покращення ambient режиму {#ambient-mode-enhancements}

Декілька ambient функцій потрапили у 1.30:

- **Підтримка CIDR адрес у `ServiceEntry`**. Ресурси `ServiceEntry` тепер можуть використовувати CIDR адреси для точок доступу, вмикаючи ambient маршрутизацію для діапазонів IP без перерахування окремих робочих навантажень.
- **Опціональний синтез XFCC на waypoints**. З анотацією `ambient.istio.io/xfcc-include-client-identity: "true"` на waypoint `Gateway`, waypoint синтезує `x-forwarded-client-cert` з SPIFFE ідентичності вихідного робочого навантаження, наданої ztunnel, щоб upstream застосунки могли бачити початкового клієнта.
- **Налаштовуваний розмір вікна HBONE** через `PILOT_HBONE_INITIAL_STREAM_WINDOW_SIZE` та `PILOT_HBONE_INITIAL_CONNECTION_WINDOW_SIZE`, корисне для тюнінгу HBONE CONNECT кластерів для high-throughput ambient робочих навантажень.
- **Метрики Tokio runtime у ztunnel** для чіткішої видимості ресурсів в кожному екземплярі.
- **Новий [посібник міграції sidecar-to-ambient](/docs/ambient/migrate/)**. Покроковий посібник для міграції поточної, заснованої на sidecar mesh до ambient режиму, що охоплює встановлення ambient компонентів, міграцію політик та per-namespace увімкнення. Міграція розроблена як поступова та реверсивна, sidecar та ambient робочі навантаження можуть співіснувати під час процесу.

### Додавання до управління трафіком {#traffic-management-additions}

- **Анотація розподілу трафіку на рівні namespace**. Сервіси наслідують розподіл трафіку з анотації namespace, коли не встановлено явно на сервісі, зменшуючи per-service boilerplate.
- **Анотація `istio.io/connect-strategy` на `ServiceEntry`** з режимом `RACE_FIRST_TCP_CONNECT`, корисна, коли DNS повертає кілька A записів і клієнт повинен обрати перший ендпоінт, що успішно завершує TCP connect.
- **DNS upstream timeout** тепер налаштовується через `DNS_FORWARD_TIMEOUT`, зі збереженням стандартного поточного значення `5s`.
- **Підтримка failover priority** для DNS кластерів.
- **Кілька CUSTOM провайдерів авторизації на робоче навантаження**, вмикаючи різні схеми автентифікації (OAuth, LDAP, API keys) на різних API шляхах.
- **[`TrafficExtension` API](/blog/2026/traffic-extension-api/)**, єдиний уніфікований API для конфігурування Wasm та Lua розширень на Envoy-базованих sidecar, шлюзах та waypoints, що замінює `WasmPlugin` як основний механізм розширюваності проксі.

### Підтримка Helm v4 {#helm-v4-support}

Istio 1.30 додає підтримку Helm v4 (server-side apply). Давнє питання з володінням полем веб-хука `failurePolicy` під час оновлень також вирішено. Користувачі, що використовують Helm v4, повинні оновлюватися гладко без попередніх обхідних шляхів.

### Безпека {#security}

- **Автентифікація debug точок доступу посилена**. XDS debug точки доступу (`syncz`, `config_dump`) на порту 15010 тепер вимагають автентифікації, коли `ENABLE_DEBUG_ENDPOINT_AUTH=true` (стандартно). Нове налаштування `DEBUG_ENDPOINT_AUTH_ALLOWED_NAMESPACES` дозволяє операторам дозволити конкретні простори імен поза системним. Див. [примітки до оновлення](upgrade-notes/) для деталей кардинальних змін.
- **Прапорець мінімальної версії TLS** для `pilot-discovery` (`--tls-min-version`), що дозволяє операторам підняти планку для control-plane TLS.
- **Стандартний реєстр** для Istio образів тепер `registry.istio.io`. Попередній реєстр залишається доступним, але нові інсталяції типово використовують нове розташування.

### Встановлення та робота {#installation-and-operability}

- **Налаштовувані перевизначення портів** для сервісу network gateway через `networkGatewayPorts` Helm values, плюс валідація шаблону для раннього збою, коли `service.ports` порожній і `networkGateway` не встановлено.
- **Стан статусу `WaypointBound`** на ресурсах `WorkloadEntry`, що звітує, чи кожне робоче навантаження зараз привʼязане до waypoint.
- **Поля `dnsPolicy` та `dnsConfig`** на Helm чарті ztunnel для середовищ з нестандартним DNS.
- **`useAppArmorAnnotation`** у Helm чарті istio-cni, стандартно `true`.
- **`global.enableReaderRBAC`** (стандартно`true`) контролює встановлення reader RBAC.

### Телеметрія {#telemetry}

- Збагачення атрибутів сервісу тепер слідує OpenTelemetry семантичним домовленостям, включаючи підтримку `app.kubernetes.io/name` та `service.istio.io/canonical-name`.
- Нове поле `disableContextPropagation` у Telemetry Tracing API, корисне для середовищ, де Istio не повинен поширювати контекст трасування.
- Ztunnel Grafana dashboard додає панель Resource Usage для активних TCP зʼєднань, відкритих файлових дескрипторів та відкритих сокетів на екземпляр.

### І ще багато іншого {#plus-much-more}

- Вдосконалення **istioctl**, зокрема впровадження параметра `--tls-min-version`, виправлення сортування у вихідних даних про з’єднання, образ istioctl без дистрибутива та вдосконалення команди `ztunnel-config`
- Вдосконалення **CNI**: виправлення kubelet probe для подів AWS EKS у середовищі ambient, що використовують групи безпеки для подів (гілка ENI), обмежене параметром `AMBIENT_ENABLE_AWS_BRANCH_ENI_PROBE` (стандартно увімкнено); перевірка вхідних даних для `excludeInterfaces`; налаштування узгодження
- **Wasm**: налаштовуване обмеження розміру бінарного файлу, налаштовуване обмеження розпакування gzip, захист від SSRF під час завантаження Wasm
- **Multicluster**: підтримка завантаження віддалених ресурсів `Secret` із локального шляху файлової системи

Про це та інше читайте в повних [примітках до релізу](change-notes/).

## Оновлення до 1.30 {#upgrading-to-130}

Ми хотіли б почути вашу думку щодо вашого досвіду оновлення до Istio 1.30. Ви можете надати відгук у каналі `#release-1_30` у нашому [Slack робочому просторі](https://slack.istio.io/).

Хотіли б ви безпосередньо внести свій внесок у Istio? Знайдіть і приєднайтеся до однієї з наших [робочих груп](https://github.com/istio/community/blob/master/WORKING-GROUPS.md) і допоможіть нам стати кращими.
