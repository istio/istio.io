---
title: Kubernetes Gateway API
description: Описує, як налаштувати Kubernetes Gateway AP з Istio.
weight: 50
aliases:
    - /docs/tasks/traffic-management/ingress/service-apis/
    - /latest/docs/tasks/traffic-management/ingress/service-apis/
keywords: [traffic-management,ingress, gateway-api]
owner: istio/wg-networking-maintainers
test: yes
---

Окрім власного API для управління трафіком,
{{< boilerplate gateway-api-future >}}
Цей документ описує відмінності між API Istio та Kubernetes і надає простий приклад, який показує, як налаштувати Istio для експонування сервісу за межі кластера службової мережі, використовуючи Gateway API. Зверніть увагу, що ці API є активно еволюціями API Kubernetes [Service](https://kubernetes.io/docs/concepts/services-networking/service/) та [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/), що активно розвиваються.

{{< tip >}}
Багато документів з управління трафіком Istio містять інструкції для використання як Istio, так і Kubernetes API (наприклад, див. [завдання управління трафіком через ingress](/docs/tasks/traffic-management/ingress/ingress-control)). Ви можете використовувати Gateway API з самого початку, дотримуючись [інструкцій з чого почати](/docs/setup/getting-started/).
{{< /tip >}}

## Налаштування {#setup}

1. API Gateway не встановлені стандартно ну більшості кластерів Kubernetes. Встановіть CRD для Gateway API, якщо вони відсутні:

    {{< text bash >}}
    $ kubectl get crd gateways.gateway.networking.k8s.io &> /dev/null || \
      { kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd?ref={{< k8s_gateway_api_version >}}" | kubectl apply -f -; }
    {{< /text >}}

1. Встановіть Istio, використовуючи профіль `minimal`:

    {{< text bash >}}
    $ istioctl install --set profile=minimal -y
    {{< /text >}}

## Відмінності від API Istio {#differences-from-istio-apis}

API Gateway мають багато спільного з API Istio, такими як Gateway та VirtualService. Основний ресурс має ту ж назву, `Gateway`, і ресурси служать подібним цілям.

Нові API Gateway прагнуть використати досвід різних реалізацій Kubernetes ingress, включаючи Istio, щоб створити стандартизований нейтральний до постачальника API. Ці API зазвичай виконують ті ж функції, що й Istio Gateway та VirtualService, з кількома ключовими відмінностями:

* В API Istio, `Gateway` *конфігурує* наявний Deployment/Service шлюзу, який [був розгорнутий](/docs/setup/additional-setup/gateway/). В API Gateway ресурс `Gateway` *конфігурує і розгортає* шлюз. Див. [Методи розгортання](#deployment-methods) для отримання додаткової інформації.
* У `VirtualService` Istio всі протоколи конфігуруються в одному ресурсі. В API Gateway кожен тип протоколу має свій ресурс, наприклад, `HTTPRoute` та `TCPRoute`.
* Хоча API Gateway пропонують багато розширених функцій маршрутизації, вони ще не охоплюють 100% функціональності Istio. Триває робота над розширенням API для покриття цих випадків використання, а також над використанням [розширюваності API](https://gateway-api.sigs.k8s.io/#gateway-api-concepts) для кращого відображення функціональності Istio.

## Налаштування Gateway {#configuring-a-gateway}

Див. документацію [Gateway API](https://gateway-api.sigs.k8s.io/) для отримання інформації про API.

У цьому прикладі ми розгорнемо простий застосунок та експонуємо його назовні за допомогою `Gateway`.

1. Спочатку розгорніть тестовий застосунок `httpbin`:

    {{< text bash >}}
    $ kubectl apply -f @samples/httpbin/httpbin.yaml@
    {{< /text >}}

2. Розгорніть конфігурацію Gateway API, включаючи один експонований маршрут (тобто `/get`):

    {{< text bash >}}
    $ kubectl create namespace istio-ingress
    $ kubectl apply -f - <<EOF
    apiVersion: gateway.networking.k8s.io/v1
    kind: Gateway
    metadata:
      name: gateway
      namespace: istio-ingress
    spec:
      gatewayClassName: istio
      listeners:
      - name: default
        hostname: "*.example.com"
        port: 80
        protocol: HTTP
        allowedRoutes:
          namespaces:
            from: All
    ---
    apiVersion: gateway.networking.k8s.io/v1
    kind: HTTPRoute
    metadata:
      name: http
      namespace: default
    spec:
      parentRefs:
      - name: gateway
        namespace: istio-ingress
      hostnames: ["httpbin.example.com"]
      rules:
      - matches:
        - path:
            type: PathPrefix
            value: /get
        backendRefs:
        - name: httpbin
          port: 8000
    EOF
    {{< /text >}}

3.  Встановіть змінну оточення Ingress Host:

    {{< text bash >}}
    $ kubectl wait -n istio-ingress --for=condition=programmed gateways.gateway.networking.k8s.io gateway
    $ export INGRESS_HOST=$(kubectl get gateways.gateway.networking.k8s.io gateway -n istio-ingress -ojsonpath='{.status.addresses[0].value}')
    {{< /text >}}

4.  Зверніться до сервісу `httpbin` за допомогою _curl_:

    {{< text bash >}}
    $ curl -s -I -HHost:httpbin.example.com "http://$INGRESS_HOST/get"
    HTTP/1.1 200 OK
    server: istio-envoy
    ...
    {{< /text >}}

    Зверніть увагу на використання прапорця `-H` для встановлення HTTP-заголовка _Host_ на "httpbin.example.com". Це необхідно, оскільки `HTTPRoute` налаштовано на обробку "httpbin.example.com", але у вашому тестовому середовищі ви не маєте привʼязки DNS для цього хосту і просто надсилаєте запит на вхідну IP-адресу.

5.  Перейдіть за будь-якою іншою URL-адресою, яка не була відкрита явно. Ви побачите помилку HTTP 404:

    {{< text bash >}}
    $ curl -s -I -HHost:httpbin.example.com "http://$INGRESS_HOST/headers"
    HTTP/1.1 404 Not Found
    ...
    {{< /text >}}

6.  Оновіть правило маршруту, щоб воно також враховувало `/headers` і додавало заголовок до запиту:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: gateway.networking.k8s.io/v1
    kind: HTTPRoute
    metadata:
      name: http
      namespace: default
    spec:
      parentRefs:
      - name: gateway
        namespace: istio-ingress
      hostnames: ["httpbin.example.com"]
      rules:
      - matches:
        - path:
            type: PathPrefix
            value: /get
        - path:
            type: PathPrefix
            value: /headers
        filters:
        - type: RequestHeaderModifier
          requestHeaderModifier:
            add:
            - name: my-added-header
              value: added-value
        backendRefs:
        - name: httpbin
          port: 8000
    EOF
    {{< /text >}}

7.  Знову зверніться до `/headers` і помітьте, що до запиту було додано заголовок `My-Added-Header`:

    {{< text bash >}}
    $ curl -s -HHost:httpbin.example.com "http://$INGRESS_HOST/headers"
    {
      "headers": {
        "Accept": "*/*",
        "Host": "httpbin.example.com",
        "My-Added-Header": "added-value",
    ...
    {{< /text >}}

## Методи розгортання {#deployment-methods}

В наведеному вище прикладі не потрібно було встановлювати `Deployment` для ingress gateway перед налаштуванням `Gateway`. У стандартній конфігурації `Deployment` та `Service` для gateway автоматично створюються на основі конфігурації `Gateway`.
Для складніших випадків використання також дозволено ручне розгортання.

### Автоматизоване розгортання {#automated-deployment}

Стандартно кожен `Gateway` автоматично створює `Service` та `Deployment` з тим самим імʼям. Ці конфігурації автоматично оновлюватимуться, якщо `Gateway` зміниться (наприклад, якщо буде додано новий порт).

Ці ресурси можна налаштувати кількома способами:

* Анотації та мітки на `Gateway` будуть скопійовані до `Service` та `Deployment`. Це дозволяє налаштовувати такі речі, як [Внутрішні балансувальники навантаження](https://kubernetes.io/docs/concepts/services-networking/service/#internal-load-balancer), які читають з цих полів.
* Istio пропонує додаткову анотацію для налаштування створених ресурсів:

    |Анотація|Призначення|
    |--------|-----------|
    |`networking.istio.io/service-type`|Контролює поле `Service.spec.type`. Наприклад, встановіть `ClusterIP`, щоб не відкривати сервіс зовні. Стандартне значення — `LoadBalancer`.|

* Поле `Service.spec.loadBalancerIP` може бути явно задано шляхом конфігурації поля `addresses`:

    {{< text yaml >}}
    apiVersion: gateway.networking.k8s.io/v1
    kind: Gateway
    metadata:
      name: gateway
    spec:
      addresses:
      - value: 192.0.2.0
        type: IPAddress
    ...
    {{< /text >}}

Примітка: можна вказати лише одну адресу.

* (Додатково) Згенеровану конфігурацію Pod можна налаштувати за допомогою [власних шаблонів інʼєкцій](/docs/setup/additional-setup/sidecar-injection/#custom-templates-experimental).

#### Прикріплення ресурсів і масштабування {#resource-attachment-and-scaling}

{{< warning >}}
Прикріплення ресурсів наразі є експериментальним.
{{< /warning >}}

Ресурси можуть бути *прикріплені* до `Gateway` для його налаштування. Однак більшість ресурсів Kubernetes наразі не підтримують пряме прикріплення до `Gateway`, але їх можна прикріпити до відповідних згенерованих `Deployment` і `Service` замість цього. Це легко здійснити, оскільки обидва ці ресурси створюються з іменем `<gateway name>-<gateway class name>` і з міткою `gateway.networking.k8s.io/gateway-name: <gateway name>`.

Наприклад, щоб розгорнути `Gateway` з `HorizontalPodAutoscaler` і `PodDisruptionBudget`:

{{< text yaml >}}
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: gateway
spec:
  gatewayClassName: istio
  listeners:
  - name: default
    hostname: "*.example.com"
    port: 80
    protocol: HTTP
    allowedRoutes:
      namespaces:
        from: All
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: gateway
spec:
  # Match the generated Deployment by reference
  # Note: Do not use `kind: Gateway`.
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: gateway-istio
  minReplicas: 2
  maxReplicas: 5
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 50
---
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: gateway
spec:
  minAvailable: 1
  selector:
    # Match the generated Deployment by label
    matchLabels:
      gateway.networking.k8s.io/gateway-name: gateway
{{< /text >}}

### Ручне розгортання {#manual-deployment}

Якщо ви не хочете автоматичного розгортання, `Deployment` і `Service` можна [налаштувати вручну](/docs/setup/additional-setup/gateway/).

При цьому вам буде потрібно вручну зв’язати `Gateway` з `Service`, а також підтримувати їх конфігурацію портів в актуальному стані.

Щоб зв’язати `Gateway` з `Service`, налаштуйте поле `addresses`, щоб воно вказувало на **один** `Hostname`.

{{< text yaml >}}
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: gateway
spec:
  addresses:
  - value: ingress.istio-gateways.svc.cluster.local
    type: Hostname
...
{{< /text >}}

## Трафік mesh-мережі {#mesh-traffic}

API Gateway також можна використовувати для налаштування трафіку мережі. Це робиться шляхом налаштування `parentRef`, щоб вказувати на сервіс, а не на шлюз.

Наприклад, щоб додати заголовок до всіх запитів до сервісу всередині кластера з назвою `example`:

{{< text yaml >}}
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: mesh
spec:
  parentRefs:
  - group: ""
    kind: Service
    name: example
  rules:
  - filters:
    - type: RequestHeaderModifier
      requestHeaderModifier:
        add:
        - name: my-added-header
          value: added-value
    backendRefs:
    - name: example
      port: 80
{{< /text >}}

Більш детальну інформацію та приклади можна знайти в інших [завданнях з управління трафіком](/docs/tasks/traffic-management/).

## Очищення {#cleanup}

1. Видаліть зразок `httpbin` і шлюз:

    {{< text bash >}}
    $ kubectl delete -f @samples/httpbin/httpbin.yaml@
    $ kubectl delete httproute http
    $ kubectl delete gateways.gateway.networking.k8s.io gateway -n istio-ingress
    $ kubectl delete ns istio-ingress
    {{< /text >}}

1. Видаліть Istio:

    {{< text bash >}}
    $ istioctl uninstall -y --purge
    $ kubectl delete ns istio-system
    {{< /text >}}

1. Видаліть CRD API шлюзу, якщо вони більше не потрібні:

    {{< text bash >}}
    $ kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd?ref={{< k8s_gateway_api_version >}}" | kubectl delete -f -
    {{< /text >}}
