---
title: Використання agentgateway
description: Налаштування agentgateway як вхідного шлюзу та як waypoint у режимі ambient.
weight: 40
owner: istio/wg-networking-maintainers
test: yes
---
{{< boilerplate experimental-feature-warning >}}

[agentgateway](https://agentgateway.dev) — це проксі панелі даних, який можна використовувати як альтернативу Envoy. Він спеціально створений для трафіку AI-агентів і [Model Context Protocol (MCP)](https://modelcontextprotocol.io), а також підтримує маршрутизацію загального призначення на рівні 7. Коли agentgateway увімкнено, Istio може програмувати його замість Envoy для двох ролей в {{< gloss "ambient" >}}ambient мережі{{< /gloss >}}:

* як **вхідний шлюз**, що обробляє трафік північ–південь, який входить у мережу, та
* як проксі {{< gloss >}}waypoint{{< /gloss >}}, що обробляє трафік рівня 7 у напрямку схід-захід для набору робочих навантажень.

Цей посібник пояснює, як працює інтеграція, які API підтримуються та як встановити Istio і налаштувати agentgateway для кожної ролі.

## Як працює інтеграція {#how-the-integration-works}

Istiod налаштовує agentgateway **виключно через ресурси Kubernetes Gateway API**, які він постачає проксі через xDS. Проксі є окремою реалізацією {{< gloss "панель даних" >}}панелі даних{{< /gloss >}} від Envoy: коли `Gateway` вибирає [`GatewayClass`](https://gateway-api.sigs.k8s.io/api-types/gatewayclass/) agentgateway, Istiod створює та керує `Deployment` і `Service` agentgateway для нього, так само, як він керує шлюзами Istio на основі Envoy.

Увімкнення agentgateway реєструє два ресурси `GatewayClass`:

| `GatewayClass` | Контролер | Роль |
| -------------- | ---------- | ---- |
| `istio-agentgateway` | `istio.io/agentgateway-controller` | Вхідний шлюз |
| `istio-agentgateway-waypoint` | `istio.io/agentgateway-waypoint-controller` | Проксі waypoint |

Оскільки панель даних вибирається для кожного `Gateway` через поле `gatewayClassName`, agentgateway і типові шлюзи та waypoint Istio на основі Envoy можуть співіснувати в одному кластері. Ви обираєте agentgateway для конкретного шлюзу або waypoint, просто посилаючись на один із класів вище.

## Підтримувана та непідтримувана конфігурація {#supported-and-unsupported-configuration}

Istio підтримує наступні ресурси [Gateway API](https://gateway-api.sigs.k8s.io/) для agentgateway:

* `Gateway` (з використанням класу `istio-agentgateway` або `istio-agentgateway-waypoint`)
* `HTTPRoute`, `GRPCRoute`, `TCPRoute` і `TLSRoute`
* `InferencePool` з [розширення Gateway API для інференсу](https://gateway-api-inference-extension.sigs.k8s.io/) для маршрутизації до робочих навантажень AI-інференсу

{{< warning >}}
Istio налаштовує agentgateway **лише** через ресурси Gateway API, перелічені вище. Власні API конфігурації Istio — такі як `VirtualService`, `DestinationRule`, `Sidecar`, `AuthorizationPolicy`, `PeerAuthentication`, `RequestAuthentication`, `Telemetry`, `WasmPlugin` та `EnvoyFilter` — **не** застосовуються до проксі agentgateway. Використовуйте Gateway API для вираження маршрутизації та політик.

Власний рідний формат конфігурації та користувацькі ресурси agentgateway також не керуються Istio; Istio програмує проксі виключно через ресурси Gateway API, описані в цьому посібнику.
{{< /warning >}}

## Перед початком {#before-you-begin}

{{< boilerplate gateway-api-install-crds >}}

### Встановлення Istio з увімкненим agentgateway {#install-istio-with-agentgateway-enabled}

Підтримка agentgateway вмикається за прапорцем функції `PILOT_ENABLE_AGENTGATEWAY` на istiod і є стандартно вимкненою. Встановіть Istio з використанням профілю `ambient` з увімкненим прапорцем. Профіль `ambient` є обовʼязковим, щоб `GatewayClass` waypoint також був зареєстрований:

{{< text syntax=bash snip_id=install_istio >}}
$ istioctl install --set profile=ambient --set values.pilot.env.PILOT_ENABLE_AGENTGATEWAY=true -y
{{< /text >}}

{{< tip >}}
Під час встановлення за допомогою Helm встановіть той самий прапорець в чарті `istiod` за допомогою `--set pilot.env.PILOT_ENABLE_AGENTGATEWAY=true`.
{{< /tip >}}

Підтвердьте, що обидва ресурси `GatewayClass` agentgateway зареєстровані:

{{< text syntax=bash snip_id=verify_gateway_classes >}}
$ kubectl get gatewayclass istio-agentgateway istio-agentgateway-waypoint
NAME                          CONTROLLER                                  ACCEPTED   AGE
istio-agentgateway            istio.io/agentgateway-controller            True       30s
istio-agentgateway-waypoint   istio.io/agentgateway-waypoint-controller   True       30s
{{< /text >}}

### Розгортання прикладу застосунку {#deploy-a-sample-application}

Розгорніть приклад застосунку [Bookinfo](/docs/examples/bookinfo/), який використовується в цьому посібнику:

{{< text syntax=bash snip_id=deploy_bookinfo >}}
$ kubectl apply -f @samples/bookinfo/platform/kube/bookinfo.yaml@
{{< /text >}}

## Налаштування agentgateway як вхідного шлюзу {#configure-agentgateway-as-an-ingress-gateway}

Щоб використовувати agentgateway як вхідний шлюз, створіть `Gateway`, який посилається на клас `istio-agentgateway`. Istiod автоматично створює та керує відповідним розгортанням agentgateway.

{{< text syntax=bash snip_id=deploy_ingress_gateway >}}
$ kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: bookinfo-gateway
  annotations:
    networking.istio.io/service-type: ClusterIP
spec:
  gatewayClassName: istio-agentgateway
  listeners:
  - name: http
    port: 80
    protocol: HTTP
    allowedRoutes:
      namespaces:
        from: Same
EOF
{{< /text >}}

Поле `gatewayClassName: istio-agentgateway` — це те, що вибирає панель даних agentgateway замість Envoy. Стандартно Istio створює сервіс `LoadBalancer` для шлюзу; анотація `networking.istio.io/service-type: ClusterIP` натомість запитує сервіс `ClusterIP`, щоб до шлюзу можна було отримати доступ за допомогою `kubectl port-forward` у цьому посібнику.

Прикріпіть `HTTPRoute`, щоб відкрити сервіс `productpage` через шлюз:

{{< text syntax=bash snip_id=deploy_ingress_route >}}
$ kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: bookinfo
spec:
  parentRefs:
  - name: bookinfo-gateway
  rules:
  - matches:
    - path:
        type: Exact
        value: /productpage
    - path:
        type: PathPrefix
        value: /static
    - path:
        type: Exact
        value: /login
    - path:
        type: PathPrefix
        value: /api/v1/products
    backendRefs:
    - name: productpage
      port: 9080
EOF
{{< /text >}}

Підтвердьте, що шлюз створено та запрограмовано. Стовпець `CLASS` показує клас agentgateway:

{{< text syntax=bash snip_id=verify_ingress_gateway >}}
$ kubectl get gateway bookinfo-gateway
NAME               CLASS                ADDRESS                                      PROGRAMMED   AGE
bookinfo-gateway   istio-agentgateway   bookinfo-gateway.default.svc.cluster.local   True         30s
{{< /text >}}

Тепер ви можете отримати доступ до застосунку через вхідний шлюз agentgateway. Перенаправте локальний порт на сервіс шлюзу та відкрийте `http://localhost:8080/productpage` у своєму браузері:

{{< text syntax=bash snip_id=none >}}
$ kubectl port-forward svc/bookinfo-gateway 8080:80
{{< /text >}}

## Налаштування agentgateway як waypoint {#configure-agentgateway-as-a-waypoint}

Проксі waypoint додає обробку рівня 7 для набору робочих навантажень в ambient мережі. Щоб використовувати agentgateway для цієї ролі, розгорніть `Gateway`, який посилається на клас `istio-agentgateway-waypoint`.

Спочатку підтвердьте, що простір імен залучено до ambient панелі даних:

{{< text syntax=bash snip_id=label_ambient >}}
$ kubectl label namespace default istio.io/dataplane-mode=ambient
namespace/default labeled
{{< /text >}}

{{< warning >}}
Підкоманди `istioctl waypoint` (`apply`, `generate`, `list` і `status`) наразі підтримують лише типовий клас `istio-waypoint` на основі Envoy. Щоб розгорнути waypoint agentgateway, застосуйте ресурс `Gateway` безпосередньо, як показано нижче.
{{< /warning >}}

Розгорніть waypoint. Як і всі waypoint, він має визначати єдиного слухача з іменем `mesh` на порту `15008` з використанням протоколу `HBONE`; єдина відмінність від waypoint Envoy — це `gatewayClassName`:

{{< text syntax=bash snip_id=deploy_waypoint >}}
$ kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: agentgateway-waypoint
  labels:
    istio.io/waypoint-for: service
spec:
  gatewayClassName: istio-agentgateway-waypoint
  listeners:
  - name: mesh
    port: 15008
    protocol: HBONE
EOF
{{< /text >}}

Підтвердьте, що waypoint запрограмовано:

{{< text syntax=bash snip_id=verify_waypoint >}}
$ kubectl get gateway agentgateway-waypoint
NAME                    CLASS                         ADDRESS        PROGRAMMED   AGE
agentgateway-waypoint   istio-agentgateway-waypoint   10.96.15.112   True         30s
{{< /text >}}

Залучіть сервіс до використання waypoint, додавши мітку `istio.io/use-waypoint` з іменем waypoint. Наприклад, щоб надсилати трафік, призначений для сервісу `reviews`, через waypoint agentgateway:

{{< text syntax=bash snip_id=enroll_waypoint >}}
$ kubectl label service reviews istio.io/use-waypoint=agentgateway-waypoint
service/reviews labeled
{{< /text >}}

Запити від робочих навантажень в ambient мережі до сервісу `reviews` тепер маршрутизуються через waypoint agentgateway для обробки рівня 7. Щоб дізнатися більше про залучення просторів імен, сервісів і podʼів, а також про те, як waypoint обробляють різні типи трафіку, дивіться [Налаштування проксі waypoint](/docs/ambient/usage/waypoint/).

Щоб застосувати політику маршрутизації рівня 7 на waypoint, прикріпіть маршрут Gateway API до `Service` за допомогою `parentRef`, чий `kind` дорівнює `Service`. Наприклад, наступний `HTTPRoute` надсилає 90% трафіку для сервісу `reviews` до `reviews-v1` і 10% до `reviews-v2`:

{{< text syntax=yaml >}}
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: reviews
spec:
  parentRefs:
  - group: ""
    kind: Service
    name: reviews
    port: 9080
  rules:
  - backendRefs:
    - name: reviews-v1
      port: 9080
      weight: 90
    - name: reviews-v2
      port: 9080
      weight: 10
{{< /text >}}

## Очищення {#cleanup}

Видаліть вхідний шлюз і його маршрут:

{{< text syntax=bash snip_id=cleanup_ingress >}}
$ kubectl delete httproute bookinfo
$ kubectl delete gateway bookinfo-gateway
{{< /text >}}

Видаліть waypoint і відкличте залучення сервісу `reviews`:

{{< text syntax=bash snip_id=cleanup_waypoint >}}
$ kubectl label service reviews istio.io/use-waypoint-
$ kubectl delete gateway agentgateway-waypoint
{{< /text >}}

Видаліть приклад застосунку та мітку ambient:

{{< text syntax=bash snip_id=cleanup_bookinfo >}}
$ kubectl delete -f @samples/bookinfo/platform/kube/bookinfo.yaml@
$ kubectl label namespace default istio.io/dataplane-mode-
{{< /text >}}

Видаліть Istio:

{{< text syntax=bash snip_id=uninstall_istio >}}
$ istioctl uninstall --purge -y
$ kubectl delete namespace istio-system
{{< /text >}}

{{< boilerplate gateway-api-remove-crds >}}
