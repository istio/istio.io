---
title: Проблеми з управлінням трафіком
description: Техніки для вирішення поширених проблем з управлінням трафіком та мережевих проблем в Istio.
force_inline_toc: true
weight: 10
aliases:
  - /uk/help/ops/traffic-management/troubleshooting
  - /uk/help/ops/troubleshooting/network-issues
  - /uk/docs/ops/troubleshooting/network-issues
owner: istio/wg-networking-maintainers
test: n/a
---

## Запити відхиляються Envoy {#requests-are-rejected-by-envoy}

Запити можуть бути відхилені з різних причин. Найкращий спосіб зрозуміти, чому запити відхиляються — це перевірити журнали доступу Envoy. Стандартно журнали доступу виводяться на стандартний вихід контейнера. Виконайте наступну команду, щоб переглянути журнал:

{{< text bash >}}
$ kubectl logs PODNAME -c istio-proxy -n NAMESPACE
{{< /text >}}

У форматі журналу доступу стандартно прапорці відповіді Envoy розташовані після коду відповіді, якщо ви використовуєте власний формат журналу, переконайтеся, що ви включили `%RESPONSE_FLAGS%`.

Зверніться до [прапорців відповіді Envoy](https://www.envoyproxy.io/docs/envoy/latest/configuration/observability/access_log/usage#config-access-log-format-response-flags) для отримання деталей про прапорці відповіді.

Загальні прапорці відповіді:

- `NR`: Шлях не налаштований, перевірте ваш `DestinationRule` або `VirtualService`.
- `UO`: Переповнення upstream зі спрацюванням запобіжника (circuit breaking), перевірте налаштування запобіжника у `DestinationRule`.
- `UF`: Не вдалося підєднатися до upstream, якщо ви використовуєте автентифікацію Istio, перевірте [конфлікт конфігурації взаємного TLS](#503-errors-after-setting-destination-rule).

## Правила маршрутизації, здається, не впливають на потік трафіку {#route-rules-dont-affect-traffic-flow}

З поточною реалізацією Envoy sidecar може знадобитися до 100 запитів для того, щоб розподіл версій з вагою став помітним.

Якщо правила маршрутизації працюють ідеально для [Bookinfo](/docs/examples/bookinfo/), але аналогічні правила маршрутизації версій не мають жодного ефекту для вашого власного застосунку, можливо, що ваші сервіси Kubernetes потрібно трохи змінити. Сервіси Kubernetes повинні відповідати певним обмеженням, щоб скористатися функціями маршрутизації L7 Istio. Дивіться [Вимоги до Podʼів та Services](/docs/ops/deployment/application-requirements/) для отримання деталей.

Ще одна потенційна проблема може бути в тому, що правила маршрутизації можуть просто повільно набирати силу. Реалізація Istio в Kubernetes використовує алгоритм, що забезпечує в кінцевому рахунку вірний результат, щоб забезпечити всім sidecar Envoy правильну конфігурацію, включаючи всі правила маршрутизації. Зміна конфігурації займе деякий час для поширення на всі sidecar. При великих розгортаннях поширення займе більше часу і може бути затримка на кілька секунд.

## Помилки 503 після налаштування DestinationRule {#503-errors-after-setting-destination-rule}

{{< tip >}}
Ви повинні побачити цю помилку лише в тому випадку, якщо ви вимкнули [автоматичний взаємний TLS](/docs/tasks/security/authentication/authn-policy/#auto-mutual-tls) під час установки.
{{< /tip >}}

Якщо запити до сервісу починають негайно генерувати помилки HTTP 503 після того, як ви застосували `DestinationRule`, і помилки тривають до тих пір, поки ви не видалите або не скасуєте `DestinationRule`, ймовірно, що `DestinationRule` викликає конфлікт TLS для сервісу.

Наприклад, якщо ви налаштували взаємний TLS у кластері глобально, `DestinationRule` повинен включати наступний `trafficPolicy`:

{{< text yaml >}}
trafficPolicy:
  tls:
    mode: ISTIO_MUTUAL
{{< /text >}}

В іншому випадку стандартний режим буде `DISABLE`, що викликає використання простих HTTP запитів з боку проксі клієнта замість зашифрованих TLS запитів. Таким чином, запити конфліктують з проксі сервера, оскільки серверний проксі очікує зашифровані запити.

Щоразу, коли ви застосовуєте `DestinationRule`, переконайтеся, що режим TLS `trafficPolicy` відповідає глобальній конфігурації сервера.

## Правила маршрутизації не мають ефекту на запити до ingress gateway {#route-rules-have-no-effect-on-ingress-gateway-requests}

Припустимо, ви використовуєте ingress `Gateway` і відповідний `VirtualService`, щоб отримати доступ до внутрішнього сервіса. Наприклад, ваш `VirtualService` виглядає приблизно так:

{{< text yaml >}}
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: myapp
spec:
  hosts:
  - "myapp.com" # або "*" якщо ви тестуєте без DNS, використовуючи IP ingress-gateway (наприклад, http://1.2.3.4/hello)
  gateways:
  - myapp-gateway
  http:
  - match:
    - uri:
        prefix: /hello
    route:
    - destination:
        host: helloworld.default.svc.cluster.local
  - match:
    ...
{{< /text >}}

У вас також є `VirtualService`, який маршрутизує трафік для сервіса helloworld для певної підмножини:

{{< text yaml >}}
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: helloworld
spec:
  hosts:
  - helloworld.default.svc.cluster.local
  http:
  - route:
    - destination:
        host: helloworld.default.svc.cluster.local
        subset: v1
{{< /text >}}

У цій ситуації ви помітите, що запити до сервіса helloworld через ingress gateway не будуть направлені до підмножини v1, а продовжать використовувати стандартну маршрутизацію round-robin.

Запити до ingress використовують хост gateway (наприклад, `myapp.com`), який активує правила в myapp `VirtualService`, що маршрутизують до будь-якої точки доступу сервісу helloworld. Лише внутрішні запити з хостом `helloworld.default.svc.cluster.local` будуть використовувати helloworld `VirtualService`, який направляє трафік виключно до підмножини v1.

Щоб контролювати трафік від gateway, вам також потрібно включити правило підмножини в myapp `VirtualService`:

{{< text yaml >}}
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: myapp
spec:
  hosts:
  - "myapp.com" # або "*" якщо ви тестуєте без DNS, використовуючи IP ingress-gateway (наприклад, http://1.2.3.4/hello)
  gateways:
  - myapp-gateway
  http:
  - match:
    - uri:
        prefix: /hello
    route:
    - destination:
        host: helloworld.default.svc.cluster.local
        subset: v1
  - match:
    ...
{{< /text >}}

Альтернативно, ви можете обʼєднати обидва `VirtualServices` в один, якщо це можливо:

{{< text yaml >}}
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: myapp
spec:
  hosts:
  - myapp.com # не можна використовувати "*" тут, оскільки це поєднується з послугами мережі
  - helloworld.default.svc.cluster.local
  gateways:
  - mesh # застосовується як внутрішньо, так і зовнішньо
  - myapp-gateway
  http:
  - match:
    - uri:
        prefix: /hello
      gateways:
      - myapp-gateway # обмежує це правило застосовуватися лише до ingress gateway
    route:
    - destination:
        host: helloworld.default.svc.cluster.local
        subset: v1
  - match:
    - gateways:
      - mesh # застосовується до всіх служб всередині мережі
    route:
    - destination:
        host: helloworld.default.svc.cluster.local
        subset: v1
{{< /text >}}

## Envoy виходить з ладу під навантаженням {#envoy-is-crashing-under-load}

Перевірте ваш `ulimit -a`. Багато систем стандартно мають обмеження на кількість відкритих файлових дескрипторів в 1024, що може викликати збій Envoy з помилкою:

{{< text plain >}}
[2017-05-17 03:00:52.735][14236][critical][assert] assert failure: fd_ != -1: external/envoy/source/common/network/connection_impl.cc:58
{{< /text >}}

Переконайтеся, що ви підвищили ваш ulimit. Наприклад: `ulimit -n 16384`

## Envoy не підключається до мого HTTP/1.0 сервісу {#envoy-wont-connect-to-my-http10-service}

Envoy вимагає трафіку `HTTP/1.1` або `HTTP/2` для висхідних (upstream) сервісів. Наприклад, при використанні [NGINX](https://www.nginx.com/) для обробки трафіку за Envoy, вам потрібно встановити директиву [proxy_http_version](https://nginx.org/en/docs/http/ngx_http_proxy_module.html#proxy_http_version) у вашій конфігурації NGINX на "1.1", оскільки стандартно NGINX використовує версію 1.0.

Приклад конфігурації:

{{< text plain >}}
upstream http_backend {
    server 127.0.0.1:8080;

    keepalive 16;
}

server {
    ...

    location /http/ {
        proxy_pass http://http_backend;
        proxy_http_version 1.1;
        proxy_set_header Connection "";
        ...
    }
}
{{< /text >}}

## Помилка 503 при доступі до headless сервісів {#503-error-while-accessing-headless-services}

Припустимо, що Istio встановлено з наступною конфігурацією:

- `mTLS mode` встановлено на `STRICT` в межах мережі
- `meshConfig.outboundTrafficPolicy.mode` встановлено на `ALLOW_ANY`

Розглянемо, що `nginx` розгорнуто як `StatefulSet` у стандартному просторі і відповідний `Headless Service` визначено наступним чином:

{{< text yaml >}}
apiVersion: v1
kind: Service
metadata:
  name: nginx
  labels:
    app: nginx
spec:
  ports:
  - port: 80
    name: http-web  # Явно визначаємо http порт
  clusterIP: None   # Створює Headless Service
  selector:
    app: nginx
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: web
spec:
  selector:
    matchLabels:
      app: nginx
  serviceName: "nginx"
  replicas: 3
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: registry.k8s.io/nginx-slim:0.8
        ports:
        - containerPort: 80
          name: web
{{< /text >}}

Імʼя порту `http-web` в визначенні Service явно вказує на протокол http для цього порту.

Припустимо, що у нас також є `Deployment` podʼа [curl]({{< github_tree >}}/samples/curl) в стандартному просторі. Коли `nginx` доступний з цього podʼа `curl`, використовуючи його IP-адресу (це один із поширених способів доступу до headless сервісу), запит проходить через `PassthroughCluster` до серверної сторони, але проксі-сервер на стороні сервера не може знайти маршрут до `nginx` і зіпиняється з помилкою `HTTP 503 UC`.

{{< text bash >}}
$ export SOURCE_POD=$(kubectl get pod -l app=curl -o jsonpath='{.items..metadata.name}')
$ kubectl exec -it $SOURCE_POD -c curl -- curl 10.1.1.171 -s -o /dev/null -w "%{http_code}"
  503
{{< /text >}}

`10.1.1.171` є IP-адресою однієї з реплік `nginx`, а сервіс доступний на `containerPort` 80.

Ось кілька способів уникнути цієї помилки 503:

1. Вкажіть правильний заголовок Host:

    Заголовок Host у запиті curl стандартно буде IP-адреса Pod. Вказання заголовка Host як `nginx.default` у нашому запиті до `nginx` успішно повертає `HTTP 200 OK`.

    {{< text bash >}}
    $ export SOURCE_POD=$(kubectl get pod -l app=curl -o jsonpath='{.items..metadata.name}')
    $ kubectl exec -it $SOURCE_POD -c curl -- curl -H "Host: nginx.default" 10.1.1.171 -s -o /dev/null -w "%{http_code}"
      200
    {{< /text >}}

2. Встановіть імʼя порту як `tcp` або `tcp-web` або `tcp-<custom_name>`:

    Тут протокол явно вказано як `tcp`. У цьому випадку використовується тільки `TCP Proxy` мережевий фільтр на проксі-сервері як на клієнтській, так і на серверній стороні. HTTP Connection Manager взагалі не використовується і тому жодний заголовок не очікується у запиті.

    Запит до `nginx` з або без явного вказання заголовка Host успішно повертає `HTTP 200 OK`.

    Це корисно в певних сценаріях, де клієнт може не мати можливості включити інформацію про заголовок у запит.

    {{< text bash >}}
    $ export SOURCE_POD=$(kubectl get pod -l app=curl -o jsonpath='{.items..metadata.name}')
    $ kubectl exec -it $SOURCE_POD -c curl -- curl 10.1.1.171 -s -o /dev/null -w "%{http_code}"
      200
    {{< /text >}}

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c curl -- curl -H "Host: nginx.default" 10.1.1.171 -s -o /dev/null -w "%{http_code}"
      200
    {{< /text >}}

3. Використовуйте доменне імʼя замість IP-адреси Pod:

    До конкретного екземпляру headless сервісу також можна отримати доступ за допомогою доменного імені.

    {{< text bash >}}
    $ export SOURCE_POD=$(kubectl get pod -l app=curl -o jsonpath='{.items..metadata.name}')
    $ kubectl exec -it $SOURCE_POD -c curl -- curl web-0.nginx.default -s -o /dev/null -w "%{http_code}"
      200
    {{< /text >}}

    Тут `web-0` є імʼям podʼа однієї з 3 реплік `nginx`.

Зверніться до цієї сторінки [маршрутизації трафіку](/docs/ops/configuration/traffic-management/traffic-routing/) для додаткової інформації про headless сервіси та поведінку маршрутизації трафіку для різних протоколів.

## Помилки конфігурації TLS {#tls-configuration-mistakes}

Багато проблем з управлінням трафіком викликані неправильною [конфігурацією TLS](/docs/ops/configuration/traffic-management/tls-configuration/). Нижче описано деякі з найпоширеніших помилок конфігурації.

### Надсилання HTTPS на HTTP порт {#sending-https-to-an-http-port}

Якщо ваш застосуок надсилає HTTPS запит на сервіс, який оголошений як HTTP, проксі Envoy спробує обробити запит як HTTP під час пересилання запиту, що зазнає невдачі, оскільки HTTP несподівано зашифрований.

{{< text yaml >}}
apiVersion: networking.istio.io/v1
kind: ServiceEntry
metadata:
  name: httpbin
spec:
  hosts:
  - httpbin.org
  ports:
  - number: 443
    name: http
    protocol: HTTP
  resolution: DNS
{{< /text >}}

Хоча наведену вище конфігурацію можна вважати правильною, якщо ви навмисно надсилаєте відкритий текст на порт 443 (наприклад, `curl http://httpbin.org:443`), зазвичай порт 443 призначений для HTTPS трафіку.

Надсилання HTTPS запиту, наприклад, `curl https://httpbin.org`, який стандартно використовує порт 443, призведе до помилки на кшталт `curl: (35) error:1408F10B:SSL routines:ssl3_get_record:wrong version number`. Журнали доступу також можуть показувати помилку, таку як `400 DPE`.

Щоб виправити це, потрібно змінити протокол порту на HTTPS:

{{< text yaml >}}
spec:
  ports:
  - number: 443
    name: https
    protocol: HTTPS
{{< /text >}}

### Невідповідність TLS між шлюзом і віртуальним сервісом {#gateway-mismatch}

Можуть виникнути дві поширені невідповідності TLS при привʼязці віртуального сервіса до шлюзу.

1. Шлюз термінує TLS, тоді як віртуальний сервіс конфігурує маршрутизацію TLS.
1. Шлюз виконує TLS passthrough, тоді як віртуальний серві конфігурує HTTP маршрутизацію.

#### Шлюз з TLS термінацією {#gateway-with-tls-termination}

{{< text yaml >}}
apiVersion: networking.istio.io/v1
kind: Gateway
metadata:
  name: gateway
  namespace: istio-system
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 443
      name: https
      protocol: HTTPS
    hosts:
      - "*"
    tls:
      mode: SIMPLE
      credentialName: sds-credential
---
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: httpbin
spec:
  hosts:
  - "*.example.com"
  gateways:
  - istio-system/gateway
  tls:
  - match:
    - sniHosts:
      - "*.example.com"
    route:
    - destination:
        host: httpbin.org
{{< /text >}}

У цьому прикладі шлюз термінує TLS (конфігурація `tls.mode` шлюзу є `SIMPLE`, а не `PASSTHROUGH`), тоді як віртуальний сервіс використовує маршрутизацію на основі TLS. Оцінка правил маршрутизації відбувається після завершення TLS шлюзом, тому правило TLS не матиме ефекту, оскільки запит тоді є HTTP, а не HTTPS.

З цією помилкою конфігурації ви отримаєте відповіді 404, оскільки запити будуть направлені на маршрутизацію HTTP, але не налаштовано жодних HTTP маршрутів. Ви можете підтвердити це, використовуючи команду `istioctl proxy-config routes`.

Щоб виправити цю проблему, слід переключити віртуальний сервіс на маршрутизацію `http`, а не `tls`:

{{< text yaml >}}
spec:
  ...
  http:
  - match:
    - headers:
        ":authority":
          regex: "*.example.com"
{{< /text >}}

#### Шлюз з TLS passthrough {#gateway-with-tls-passthrough}

{{< text yaml >}}
apiVersion: networking.istio.io/v1
kind: Gateway
metadata:
  name: gateway
spec:
  selector:
    istio: ingressgateway
  servers:
  - hosts:
    - "*"
    port:
      name: https
      number: 443
      protocol: HTTPS
    tls:
      mode: PASSTHROUGH
---
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: virtual-service
spec:
  gateways:
  - gateway
  hosts:
  - httpbin.example.com
  http:
  - route:
    - destination:
        host: httpbin.org
{{< /text >}}

У цій конфігурації віртуальний сервіс намагається з’єднати HTTP трафік з TLS трафіком, що проходить через шлюз. Це призведе до того, що конфігурація віртуального сервіса не матиме жодного ефекту. Ви можете спостерігати, що HTTP маршрут не застосовується за допомогою команд `istioctl proxy-config listener` та `istioctl proxy-config route`.

Щоб виправити це, потрібно переключити віртуальний сревіс на конфігурацію маршрутизації `tls`:

{{< text yaml >}}
spec:
  tls:
  - match:
    - sniHosts: ["httpbin.example.com"]
    route:
    - destination:
        host: httpbin.org
{{< /text >}}

Альтернативно, ви можете термінувати TLS, а не передавати його через шлюз, змінивши конфігурацію `tls` в шлюзі:

{{< text yaml >}}
spec:
  ...
    tls:
      credentialName: sds-credential
      mode: SIMPLE
{{< /text >}}

### Подвійний TLS (створення TLS для TLS-запиту) {#double-tls}

При налаштуванні Istio для виконання {{< gloss "Створення TLS" >}}створення TLS{{< /gloss >}}, необхідно переконатися, що застосунок надсилає запити у незашифрованому вигляді до sidecar, який потім ініціює TLS.

Наступний `DestinationRule` ініціює TLS для запитів до сервісу `httpbin.org`, але відповідний `ServiceEntry` визначає протокол як HTTPS на порту 443.

{{< text yaml >}}
apiVersion: networking.istio.io/v1
kind: ServiceEntry
metadata:
  name: httpbin
spec:
  hosts:
  - httpbin.org
  ports:
  - number: 443
    name: https
    protocol: HTTPS
  resolution: DNS
---
apiVersion: networking.istio.io/v1
kind: DestinationRule
metadata:
  name: originate-tls
spec:
  host: httpbin.org
  trafficPolicy:
    tls:
      mode: SIMPLE
{{< /text >}}

З цією конфігурацією sidecar очікує, що застосунок надішле TLS-трафік на порт 443 (наприклад, `curl https://httpbin.org`), але також виконає створення TLS перед пересиланням запитів. Це призведе до подвійного шифрування запитів.

Наприклад, надсилання запиту, як-от `curl https://httpbin.org`, призведе до помилки: `(35) error:1408F10B:SSL routines:ssl3_get_record:wrong version number`.

Виправити це можна, змінивши протокол порту в `ServiceEntry` на HTTP:

{{< text yaml >}}
spec:
  hosts:
  - httpbin.org
  ports:
  - number: 443
    name: http
    protocol: HTTP
{{< /text >}}

Зверніть увагу, що з цією конфігурацією ваш застосунок повинен надсилати незашифровані запити на порт 443, як-от `curl http://httpbin.org:443`, оскільки створення TLS не змінює порт. Однак починаючи з Istio 1.8, ви можете відкрити HTTP порт 80 для застосунку (наприклад, `curl http://httpbin.org`) і потім перенаправити запити на `targetPort` 443 для сворення TLS:

{{< text yaml >}}
spec:
  hosts:
  - httpbin.org
  ports:
  - number: 80
    name: http
    protocol: HTTP
    targetPort: 443
{{< /text >}}

### Помилки 404 при налаштуванні кількох шлюзів з одним і тим же TLS сертифікатом {#404-errors-occur-when-multiple-gateways-configured-with-same-tls-certificate}

Налаштування більше одного шлюзу з одним і тим же TLS сертифікатом призведе до помилок 404 в оглядачах, які використовують [повторне використання з’єднання HTTP/2](https://httpwg.org/specs/rfc7540.html#reuse) (тобто більшість оглядачів), коли ви звертаєтеся до другого хоста після того, як з’єднання з іншим хостом вже було встановлено.

Наприклад, припустимо, що у вас є 2 хости, які використовують один і той же TLS сертифікат:

- Wildcard сертифікат `*.test.com`, встановлений в `istio-ingressgateway`
- Конфігурація `Gateway` `gw1` з хостом `service1.test.com`, селектором `istio: ingressgateway` та TLS, що використовує сертифікат шлюзу (wildcard)
- Конфігурація `Gateway` `gw2` з хостом `service2.test.com`, селектором `istio: ingressgateway` та TLS, що використовує сертифікат шлюзу (wildcard)
- Конфігурація `VirtualService` `vs1` з хостом `service1.test.com` і шлюзом `gw1`
- Конфігурація `VirtualService` `vs2` з хостом `service2.test.com` і шлюзом `gw2`

Оскільки обидва шлюзи обслуговуються одним робочим навантаженням (тобто селектор `istio: ingressgateway`), запити до обох сервісів (`service1.test.com` і `service2.test.com`) будуть розв’язані на одні й ті ж IP-адреси. Якщо спочатку звернутися до `service1.test.com`, він поверне wildcard сертифікат (`*.test.com`), вказуючи, що з’єднання з `service2.test.com` можуть використовувати той же сертифікат. Оглядачі, такі як Chrome і Firefox, відповідно, повторно використовуватимуть існуюче з’єднання для запитів до `service2.test.com`. Оскільки шлюз (`gw1`) не має маршруту для `service2.test.com`, він поверне помилку 404 (Не знайдено).

Ви можете уникнути цієї проблеми, налаштувавши один wildcard `Gateway`, а не два (`gw1` і `gw2`). Тоді просто прив’яжіть обидва `VirtualServices` до нього, ось так:

- Конфігурація `Gateway` `gw` з хостом `*.test.com`, селектором `istio: ingressgateway` та TLS, що використовує сертифікат шлюзу (wildcard)
- Конфігурація `VirtualService` `vs1` з хостом `service1.test.com` і шлюзом `gw`
- Конфігурація `VirtualService` `vs2` з хостом `service2.test.com` і шлюзом `gw`

### Налаштування маршрутизації SNI, коли SNI не надсилається {#configuring-sni-routing-when-not-sending-sni}

HTTPS `Gateway`, який вказує поле `hosts`, виконує [SNI](https://en.wikipedia.org/wiki/Server_Name_Indication) збіг для вхідних запитів. Наприклад, наступна конфігурація дозволяє лише запити, що відповідають `*.example.com` в SNI:

{{< text yaml >}}
servers:
- port:
    number: 443
    name: https
    protocol: HTTPS
  hosts:
  - "*.example.com"
{{< /text >}}

Це може призвести до помилок для деяких запитів.

Наприклад, якщо ви не налаштували DNS і натомість безпосередньо встановлюєте заголовок хоста, як `curl 1.2.3.4 -H "Host: app.example.com"`, SNI не буде встановлено, що призведе до помилки запиту. Замість цього, ви можете налаштувати DNS або використовувати прапорець `--resolve` для `curl`. Для отримання додаткової інформації дивіться завдання [Захист Gateways](/docs/tasks/traffic-management/ingress/secure-ingress/).

Ще однією поширеною проблемою є балансувальники навантаження перед Istio. Більшість хмарних балансувальників навантаження не пересилають SNI, тому якщо ви термінуєте TLS у своєму хмарному балансувальнику навантаження, вам може знадобитися виконати одну з наступних дій:

- Налаштувати хмарний балансувальник навантаження для передачі TLS-зʼєднання
- Вимкнути зіставлення SNI у `Gateway`, встановивши поле hosts на `*`

Зазвичай симптомом цього є те, що перевірки справності балансувальника навантаження успішні, але реальний трафік не проходить.

## Незмінена конфігурація фільтра Envoy раптово перестає працювати{#unchanged-envoy-filter-configuration-suddenly-stops-working}

Конфігурація `EnvoyFilter`, яка вказує позицію вставки відносно іншого фільтра, може бути дуже нестійкою, оскільки, стандартно, порядок оцінювання базується на часі створення фільтрів. Розгляньте фільтр з наступною специфікацією:

{{< text yaml >}}
spec:
  configPatches:
  - applyTo: NETWORK_FILTER
    match:
      context: SIDECAR_OUTBOUND
      listener:
        portNumber: 443
        filterChain:
          filter:
            name: istio.stats
    patch:
      operation: INSERT_BEFORE
      value:
        ...
{{< /text >}}

Щоб працювати правильно, ця конфігурація фільтра залежить від того, щоб фільтр `istio.stats` мав старіший час створення, ніж він. В іншому випадку операція `INSERT_BEFORE` буде проігнорована без сповіщення про це. У журналі помилок не буде нічого, що вказує на те, що цей фільтр не було додано до ланцюга.

Це особливо проблематично при порівнянні фільтрів, таких як `istio.stats`, які є версійно специфічними (тобто містять поле `proxyVersion` у своїх критеріях збігу). Такі фільтри можуть бути видалені або замінені новими при оновленні Istio. Як результат, `EnvoyFilter`, подібний до наведеного вище, може спочатку працювати бездоганно, але після оновлення Istio до новішої версії його більше не буде включено в ланцюг мережевого фільтра sidecarʼів.

Щоб уникнути цієї проблеми, ви можете або змінити операцію на ту, яка не залежить від наявності іншого фільтра (наприклад, `INSERT_FIRST`), або встановити явний пріоритет у `EnvoyFilter`, щоб перевизначити стандартне впорядкування на основі часу створення. Наприклад, додавання `priority: 10` до наведеного вище фільтра забезпечить його обробку після фільтра `istio.stats`, який має стандартний пріоритет 0.

## Віртуальний сервіс з інʼєкцією хбоїва і політиками повторних спроб/тайм-аутів не працює як очікується {#virtual-service-with-fault-injection-and-retry-timeout-policies-not-working-as-expected}

На даний момент Istio не підтримує конфігурацію інʼєкцій збоїв і політик повторних спроб або тайм-аутів в одному й тому ж `VirtualService`. Розгляньте наступну конфігурацію:

{{< text yaml >}}
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: helloworld
spec:
  hosts:
    - "*"
  gateways:
  - helloworld-gateway
  http:
  - match:
    - uri:
        exact: /hello
    fault:
      abort:
        httpStatus: 500
        percentage:
          value: 50
    retries:
      attempts: 5
      retryOn: 5xx
    route:
    - destination:
        host: helloworld
        port:
          number: 5000
{{< /text >}}

Ви могли б очікувати, що, враховуючи пʼять налаштованих повторних спроб, користувач майже ніколи не побачити помилок при виклику сервісу `helloworld`. Однак, оскільки і налаштування помилок, і повторні спроби сконфігуровані в одному й тому ж `VirtualService`, конфігурація повторних спроб не буде застосовуватися, що призводить до рівня помилок 50%. Щоб розвʼязати цю проблему, ви можете видалити конфігурацію помилок з вашого `VirtualService` і зроби інʼєкцію збою у висхідний (upstream) Envoy проксі за допомогою `EnvoyFilter` замість цього:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: EnvoyFilter
metadata:
  name: hello-world-filter
spec:
  workloadSelector:
    labels:
      app: helloworld
  configPatches:
  - applyTo: HTTP_FILTER
    match:
      context: SIDECAR_INBOUND # буде збігатися з вихідними слухачами в усіх sidecarʼах
      listener:
        filterChain:
          filter:
            name: "envoy.filters.network.http_connection_manager"
    patch:
      operation: INSERT_BEFORE
      value:
        name: envoy.fault
        typed_config:
          "@type": "type.googleapis.com/envoy.extensions.filters.http.fault.v3.HTTPFault"
          abort:
            http_status: 500
            percentage:
              numerator: 50
              denominator: HUNDRED
{{< /text >}}

Це працює, тому що таким чином політика повторних спроб конфігурується для клієнтського проксі, а інʼєкція збоїів — для upstream проксі.
