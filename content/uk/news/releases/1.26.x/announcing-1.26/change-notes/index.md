---
title: Примітки до змін Istio 1.26.0
linktitle: 1.26.0
subtitle: Основний реліз
description: Примітки до релізу Istio 1.26.0.
publishdate: 2025-05-08
release: 1.26.0
weight: 10
aliases:
    - /uk/news/announcing-1.26.0
    - /uk/news/announcing-1.26.x
---

## Керування трафіком {#traffic-management}

* **Покращено** агент CNI більше не потребує параметра `hostNetwork`, що покращує сумісність. Динамічне перемикання на хост-мережу тепер виконується за необхідності. Попередню поведінку можна тимчасово відновити, встановивши поле `ambient.shareHostNetworkNamespace` у чарті `istio-cni`. ([Тікет #54726](https://github.com/istio/istio/issues/54726))

* **Покращено** бінарне визначення iptables для перевірки підтримки базового ядра та надання переваги `nft`, коли доступні як застарілі, так і `nft`, але жоден з них не має існуючих правил.

* **Оновлено** стандартне значення максимальної кількості зʼєднань, що приймаються за одну подію сокета, до 1 для покращення продуктивності. Щоб повернутися до попередньої поведінки, встановіть `MAX_CONNECTIONS_PER_SOCKET_EVENT_LOOP` в нуль.

* **Додано** можливість для `EnvoyFilter` зіставляти `VirtualHost` за доменним іменем.

* **Додано** початкову підтримку експериментальних функцій API Gateway `BackendTLSPolicy` та `XBackendTrafficPolicy`. Стандартно вони вимкнені і потребують встановлення `PILOT_ENABLE_ALPHA_GATEWAY_API=true`.
  ([Тікет #54131](https://github.com/istio/istio/issues/54131)), ([Тікет #54132](https://github.com/istio/istio/issues/54132))

* **Додано** підтримку посилання на `ConfigMap`, на додачу до `Secret`, для `DestinationRule` TLS у режимі `SIMPLE` — корисно, коли потрібен лише сертифікат ЦС.
  ([Тікет #54131](https://github.com/istio/istio/issues/54131)), ([Тікет #54132](https://github.com/istio/istio/issues/54132))

* **Додано** підтримку кастомізації для [Автоматизованого розгортання Gateway API](/docs/tasks/traffic-management/ingress/gateway-api/#automated-deployment). Це стосується як типів Istio `Gateway` (вхід і вихід), так і типів Istio Waypoint `Gateway` (ambient waypoints). Користувачі тепер можуть налаштовувати згенеровані ресурси, такі як `Service`, `Deployment`, `ServiceAccount`, `HorizontalPodAutoscaler` і `PodDisruptionBudget`.

* **Додано** нову змінну оточення `ENABLE_GATEWAY_API_MANUAL_DEPLOYMENT` для `istiod`. Якщо встановлено у значення `false`, вона вимикає автоматичне приєднання ресурсів API Gateway до існуючих розгортань шлюзу. Стандартно це значення `true`, щоб зберегти поточну поведінку.

* **Додано** можливість налаштовувати предикати хостів для повторних спроб за допомогою Retry API (`retry_ignore_previous_hosts`).

* **Додано** підтримку вказівки інтервалів очікування під час повторних спроб.

* **Додано** підтримку використання `TCPRoute` у проксі-waypoint.

* **Виправлено** помилку, коли веб-хук перевірки неправильно повідомляв про попередження, коли `ServiceEntry` налаштовував `workloadSelector` з роздільною здатністю DNS.
  ([Тікет #50164](https://github.com/istio/istio/issues/50164))

* **Виправлено** проблему, коли FQDN не працювали у `WorkloadEntry` з використанням режиму ambient.

* **Виправлено** випадок, коли `ReferenceGrants` не працювали, коли mTLS було увімкнено на слухачі шлюзу.
  ([Тікет #55623](https://github.com/istio/istio/issues/55623))

* **Виправлено** проблему, коли Istio не міг коректно отримати `allowedRoutes` для waypoint у пісочниці.
  ([Тікет #56010](https://github.com/istio/istio/issues/56010))

* **Виправлено** ваду, через яку витікали точки доступу `ServiceEntry` під час виселення podʼа.
  ([Тікет #54997](https://github.com/istio/istio/issues/54997))

* **Виправлено** проблему, через яку адреса слухача дублювалася для двостекових сервісів з пріоритетом IPv6.  ([Тікет #56151](https://github.com/istio/istio/issues/56151))

## Безпека {#security}

* **Додано** експериментальну підтримку v1alpha1 API `ClusterTrustBundle`. Її можна увімкнути, встановивши `values.pilot.env.ENABLE_CLUSTER_TRUST_BUNDLE_API=true`. Переконайтеся, що у вашому кластері увімкнено відповідні функціональні можливості; див. [KEP-3257](https://github.com/kubernetes/enhancements/tree/master/keps/sig-auth/3257-cluster-trust-bundles) для отримання детальної інформації.
  ([Тікет #43986](https://github.com/istio/istio/issues/43986))

## Телеметрія {#telemetry}

* **Додано** підтримку поля `omit_empty_values` у провайдері `EnvoyFileAccessLog` через API телеметрії.
  ([Тікет #54930](https://github.com/istio/istio/issues/54930))

* **Додано** змінну оточення `PILOT_SPAWN_UPSTREAM_SPAN_FOR_GATEWAY`, яка розділяє діапазони трасування для серверного та клієнтського шлюзів. Наразі цей параметр стандартно має значення `false`, але у майбутньому він стане стандартним.

* Додано попередження щодо використання застарілих постачальників телеметрії Lightstep та OpenCensus.
  ([Тікет #54002](https://github.com/istio/istio/issues/54002))

## Встановлення {#installation}

* **Покращено** процес встановлення на GKE. Якщо встановлено `global.platform=gke`, необхідні ресурси `ResourceQuota` буде розгорнуто автоматично. Під час встановлення за допомогою `istioctl` цей параметр також буде автоматично ввімкнено, якщо буде виявлено GKE. Крім того, тепер належним чином налаштовано `cniBinDir`.

* **Покращено** чарт `ztunnel` Helm, щоб не призначати назви ресурсів до `.Release.Name`, натомість, стандартно, до `ztunnel`. Це відкидає зміну, зроблену у Istio 1.25.

* **Додано** підтримку встановлення параметра `reinvocationPolicy` у веб-хуку revision-tag під час встановлення Istio за допомогою `istioctl` або Helm.

* **Додано** можливість налаштування сервісу `loadBalancerClass` у чарті Gateway Helm.
  ([Тікет #39079](https://github.com/istio/istio/issues/39079))

* **Додано** значення `ConfigMap`, яке зберігає як надані користувачем значення Helm, так і обʼєднані значення після застосування профілів для чарту `istiod`.

* **Додано** підтримку читання значень заголовків зі змінних оточення `istiod`.
  ([Тікет #53408](https://github.com/istio/istio/issues/53408))

* **Додано** конфігураційну `updateStrategy` для чартів `ztunnel` та `istio-cni` Helm.

* **Виправлено** ваду у шаблоні інʼєкції sidecar, яка некоректно видаляла наявні контейнери init, коли було вимкнено перехоплення трафіку та власний sidecar.
  ([Тікет #54562](https://github.com/istio/istio/issues/54562))

* **Виправлено** відсутність міток `topology.istio.io/network` на pod'ах шлюзу при використанні `--set networkGateway`.
  ([Тікет #54909](https://github.com/istio/istio/issues/54909))

* **Виправлено** проблему, коли встановлення `replicaCount=0` у чарті `istio/gateway` Helm призводило до того, що поле `replicas` було пропущено замість того, щоб бути явно встановленим у `0`.
  ([Тікет #55092](https://github.com/istio/istio/issues/55092))

* **Виправлено** проблему, яка призводила до того, що посилання на файлові сертифікати (наприклад, з `DestinationRule` або `Gateway`) не працювали при використанні SPIRE в якості центру сертифікації.

* **Видалено** застарілий прапорець `ENABLE_AUTO_SNI` та повʼязані з ним шляхи коду.

## istioctl

* **Додано** параметр `--locality' до `іstioctl experimental workload group create'.
  ([Тікет #54022](https://github.com/istio/istio/issues/54022))

* **Додано** можливість запуску певних перевірок аналізатором за допомогою команди `istioctl analyze`.

* **Додано** параметр `--tls-server-name` до `istioctl create-remote-secret`, який дозволяє встановити `tls-server-name` у згенерованому kubeconfig. Це гарантує успішне TLS-зʼєднання, коли поле `server` замінено на імʼя хоста проксі-шлюзу.

* **Додано** підтримку поля `envVarFrom` у чарті `istiod`.

* **Виправлено** проблему, коли `istioctl analyze` повідомляв про невідому анотацію `idecar.istio.io/statsCompression`.
  ([Тікет #52082](https://github.com/istio/istio/issues/52082))

* **Виправлено** помилку, яка блокувала встановлення, якщо було пропущено `IstioOperator.components.gateways.ingressGateways.label` або `IstioOperator.components.gateways.ingressGateways.label`.
  ([Тікет #54955](https://github.com/istio/istio/issues/54955))

* **Виправлено** помилку, коли `istioctl` ігнорував поля `tag` у `IstioOperator.components.gateways.ingressGateways` та `egressGateways`.
  ([Тікет #54955](https://github.com/istio/istio/issues/54955))

* **Виправлено** проблему, коли `istioctl waypoint delete` могла видаляти ресурс, який не є шлюзом, коли було вказано імʼя.
  ([Тікет #55235](https://github.com/istio/istio/issues/55235))

* **Виправлено** проблему, коли `istioctl experimental describe` не враховував прапорець `--namespace`.
  ([Тікет #55243](https://github.com/istio/istio/issues/55243))

* **Виправлено** помилку, яка унеможливлювала одночасну генерацію міток `istio.io/waypoint-for` та `istio.io/rev` при створенні проксі-waypoint за допомогою `istioctl`.
  ([Тікет #55437](https://github.com/istio/istio/issues/55437))

* **Виправлено** проблему, коли `istioctl admin log` не міг змінити рівень журналу для `ingress status`.
  ([Тікет #55741](https://github.com/istio/istio/issues/55741))

* **Виправлено** помилку перевірки, коли у конфігурації YAML `istioctl` було встановлено `reconcileIptablesOnStartup: true`.
  ([Тікет #55347](https://github.com/istio/istio/issues/55347))
