---
title: Примітки до змін Istio 1.25.0
linktitle: 1.25.0
subtitle: Основний реліз
description: Примітки до релізу Istio 1.25.0.
publishdate: 2025-03-03
release: 1.25.0
weight: 10
aliases:
    - /uk/news/announcing-1.25.0
---

## Повідомлення про застарівання {#deprecation-notices}

Ці повідомлення описують функціональність, яку буде вилучено у майбутньому випуску згідно з [політикою застарівання Istio](/docs/releases/feature-stages/#feature-phase-definition). Будь ласка, подумайте про оновлення вашого середовища, щоб вилучити застарілу функціональність.

- **Застаріло** використання `ISTIO_META_DNS_AUTO_ALLOCATE` у `proxyMetadata` на користь новішої версії [DNS auto-allocation](/docs/ops/configuration/traffic-management/dns-proxy#address-auto-allocation). Нові користувачі Istio IP `auto-allocation` повинні перейти на новий контролер, заснований на статусі. Існуючі користувачі можуть продовжувати використовувати стару реалізацію.
  ([Issue #53596](https://github.com/istio/istio/issues/53596))

- **Застаріло** `traffic.sidecar.istio.io/kubevirtInterfaces`, використовуйте натомість `istio.io/reroute-virtual-interfaces`.
  ([Issue #49829](https://github.com/istio/istio/issues/49829))

## Керування трафіком {#traffic-management}

- **Зміни**. Стандартне значення `cni.ambient.dnsCapture` тепер `true`. Воно стандартно вмикає проксіювання DNS для робочих навантажень у середовищі ambient mesh, покращуючи безпеку, продуктивність і надаючи низку можливостей. Цей параметр можна вимкнути явно або за допомогою `compatibilityVersion=1.24`. Примітка: DNS буде увімкнено лише для нових подів. Щоб увімкнути цю функцію для наявних подів, їх слід перезапустити вручну або увімкнути функцію узгодження iptables за допомогою `--set cni.ambient.reconcileIptablesOnStartup=true`.

- **Зміни**. Стандартне значення параметра `PILOT_ENABLE_IP_AUTOALLOCATE` тепер `true`. Це увімкне нову ітерацію [автоматичного розподілу IP-адрес](/docs/ops/configuration/traffic-management/dns-proxy/#address-auto-allocation), виправлено давні проблеми з нестабільністю розподілу, підтримкою ambient та покращено видимість. Обʼєкти `ServiceEntry` без встановленої `spec.address` тепер матимуть нове поле `status.addresses`, яке буде встановлено автоматично. Зауваження: ці дані не буде використано, якщо проксі-сервери не налаштовано на проксіювання DNS, які за стандартно залишаються вимкненими.

- **Оновлено** функцію `PILOT_SEND_UNHEALTHY_ENDPOINTS` (яка стандартно вимкнена), щоб не включати  точки доступу, що завершують роботу. Це гарантує, що сервіс не вважатиметься несправним під час зменшення масштабу або подій розгортання.

- **Оновлений** алгоритм проксіювання DNS для випадкового вибору висхідного потоку для пересилання DNS-запитів.
  ([Issue #53414](https://github.com/istio/istio/issues/53414))

- **Додано** нову змінну оточення istiod `PILOT_DNS_JITTER_DURATION`, яка встановлює джиттер для періодичної резолюції DNS.
  Дивіться `dns_jitter` в `https://www.envoyproxy.io/docs/envoy/latest/api-v3/config/cluster/v3/cluster.proto`.
  ([Issue #52877](https://github.com/istio/istio/issues/52877))

- **Додано** `ObservedGeneration` до умов стану ambient. У цьому полі буде показано генерацію обʼєкта, який спостерігався контролером, коли було згенеровано умову.
  ([Issue #53331](https://github.com/istio/istio/issues/53331))

- **Додано** змінну оточення Istiod `PILOT_DNS_CARES_UDP_MAX_QUERIES`, яка керує полем `udp_max_queries` DNS-резольвера Envoy, стандартно Cares DNS. Типове значення дорівнює 100, якщо його не встановлено.
  Докладнішу інформацію наведено у [документації Envoy](https://www.envoyproxy.io/docs/envoy/latest/api-v3/extensions/network/dns_resolver/cares/v3/cares_dns_resolver.proto#envoy-v3-api-field-extensions-network-dns-resolver-cares-v3-caresdnsresolverconfig-udp-max-queries)
  ([Issue #53577](https://github.com/istio/istio/issues/53577))

- **Додано** підтримку узгодження правил in-pod iptables наявних ambient podʼів з попередньою версією при оновленні `istio-cni`. Функцію можна увімкнути за допомогою `--set cni.ambient.reconcileIptablesOnStartup=true`, і вона буде стандартно увімкнена в наступних випусках.
  ([Issue #1360](https://github.com/istio/istio/issues/1360))

- **Додано** анотацію `istio.io/reroute-virtual-interfaces`, відокремлений комами список віртуальних інтерфейсів, вхідний трафік яких буде безумовно вважатися вихідним. Це дозволяє робочим навантаженням, що використовують віртуальну мережу (KubeVirt, ВМ, docker-in-docker тощо), коректно функціонувати як з sidecar, так і з перехопленням ambient mesh-трафіку.

- **Додано** підтримку додавання стандартних значень політик до istio-waypoint через `GatewayClass`.
  ([Issue #54696](https://github.com/istio/istio/issues/54696))

- **Додано** анотацію `ambient.istio.io/dns-capture`, яка може бути не встановлена, або встановлена у значення `true` чи `false`. Якщо вказано на `Pod`, зареєстрованому у ambient mesh, контролює, чи буде перехоплено DNS-трафік (TCP і UDP на порту 53) і передано у ambient. Ця анотація рівня поду, якщо вона присутня у поді, замінить глобальний параметр `istio-cni` `AMBIENT_DNS_CAPTURE`, який станом на 1.25 стандартно має значення `true`. Зауваження: встановлення цього параметра у значення `false` призведе до порушення роботи деяких функцій Istio, зокрема `ServiceEntries` та egress waypoints, але може бути бажаним для робочих навантажень, які погано взаємодіють з DNS-проксі.
  ([Issue #49829](https://github.com/istio/istio/issues/49829))

- **Додано** підтримку налаштування мітки `istio.io/ingress-use-waypoint` на рівні namespace.

- **Додано** підтримку збереження оригінального регістру заголовків HTTP/1.x. ([Issue #53680](https://github.com/istio/istio/issues/53680))

- **Додано** підтримку поля `Service.spec.trafficDistribution` та анотації `networking.istio.io/traffic-distribution`, що дозволяє спростити механізм надання трафіку переваги географічно близьким  точкам доступу.
  Зауваження: раніше ця можливість існувала лише для ztunnel, але тепер підтримується у всіх панелях даних.

- **Виправлено** помилку зі змішаним регістром хостів у Gateway та перенаправленні TLS, яка призводила до перенаправлення до застарілого RDS. ([Issue #49638](https://github.com/istio/istio/issues/49638))

- **Виправлено** проблему, коли `HTTPRoute` у `VirtualService` з відповідником, що вказує `sourceLabels`, застосовувався до waypoint.
  ([Issue #51565](https://github.com/istio/istio/issues/51565))

- **Виправлено** проблему, яка полягала у тому, що у разі невдалого отримання образу WASM використовувався фільтр дозволу на всі RBAC-дані. Тепер, якщо `failStrategy` встановлено у `FAIL_CLOSE`, буде використано фільтр DENY-ALL RBAC. ([Issue #53279](https://github.com/istio/istio/issues/53279)), ([Issue #23624](https://github.com/istio/istio/issues/23624))

- **Виправлено**, тепер проксі waypoint proxy враховують довірені домени.

- **Виправлено** проблему, коли обʼєднання `Duration` у `EnvoyFilter` могло призвести до несподіваної модифікації всіх атрибутів, повʼязаних зі слухачами, оскільки всі слухачі мали однаковий тип вказівника (`listener_filters_timeout`).

- **Виправлено** проблему, через яку виникали помилки під час очищення правил iptables, які були умовними.

- **Виправлено** проблему конфігурації, через яку на DNS-трафік (UDP і TCP) тепер впливають такі анотації трафіку, як `traffic.sidecar.istio.io/excludeOutboundIPRanges` і `traffic.sidecar.istio.io/excludeOutboundPorts`. Раніше UDP/DNS трафік однозначно ігнорував ці анотації трафіку, навіть якщо був вказаний порт DNS, через структуру правил. Зміна поведінки фактично відбулася в серії випусків 1.23, але була залишена поза увагою в примітках до випуску 1.23.
  ([Issue #53949](https://github.com/istio/istio/issues/53949))

- **Виправлено** проблему, коли istiod неправильно обробляв `RequestAuthentication` для waypoint проксі з перехресним простором імен. ([Issue #54051](https://github.com/istio/istio/issues/54051))

- **Виправлено** проблему, яка призводила до невдалого розгортання патчів керованого gateway/waypoint під час оновлення до версії 1.24.
  ([Issue #54145](https://github.com/istio/istio/issues/54145))

- **Виправлено** проблему, через яку нестандартні ревізії, що керують шлюзами, не мали міток `istio.io/rev`.
  ([Issue #54280](https://github.com/istio/istio/issues/54280))

- **Виправлено** формулювання повідомлення про стан, коли правила L7 присутні у `AuthorizationPolicy`, яка повʼязана з ztunnel, щоб зробити його більш зрозумілим.
  ([Issue #54334](https://github.com/istio/istio/issues/54334))

- **Виправлено** помилку, коли фільтр дзеркальних запитів неправильно обчислював відсоток.
  ([Issue #54357](https://github.com/istio/istio/issues/54357))

- **Виправлено** проблему, коли використання теґу в мітці `istio.io/rev` на шлюзі призводило до неправильного програмування шлюзу та відсутності статусу.
  ([Issue #54458](https://github.com/istio/istio/issues/54458))

- **Виправлено** проблему, коли неправильне зʼєднання з ztunnel могло призвести до того, що `istio-cni` буде вважати, що у нього немає зʼєднань.
  ([Issue #54544](https://github.com/istio/istio/issues/54544)), ([Issue #53843](https://github.com/istio/istio/issues/53843))

- **Виправлено** надмірні записи до журналу iptables на рівні інформації для перевірки та видалення правил. За необхідності детальне ведення журналу можна увімкнути, переключившись на журнал рівня налагодження.
  ([Issue #54644](https://github.com/istio/istio/issues/54644))

- **Виправлено** проблему, яка призводила до того, що сервіси `ExternalName` не працювали під час використання зовнішнього режиму та DNS-проксінгу.

- **Виправлено** проблему, яка призводила до відхилення конфігурації у разі часткового збігу IP-адрес у декількох сервісах. Наприклад, сервіс з `[IP-A]` і сервіс з `[IP-B, IP-A]`.
  ([Issue #52847](https://github.com/istio/istio/issues/52847))

- **Виправлено** проблему, що призводила до того, що перевірка імені заголовка `VirtualService` відхиляла дійсні імена заголовків.

- **Виправлено** проблему під час оновлення проксі waypoint з Istio 1.23.x до Istio 1.24.x.
  ([Issue #53883](https://github.com/istio/istio/issues/53883))

## Безпека {#security}

- **Додано** можливість `DAC_OVERRIDE` до `istio-cni-node` `DaemonSet`. Це виправляє проблеми під час запуску у середовищах, де певні файли належать користувачам, які не мають права root. Зауваження: до версії Istio 1.24 вузол `istio-cni-node` запускався як `privileged`. У Istio 1.24 це було вилучено, але прибрано деякі необхідні привілеї, які зараз додано назад. Порівняно з Istio 1.23, `istio-cni-node` все ще має менше привілеїв, ніж після цієї зміни.

- **Додано** необмежену анотацію AppArmor до `istio-cni-node` `DaemonSet`, щоб уникнути конфліктів з профілями AppArmor, які блокують певні можливості привілейованих подів. Раніше AppArmor (коли його увімкнено) оминався для `istio-cni-node` `DaemonSet`, оскільки privileged було встановлено у значення true у `SecurityContext`. Ця зміна гарантує, що профіль AppArmor для `istio-cni-node` `DaemonSet` буде встановлено у значення unconfined.

- **Виправлено** проблему, коли ambient політики `PeerAuthentication` були надто суворими.
  ([Issue #53884](https://github.com/istio/istio/issues/53884))

- **Виправлено** можливий стан перегонів у кеші резолюції JWK для політик JWT, який при спрацьовуванні призводив до пропусків кешу та збоїв оновлення ключів підпису при ротації.
  ([Issue #52121](https://github.com/istio/istio/issues/52121))

- **Виправлено** помилку (тільки) в ambient , коли декілька `STRICT` правил mTLS на рівні порту в політиці `PeerAuthentication` фактично призводили до дозвільної політики через неправильну логіку оцінки (`AND` проти `OR`).
  ([Issue #54146](https://github.com/istio/istio/issues/54146))

- **Виправлено** проблему, коли вхідні шлюзи не використовували виявлення WDS для отримання метаданих для ambient пунктів призначення.

## Телеметрія {#telemetry}

- **Додано** підтримку додаткового обміну мітками для телеметрії в режимі sidecar.
  ([Issue #54000](https://github.com/istio/istio/issues/54000))

- **Додано** нову мітку `service.istio.io/workload-name`, яка може бути додана до `Pod` чи `WorkloadEntry` для перевизначення "workload name" в телеметрії.

- **Додано** запасний варіант використання імені `WorkloadGroup` як "workload name" (як повідомляється у телеметрії) для `WorkloadEntry`, створеного `WorkloadGroup`.

- **Виправлено** те, що інтерполяція `$(HOST_IP)` призводить до збоїв istio-proxy, коли трасування Datadog увімкнено на кластерах IPv6.
  ([Issue #54267](https://github.com/istio/istio/issues/54267))

- **Виправлено** проблему, коли нестабільність порядку журналу доступу призводила до розриву зʼєднання.
  ([Issue #54672](https://github.com/istio/istio/issues/54672))

- **Виправлено** проблему, через яку багато панелей на дашбордах Grafana показували **Немає даних**, якщо у Prometheus було налаштовано інтервал отримання даниї більше, ніж `15s`. ([Довідкова інформація](https://grafana.com/blog/2020/09/28/new-in-grafana-7.2-__rate_interval-for-prometheus-rate-queries-that-just-work/) та [використання](/docs/tasks/observability/metrics/using-istio-dashboard/))

- **Вилучено** підтримку OpenCensus.

## Встановлення {#installation}

- **Покращено** Перевизначення значень `platform` та `profile` Helm тепер еквівалентно підтримують глобальні та локальні форми перевизначення, наприклад
    - `--set global.platform=foo`
    - `--set global.profile=bar`
    - `--set platform=foo`
    - `--set profile=bar`

- **Покращено** чарт ztunnel Helm для встановлення назв ресурсів на `.Release.Name` замість жорстко закодованих у ztunnel.

- **Додано** нові повідомлення до умови `WaypointBound` для представлення привʼязки сервісу до проксі waypoint для входу.

- **Додано** повідомлення, коли `istioctl install` не працює у Windows.

- **Додано** под `dnsPolicy` з `ClusterFirstWithHostNet` до `istio-cni`, коли він працює з `hostNetwork=true` (тобто у режимі ambient).

- **Додано** профіль платформи GKE для режиму ambient. Під час встановлення на GKE використовуйте `--set global.platform=gke` (Helm) або `--set values.global.platform=gke` (istioctl) для застосування специфічних для GKE перевизначень значень. Це замінить попереднє автоматичне визначення GKE на основі версії K8S, яке використовувалося у чарті `istio-cni`.

- **Додано** підтримку параметра конфігурації Envoy для пропуску застарілих журналів, стандартно встановлене значення true. Встановлення значення змінної оточення `ENVOY_SKIP_DEPRECATED_LOGS` у false увімкне застарілі журнали.

- **Додано** мітки виключення панелі даних ambient до шлюзів, що стандартно постачаються з Istio, щоб уникнути заплутаної поведінки, якщо ви встановлюєте шлюзи поза `istio-system`.
  ([Issue #54824](https://github.com/istio/istio/issues/54824))

- **Виправлено** проблему, через яку створення запису `ipset` не вдавалося на певних типах вузлів Kubernetes на основі Docker.
  ([Issue #53512](https://github.com/istio/istio/issues/53512))

- **Виправлено** Helm render для коректного застосування анотацій на пілотному `ServiceAccount`.
  ([Issue #51289](https://github.com/istio/istio/issues/51289))

- **Виправлено** проблему, коли `includeInboundPorts: ""` не працював, коли увімкнено `istio-cni`.
  ([Issue #54288](https://github.com/istio/istio/issues/54288))

- **Виправлено** проблему, через яку інсталяція CNI залишала тимчасові файли, коли контейнер неодноразово знищувався під час виконання двійкового копіювання, що могло призвести до заповнення місця на диску.
  ([Issue #54311](https://github.com/istio/istio/issues/54311))

- **Виправлено** проблему в таблиці шлюзів, де `--set platform` працював, але `--set global.platform` не працював.

- **Виправлено** проблему, коли шаблон інʼєкції `gateway` не враховував анотації `kubectl.kubernetes.io/default-logs-container` та `kubectl.kubernetes.io/default-container`.

- **Виправлено** проблему, що призводила до невдачі команди `istio-iptables`, коли у системі присутня не вбудована таблиця.

- **Виправлено** проблему, що перешкоджала налаштуванню поля `PodDisruptionBudget` `maxUnavailable`.
  ([Issue #54087](https://github.com/istio/istio/issues/54087))

- **Виправлено** проблему, коли помилки конфігурації інʼєкції замовчувалися (тобто реєструвалися і не поверталися), коли інжектор для sidecar не міг обробити конфігурацію sidecar. Ця зміна тепер поширюватиме помилку користувачеві замість того, щоб продовжувати обробляти несправну конфігурацію.
  ([Issue #53357](https://github.com/istio/istio/issues/53357))

## istioctl

- **Покращено** вивід `istioctl proxy-config secret` для відображення пакунків довіри, наданих Spire.

- **Додано** аліас `-r` для прапорців `--revision` у `istioctl analyze`.

- **Додано** підтримку `AuthorizationPolicies` з дією `CUSTOM` у команді `istioct x authz check`.

- **Додано** підтримку параметра `--network` до команди `istioctl experimental workload group create`.
  ([Issue #54022](https://github.com/istio/istio/issues/54022))

- **Додано** можливість безпечного перезапуску/оновлення агента вузла `istio-cni`, критичного до системи, `DaemonSet` на місці. Це працює, запобігаючи запуску нових подів на вузлі під час перезапуску або оновлення `istio-cni`. Цю можливість стандартно увімкнено і її можна вимкнути, встановивши змінну оточення `AMBIENT_DISABLE_SAFE_UPGRADE=true` у `istio-cni`.
  ([Issue #49009](https://github.com/istio/istio/issues/49009))

- **Додано** зміни для команди `rootca-compare` для обробки випадку, коли у бода є декілька кореневих ЦС.  ([Issue #54545](https://github.com/istio/istio/issues/54545))

- **Додано** підтримку команди `istioctl waypoint delete` для видалення вказаних ревізій waypoints.

- **Додано** підтримку аналізатора для звітування про негативні стани на вибраних ресурсах API Istio та Kubernetes Gateway.
  ([Issue #55055](https://github.com/istio/istio/issues/55055))

- **Покращено** роботу `istioctl proxy-config secret` та `istioctl proxy-config`.
  ([Issue #53931](https://github.com/istio/istio/issues/53931))

- **Виправлено** проблему у команді `rootca-compare`, яка обробляла випадок, коли у поді є декілька кореневих центрів сертифікації.  ([Issue #54545](https://github.com/istio/istio/issues/54545))

- **Виправлено** проблему, що призводила до тупикового завершення команди `istioctl install`, якщо у файлі `IstioOperator` вказано декілька вхідних шлюзів.
  ([Issue #53875](https://github.com/istio/istio/issues/53875))

- **Виправлено** проблему, яка призводила до того, що `istioctl waypoint delete --all` видаляв усі ресурси шлюзу, навіть ті, що не є waypoint.
  ([Issue #54056](https://github.com/istio/istio/issues/54056))

- **Виправлено** команду `istioctl experimental injector list`, яка не виводила надлишкові простори імен для веб-хуків інжекторів.

- **Виправлено** команда `istioctl analyze` повідомляла про помилки `IST0145` при використанні одного хосту з різними портами та декількома шлюзами.
  ([Issue #54643](https://github.com/istio/istio/issues/54643))

- **Виправлено** проблему, коли `istioctl --as` неявно встановлював`--as-group=""`, коли `--as` використовується без `--as-group`.

- **Видалено** прапорці `--recursive` та встановлено рекурсію у true для `istioctl analyze`.

- **Видалено** експериментальний прапорець `--xds-via-agents` з команди `istioctl proxy-status`.
