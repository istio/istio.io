---
title: Примітки до змін Istio 1.24.0
linktitle: 1.24.0
subtitle: Основний випуск
description: Примітки до змін в Istio 1.24.0.
publishdate: 2024-11-07
release: 1.24.0
weight: 10
aliases:
    - /uk/news/announcing-1.24.0
---

## Режим ambient {#ambient-mode}

- **Додано** підтримку прикріплення політик до `ServiceEntry` для waypointʼів.

- **Додано** нову анотацію, `ambient.istio.io/bypass-inbound-capture"`, яку можна застосувати, щоб змусити ztunnel захоплювати лише вихідний трафік. Це може бути корисним для уникнення зайвого переходу для робочих навантажень, які приймають трафік тільки від клієнтів за межами mesh (наприклад, podʼи з доступом до Інтернету).

- **Додано** нову анотацію, `networking.istio.io/traffic-distribution`, яка дозволяє ztunnel надавати перевагу локальним подам при передачі трафіку. Це працює так само як поле [`spec.trafficDistribution`](https://kubernetes.io/docs/concepts/services-networking/service/#traffic-distribution) у `Service`, але дозволяє використання на старіших версіях Kubernetes (оскільки поле було додано як бета у Kubernetes 1.31). Зазначимо, що waypointʼи автоматично налаштовують цю анотацію.

- **Виправлено** проблему, яка заважала працювати [протоколам з ініціативою від сервера](/docs/ops/deployment/application-requirements/#server-first-protocols) з waypoint'ами.

- **Покращено** журнали Envoy, що містять деталі про збої зʼєднання в ambient mode.

- **Додано** підтримку налаштування `Telemetry` у waypoint proxy.

- **Додано** записування статусу для привʼязки AuthorizationPolicy до waypoint proxy. Форматування статусів наразі **експериментальне** і може змінитися. Політика з кількома `targetRefs` наразі отримує єдиний статус. Як тільки патерн для статусів із кількома посиланнями буде прийнятий у Kubernetes Gateway API, Istio прийме цей стандарт для більш детальної інформації при використанні кількох `targetRefs`.
  ([Issue #52699](https://github.com/istio/istio/issues/52699))

- **Виправлено** проблему, через яку podʼи з `hostNetwork` функціонували неправильно в ambient mode.

- **Покращено** спосіб, яким ztunnel визначає, від імені якого podʼа він діє. Раніше це залежало від IP-адрес, що було ненадійним у деяких сценаріях.

- **Виправлено** проблему, через яку ігнорувалися будь-які `portLevelSettings` у `DestinationRule` у waypoint'ах.
  ([Issue #52532](https://github.com/istio/istio/issues/52532))

- **Виправлено** проблему з використанням політик дзеркалювання з waypointʼами.
  ([Issue #52713](https://github.com/istio/istio/issues/52713))

- **Додано** підтримку правила `connection.sni` у `AuthorizationPolicy`, застосованого до waypoint'а.
  ([Issue #52752](https://github.com/istio/istio/issues/52752))

- **Оновлено** метод перенаправлення, що використовується в Ambient, з `TPROXY` на `REDIRECT`. Для більшості користувачів це не повинно вплинути на роботу, але вирішує деякі проблеми сумісності з `TPROXY`.
  ([Issue #52260](https://github.com/istio/istio/issues/52260)),([Issue #52576](https://github.com/istio/istio/issues/52576))

## Управління трафіком {#traffic-management}

- **Підвищено** підтримку Istio dual-stack до Альфа-версії.
  ([Issue #47998](https://github.com/istio/istio/issues/47998))

- **Додано** параметри `warmup.aggression`, `warmup.duration`, `warmup.minimumPercent` до `DestinationRule` для більш гнучкого контролю поведінки під час розігріву.
  ([Issue #3215](https://github.com/istio/api/issues/3215))

- **Додано** політику повторних спроб для вхідних запитів, яка автоматично скидає запити, які сервіс не обробив. Це можна скасувати, встановивши `ENABLE_INBOUND_RETRY_POLICY` на false.
  ([Issue #51704](https://github.com/istio/istio/issues/51704))

- **Виправлено** стандартну політику повторних спроб, щоб виключити повтори для 503, що потенційно небезпечно для ідемпотентних запитів. Цю поведінку можна тимчасово скасувати, встановивши `EXCLUDE_UNSAFE_503_FROM_DEFAULT_RETRY=false`.
  ([Issue #50506](https://github.com/istio/istio/issues/50506))

- **Оновлено** поведінку XDS-генерації для узгодженості у випадках, коли `Sidecar` конфігуровано, та коли ні. Дивіться примітки до оновлення для отримання додаткової інформації.

- **Покращено** вебхук для валідації Istiod, щоб приймати версії, про які він не знає. Це забезпечує можливість старішим версіям Istio валідувати ресурси, створені новішими CRD.

- **Покращено** підтримку dual-stack сервісів, об’єднуючи кілька IP-адрес в одну єдину точку доступу, замість їх обробки як двох окремих.
  ([Issue #40394](https://github.com/istio/istio/issues/40394))

- **Додано** підтримку відповідності декількох IP-адрес (для dual-stack сервісів) у HTTP-маршруті.

- **Додано** у `VirtualService` підтримку `sourceNamespaces`, які тепер враховуються при фільтрації непотрібної конфігурації.

- **Додано** підтримку обходу менеджера перевантаження для статичних слухачів. Це можна скасувати, встановивши `BYPASS_OVERLOAD_MANAGER_FOR_STATIC_LISTENERS` на false у Deployment агента.
  ([Issue #41859](https://github.com/istio/istio/issues/41859)),([Issue #52663](https://github.com/istio/istio/issues/52663))

- **Додано** нову змінну середовища `ENVOY_DNS_JITTER_DURATION` для istiod зі стандартним значенням `100ms`, яка встановлює джиттер для періодичного DNS-розвʼязування. Дивіться `dns_jitter` у `https://www.envoyproxy.io/docs/envoy/latest/api-v3/config/cluster/v3/cluster.proto`. Це може допомогти зменшити навантаження на  DNS-сервер кластера.
  ([Issue #52877](https://github.com/istio/istio/issues/52877))

- **Додано** підтримку налаштування параметрів сертифікатів під час заповнення XFCC заголовка через нове поле `ProxyConfig`, `proxyHeaders.setCurrentClientCertDetails`.

- **Додано** можливість для користувачів вставляти додаткові пробіли між просторами імен в анотації `networking.istio.io/exportTo`.
  ([Issue #53429](https://github.com/istio/istio/issues/53429))

- **Додано** експериментальну функцію для лінивого створення підмножини статистик Envoy. Це дозволить економити памʼять та обчислювальні ресурси при створенні обʼєктів, що зберігають ці статистики, якщо ці статистики не будуть використані протягом усього часу виконання процесу. Це можна вимкнути, встановивши `ENABLE_DEFERRED_STATS_CREATION` на false у Deployment агента.

- **Виправлено** відповідність кількох IP-сервісів у ServiceEntry. Дивіться примітки до оновлення для отримання додаткової інформації.
  ([Issue #51747](https://github.com/istio/istio/issues/51747)),([Issue #30282](https://github.com/istio/istio/issues/30282))

- **Виправлено** `MeshConfig` `serviceSettings.settings.clusterLocal` для надання переваги більш точним іменам хостів, дозволяючи виключення хостів.

- **Виправлено** `DestinationRules` на одному хості, щоб вони не обʼєднувалися, якщо мають різні значення `exportTo`. Стару поведінку можна тимчасово відновити, встановивши `ENABLE_ENHANCED_DESTINATIONRULE_MERGE=false`.
  ([Issue #52519](https://github.com/istio/istio/issues/52519))

- **Виправлено** проблему, коли IP-адреси, призначені контролером, не відповідали перехопленню DNS для проксі так само, як тимчасові автоматично призначені IP-адреси.
  ([Issue #52609](https://github.com/istio/istio/issues/52609))

- **Виправлено** проблему, через яку waypointʼи ігнорували автоматично призначені IP-адреси для `ServiceEntry` у деяких випадках.
  ([Issue #52746](https://github.com/istio/istio/issues/52746))

- **Виправлено** проблему, коли ланцюг `ISTIO_OUTPUT` у `iptables` не видалявся за допомогою команди `pilot-agent istio-clean-iptables`.
  ([Issue #52835](https://github.com/istio/istio/issues/52835))

- **Виправлено** проблему, коли використання HTTPS у повільних сценаріях запитів, таких як мережі з великими втратами пакетів, могло потенційно призвести до витоку памʼяті в Envoy.
  ([Issue #52850](https://github.com/istio/istio/issues/52850))

- **Виправлено** помилку, коли DNS-проксі містив непідготовлені точки доступу для headless сервісів.

- **Видалено** застарілу мітку `istio.io/gateway-name`, будь ласка, використовуйте натомість `gateway.networking.k8s.io/gateway-name`.

- **Видалено** записування `kubeconfig` у теку CNI net.
  ([Issue #52315](https://github.com/istio/istio/issues/52315))

- **Видалено** `CNI_NET_DIR` з configmap `istio-cni`, оскільки він більше не виконує ніяких функцій.
  ([Issue #52315](https://github.com/istio/istio/issues/52315))

## Телеметрія {#telemetry}

- **Оновлено** словник CEL, що використовується в API телеметрії та розширеннях. Дивіться примітки до оновлення для детальнішої інформації.

- **Додано** нову змінну шаблону (`%SERVICE_NAME%`) для префіксу статистики
  ([Issue #52177](https://github.com/istio/istio/issues/52177))

- **Додано** значення `logAsJson` до Helm-чарту ztunnel
  ([Issue #52631](https://github.com/istio/istio/issues/52631))

- **Додано** конфігурацію теґів статистики для метрик спостереження.
  ([Issue #52731](https://github.com/istio/istio/issues/52731))

- **Додано** підтримку заголовків та конфігурацій тайм-ауту для gRPC-запитів під час експорту трейсів до OpenTelemetry Collector. ([Issue #52873](https://github.com/istio/istio/issues/52873))

- **Додано** підтримку налаштованої точки доступу Zipkin collector через `meshConfig.extensionProviders.zipkin.path`.  ([Issue #53086](https://github.com/istio/istio/issues/53086))

- **Виправлено** Додано порт метрик до podʼів, створених автоматизованими розгортаннями [`Gateway`](/docs/tasks/traffic-management/ingress/gateway-api/#automated-deployment).

- **Виправлено** Оновлення `citadel_server_root_cert_expiry_timestamp`, `citadel_server_root_cert_expiry_seconds`, `citadel_server_cert_chain_expiry_timestamp` та `citadel_server_cert_chain_expiry_seconds` при завантаженні нових сертифікатів.

- **Додано** параметр `SECRET_GRACE_PERIOD_RATIO_JITTER` зі стандартним значенням `0.01` для введення випадкового зсуву в `SECRET_GRACE_PERIOD_RATIO`. Без цієї конфігурації проксі, розгорнуті одночасно, запитуватимуть оновлення сертифікатів одночасно, що може призвести до надмірного навантаження на сервер CA. Нова типова поведінка передбачає оновлення сертифікатів кожні 12 годин, що коригується на +/- приблизно 15 хвилин завдяки цьому значенню.
  ([Issue #52102](https://github.com/istio/istio/issues/52102))

## Встановлення {#installation}

- **Оновлено** значення `securityContext.privileged` для istio-cni на false на користь специфічних для функцій дозволів. istio-cni залишається ["привілейованим" контейнером відповідно до стандартів безпеки Kubernetes для Podʼів](https://kubernetes.io/docs/concepts/security/pod-security-standards/#privileged), оскільки навіть без цього прапорця він має привілейовані можливості, зокрема `CAP_SYS_ADMIN`.
  ([Issue #52558](https://github.com/istio/istio/issues/52558))

- **Покращено** ресурс Waypoint тепер можна налаштувати за допомогою `global.waypoint.resources`.
  ([Issue #51496](https://github.com/istio/istio/issues/51496))

- **Покращено** `affinity` для podʼів Waypoint тепер налаштовується через `waypoint.affinity`.
  ([Issue #52883](https://github.com/istio/istio/issues/52883))

- **Покращено** параметри `topologySpreadConstraints` для podʼів Waypoint тепер налаштовуються через `global.waypoint.topologySpreadConstraints`.
  ([Issue #52901](https://github.com/istio/istio/issues/52901))

- **Покращено** параметри `tolerations` для podʼів Waypoint тепер налаштовуються через `global.waypoint.tolerations`.
  ([Issue #52901](https://github.com/istio/istio/issues/52901))

- **Покращено** параметри `nodeSelector` для podʼів Waypoint тепер налаштовуються через `global.waypoint.nodeSelector`.
  ([Issue #52901](https://github.com/istio/istio/issues/52901))

- **Покращено** обсяг памʼяті DaemonSet `istio-cni-node`. У багатьох випадках це дозволяє зменшити споживання памʼяті до 80%.
  ([Issue #53493](https://github.com/istio/istio/issues/53493))

- **Оновлено** зразок застосунку Kiali до [версії v2.0](https://medium.com/kialiproject/kiali-2-0-for-istio-2087810f337e).

- **Оновлено** всі компоненти Istio для читання `v1` CRD, де це можливо. Це не має впливати на роботу, якщо кластер не використовує CRD версії Istio 1.21 або старішої (яка не підтримується).

- **Додано** мітки `app.kubernetes.io/name`, `app.kubernetes.io/instance`, `app.kubernetes.io/part-of`, `app.kubernetes.io/version`, `app.kubernetes.io/managed-by`, та `helm.sh/chart` до майже всіх ресурсів.
  ([Issue #52034](https://github.com/istio/istio/issues/52034))

- **Додано** конфігурації для встановлення Helm для конкретних платформ. Приклад:
  `helm install istio-cni --set profile=ambient --set global.platform=k3s`
  `helm install istiod --set profile=ambient --set global.platform=k3s`

  Для списку наразі підтримуваних перевизначень для платформ перегляньте файли `manifests/charts/platform-xxx.yaml`.

- **Видалено** варіанти профілю `openshift`, замінені на перевизначення `global.platform`. Приклад:
`helm install istio-cni --set profile=ambient-openshift` тепер
`helm install istio-cni --set profile=ambient --set global.platform=openshift`

- **Додано** можливість налаштовувати `initContainers` для Istiod.
  ([Issue #53120](https://github.com/istio/istio/issues/53120))

- **Додано** налаштування (`strategy`, `minReadySeconds`, і `terminationGracePeriodSeconds`) для стабілізації шлюзів при великому навантаженні.
  ([Issue #53121](https://github.com/istio/istio/issues/53121))

- **Додано** значення `seLinuxOptions` до Helm-чарту `istio-cni`. На деяких платформах (наприклад, OpenShift) необхідно встановити `seLinuxOptions.type` як `spc_t`, щоб обійти деякі обмеження SELinux, повʼязані з томами `hostPath`. Без цього налаштування podʼи `istio-cni-node` можуть не запускатися.  ([Issue #53558](https://github.com/istio/istio/issues/53558))

- **Додано** підтримку додавання довільних змінних середовища в Helm-чарт `istio-cni`.

- **Додано** нову анотацію `sidecar.istio.io/nativeSidecar` для керування інʼєкцією вбудованого sidecar на рівні podʼів. Ця анотація може бути встановлена як `true` або `false`, щоб увімкнути або вимкнути вбудовану інʼєкцію для podʼа. Вона має вищий пріоритет над глобальною змінною середовища `ENABLE_NATIVE_SIDECARS`.
  ([Issue #53452](https://github.com/istio/istio/issues/53452))

- **Додано** можливість додавати налаштовану анотацію до `MutatingWebhookConfiguration` для теґів ревізій через Helm-чарт.

- **Виправлено** правила `kube-virt-interfaces`, які не видалялися інструментом `istio-clean-iptables`.
  ([Issue #48368](https://github.com/istio/istio/issues/48368))

- **Виправлено** можливість повторного виконання istio-iptables, пропускаючи крок застосування, якщо існуючі правила сумісні.

- **Виправлено** проблему, де деякі рядки статусу втсановлення не завершувалися коректно, що могло спричиняти некоректне відображення при зміні розміру вікон терміналу.
  ([Issue #52525](https://github.com/istio/istio/issues/52525))

- **Виправлено** значення `allowPrivilegeEscalation` на `true` у ztunnel — насправді воно завжди було примусово `true`, але K8S не перевіряє це належним чином: <https://github.com/kubernetes/kubernetes/issues/119568>.

- **Виправлено** видалено некритичні компоненти з `base`-чарту та видалено `pilot.enabled` з чартів `istiod-remote` та `istio-discovery`.

- **Виправлено** стандартне встановлення шаблонних CRD у `base`-чарті. Раніше це працювало лише за певних умов, і при використанні певних прапорців інсталяції могло призводити до CRD, які можна було оновити лише вручну через `kubectl`. Дивіться примітки до оновлення для детальнішої інформації.

- **Застаріло** `Values.base.enableCRDTemplates`. Ця опція тепер стандартно має значення `true` і буде видалена в майбутньому релізі. До того часу, щоб увімкнути попередню поведінку, можна встановити значення `false`.
  ([Issue #43204](https://github.com/istio/istio/issues/43204))

- **Видалено** деякі поля з API значень helm, які не мали ефекту, а в деяких випадках були давно застарілими. Видалені поля: `pilot.configNamespace`, `pilot.configSource`, `pilot.enableProtocolSniffingForOutbound`, `pilot.enableProtocolSniffingForInbound`, `pilot.useMCP`, `global.autoscalingV2API`, `global.configRootNamespace`, `global.defaultConfigVisibilitySettings`, `global.useMCP`, `sidecarInjectorWebhook.objectSelector`, та `sidecarInjectorWebhook.useLegacySelectors`.
  ([Issue #51987](https://github.com/istio/istio/issues/51987))

- **Видалено** невикористовувані значення `istio_cni` з чарту `istiod`, які були позначені як застарілі два релізи тому (#49290).
  ([Issue #52645](https://github.com/istio/istio/issues/52645))

- **Видалено** чарт `istiod-remote` на користь `helm install istio-discovery --set profile=remote`.

- **Видалено** підтримку профілю сумісності `1.20`. Цей профіль налаштовував такі параметри: `ENABLE_EXTERNAL_NAME_ALIAS`, `PERSIST_OLDEST_FIRST_HEURISTIC_FOR_VIRTUAL_SERVICE_HOST_MATCHING`, `VERIFY_CERTIFICATE_AT_CLIENT` та `ENABLE_AUTO_SNI`. Всі ці прапорці, крім `ENABLE_AUTO_SNI`, також були повністю видалені з Istio.

- **Видалено** анотацію `sidecar.istio.io/enableCoreDump`. Зразок налаштування для увімкнення дампів памʼяті тепер доступний у файлі `samples/proxy-coredump`.

- **Видалено** застарілі параметри прапорця `--log_rotate_*`. Користувачам, які бажають використовувати обертання логів, рекомендовано застосовувати зовнішні інструменти для цього.

## istioctl {#istioctl}

- **Додано** автоматичне виявлення різних платформо-залежних несумісностей під час встановлення.

- **Додано** нову команду `istioctl manifest translate` для допомоги у переході з `istioctl install` на `helm`.

- **Додано** новий прапорець `remote-contexts` до команди `istioctl analyze` для вказання контекстів віддалених кластерів під час багатокластерного аналізу.
  ([Issue #51934](https://github.com/istio/istio/issues/51934))

- **Додано** підтримку фільтрації Pod за селектором міток у `istioctl x envoy-stats`.

- **Додано** підтримку фільтрації ресурсів за простором назв у `istioctl experimental injector list`.

- **Додано** підтримку прапорців `--impersonate` у istioctl.
  ([Issue #52285](https://github.com/istio/istio/issues/52285))

- **Виправлено** помилку IST0145 у звіті `istioctl analyze` з підстановочним ім’ям хосту та певним субдоменом.
  ([Issue #52413](https://github.com/istio/istio/issues/52413))

- **Виправлено** `istioctl experimental injector list` тепер не відображає вебхуки, які не стосуються Istio.

- **Видалено** команди `istioctl manifest diff` та `istioctl manifest profile diff`. Користувачі, які хочуть порівняти маніфести, можуть скористатися загальними інструментами порівняння YAML.

- **Видалено** команду `istioctl profile`. Така інформація доступна у документації Istio.

## Зміни в документації {#documentation-changes}

- **Покращено** читабельність документації Istio, перейменувавши зразковий застосунок `sleep` на `curl`.
  ([Issue #15725](https://github.com/istio/istio.io/issues/15725))
