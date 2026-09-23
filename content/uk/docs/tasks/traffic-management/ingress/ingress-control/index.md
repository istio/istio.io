---
title: Ingress Gateways
description: Описує, як налаштувати шлюз Istio для експонування сервісу поза межами сервісної мережі.
weight: 10
keywords: [traffic-management,ingress]
aliases:
    - /uk/docs/tasks/ingress.html
    - /uk/docs/tasks/ingress
owner: istio/wg-networking-maintainers
test: yes
---

Разом із підтримкою ресурсів [Ingress](/docs/tasks/traffic-management/ingress/kubernetes-ingress/) Kubernetes, Istio також дозволяє налаштувати вхідний трафік, використовуючи ресурс [Istio Gateway](/docs/concepts/traffic-management/#gateways) або [Kubernetes Gateway](https://gateway-api.sigs.k8s.io/api-types/gateway/). `Gateway` забезпечує ширші налаштування та гнучкість, ніж `Ingress`, і дозволяє застосовувати функції Istio, такі як моніторинг та правила маршрутизації, до трафіку, що входить у кластер.

Ця задача описує, як налаштувати Istio для експонування сервісу за межами сервісної мережі, використовуючи `Gateway`.

{{< boilerplate gateway-api-support >}}

## Перш ніж почати {#before-you-begin}

*   Налаштуйте Istio, дотримуючись інструкцій з [Посібника з встановлення](/docs/setup/).

    {{< tip >}}
    Якщо ви плануєте використовувати інструкції `Gateway API`, ви можете встановити Istio, використовуючи профіль `minimal`, оскільки вам не знадобиться `istio-ingressgateway`, який інакше встановлюється стандартно:

    {{< text bash >}}
    $ istioctl install --set profile=minimal
    {{< /text >}}

    {{< /tip >}}

*   Запустіть [httpbin]({{< github_tree >}}/samples/httpbin), який буде служити цільовим сервісом для вхідного трафіку:

    {{< text bash >}}
    $ kubectl apply -f @samples/httpbin/httpbin.yaml@
    {{< /text >}}

    Зверніть увагу, що для цілей цього документа, який показує, як використовувати шлюз для контролю вхідного трафіку у вашому "Kubernetes кластері", ви можете запустити сервіс `httpbin` з увімкненою чи вимкненою ін’єкцією sidecar (тобто, цільовий сервіс може бути як всередині, так і поза мережею Istio).

## Налаштування вхідного трафіку за допомогою шлюзу {#configuring-ingress-using-a-gateway}

Вхідний `Gateway` описує балансувальник навантаження, який працює на периметрі мережі та приймає вхідні HTTP/TCP зʼєднання. Він налаштовує відкриті порти, протоколи тощо, але, на відміну від [ресурсів Ingress Kubernetes](https://kubernetes.io/docs/concepts/services-networking/ingress/), не включає жодної конфігурації маршрутизації трафіку. Маршрутизація трафіку для вхідного трафіку налаштовується за допомогою правил маршрутизації, точно так само, як і для внутрішніх запитів до сервісів.

Подивімось, як можна налаштувати `Gateway` на порту 80 для HTTP трафіку.

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

Створимо [Istio Gateway](/docs/reference/config/networking/gateway/):

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1
kind: Gateway
metadata:
  name: httpbin-gateway
spec:
  # Селектор збігається з мітками podʼів ingress gateway.
  # Якщо ви встановили Istio за допомогою Helm, слідуючи стандартній документації, це буде "istio=ingress"
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "httpbin.example.com"
EOF
{{< /text >}}

Налаштуйте маршрути для трафіку, що надходить через `Gateway`:

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: httpbin
spec:
  hosts:
  - "httpbin.example.com"
  gateways:
  - httpbin-gateway
  http:
  - match:
    - uri:
        prefix: /status
    - uri:
        prefix: /delay
    route:
    - destination:
        port:
          number: 8000
        host: httpbin
EOF
{{< /text >}}

Тепер ви створили конфігурацію [віртуального сервісу](/docs/reference/config/networking/virtual-service/) для сервісу `httpbin`, що містить два правила маршрутизації, які дозволяють трафік для шляхів `/status` та `/delay`.

Список [шлюзів](/docs/reference/config/networking/virtual-service/#VirtualService-gateways) вказує, що дозволені лише запити через ваш `httpbin-gateway`. Усі інші зовнішні запити будуть відхилені з відповіддю 404.

{{< warning >}}
Внутрішні запити від інших сервісів у мережі не підлягають цим правилам та стандартно використовують маршрутизацію round-robin. Щоб застосувати ці правила і до внутрішніх викликів, ви можете додати спеціальне значення `mesh` до списку `gateways`. Оскільки внутрішній hostname сервісу, ймовірно, відрізняється (наприклад, `httpbin.default.svc.cluster.local`) від зовнішнього, вам також потрібно буде додати його до списку `hosts`. Для отримання додаткової інформації зверніться до [посібника з експлуатації](/docs/ops/common-problems/network-issues#route-rules-have-no-effect-on-ingress-gateway-requests).
{{< /warning >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

Створіть [Kubernetes Gateway](https://gateway-api.sigs.k8s.io/references/spec/#gateway.networking.k8s.io/v1.Gateway):

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: httpbin-gateway
spec:
  gatewayClassName: istio
  listeners:
  - name: http
    hostname: "httpbin.example.com"
    port: 80
    protocol: HTTP
    allowedRoutes:
      namespaces:
        from: Same
EOF
{{< /text >}}

{{< tip >}}
В операційному середовищі, `Gateway` та відповідні маршрути часто створюються в окремих просторах імен користувачами, які виконують різні ролі. У такому випадку поле `allowedRoutes` в `Gateway` буде налаштовано для вказівки просторів імен, де мають бути створені маршрути, замість очікування їх у тому ж просторі імен, що й `Gateway`, як у цьому прикладі.
{{< /tip >}}

Оскільки створення ресурсу Kubernetes `Gateway` також [виконає розгортання асоційованого проксі-сервісу](/docs/tasks/traffic-management/ingress/gateway-api/#automated-deployment), виконайте наступну команду, щоб дочекатися готовності шлюзу:

{{< text bash >}}
$ kubectl wait --for=condition=programmed gtw httpbin-gateway
{{< /text >}}

Налаштуйте маршрути для трафіку, що входить через `Gateway`:

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: httpbin
spec:
  parentRefs:
  - name: httpbin-gateway
  hostnames: ["httpbin.example.com"]
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /status
    - path:
        type: PathPrefix
        value: /delay
    backendRefs:
    - name: httpbin
      port: 8000
EOF
{{< /text >}}

Ви створили конфігурацію [HTTP Route](https://gateway-api.sigs.k8s.io/references/spec/#gateway.networking.k8s.io/v1.HTTPRoute) для сервісу `httpbin`, що містить два правила маршрутизації, які дозволяють трафік для шляхів `/status` та `/delay`.

{{< /tab >}}

{{< /tabset >}}

## Визначення IP-адреси та портів для вхідного трафіку {#determining-the-ingress-ip-and-ports}

Кожен `Gateway` підтримується [сервісом типу LoadBalancer](https://kubernetes.io/docs/tasks/access-application-cluster/create-external-load-balancer/). Зовнішня IP-адреса та порти навантажувача для цього сервісу використовуються для доступу до шлюзу. Сервіси Kubernetes типу `LoadBalancer` стандартно підтримуються у кластерах, що працюють на більшості хмарних платформ, але в деяких середовищах (наприклад, тестових) вам може знадобитися виконати наступні дії:

* `minikube` — запустіть зовнішній навантажувач, виконавши наступну команду в іншому терміналі:

    {{< text syntax=bash snip_id=minikube_tunnel >}}
    $ minikube tunnel
    {{< /text >}}

* `kind` — дотримуйтеся [посібника](https://kind.sigs.k8s.io/docs/user/loadbalancer/), щоб забезпечити роботу сервісів типу `LoadBalancer`.

* інші платформи — ви можете використовувати [MetalLB](https://metallb.universe.tf/installation/) для отримання `EXTERNAL-IP` для сервісів типу `LoadBalancer`.

Для зручності ми збережемо IP-адресу та порти для вхідного трафіку у змінних середовища, які будуть використовуватися в подальших інструкціях. Налаштуйте змінні середовища `INGRESS_HOST` та `INGRESS_PORT` відповідно до наступних інструкцій:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

Встановіть наступні змінні оточення на назву та простір імен, де знаходиться вхідний шлюз Istio у вашому кластері:

{{< text bash >}}
$ export INGRESS_NAME=istio-ingressgateway
$ export INGRESS_NS=istio-system
{{< /text >}}

{{< tip >}}
Якщо ви встановили Istio за допомогою Helm, назва вхідного шлюзу та простір імен будуть `istio-ingress`:

{{< text bash >}}
$ export INGRESS_NAME=istio-ingress
$ export INGRESS_NS=istio-ingress
{{< /text >}}

{{< /tip >}}

Запустіть наступну команду, щоб визначити, чи знаходиться ваш кластер Kubernetes в середовищі, яке підтримує зовнішні балансувальники навантаження:

{{< text bash >}}
$ kubectl get svc "$INGRESS_NAME" -n "$INGRESS_NS"
NAME                   TYPE           CLUSTER-IP       EXTERNAL-IP      PORT(S)   AGE
istio-ingressgateway   LoadBalancer   172.21.109.129   130.211.10.121   ...       17h
{{< /text >}}

Якщо встановлено значення `EXTERNAL-IP`, ваше середовище має зовнішнього балансувальника навантаження, який ви можете використовувати для вхідного шлюзу. Якщо значення `EXTERNAL-IP` дорівнює `<none>` (або постійно `<pending>`), у вашому середовищі не передбачено зовнішнього балансувальника навантаження для вхідного шлюзу.

Якщо ваше середовище не підтримує зовнішні балансувальники навантаження, ви можете спробувати [доступ до вхідного шлюзу за допомогою портів вузла](/docs/tasks/traffic-management/ingress/ingress-control/#using-node-ports-of-the-ingress-gateway-service). В іншому випадку, встановіть IP-адресу і порти вхідного шлюзу за допомогою наступних команд:

{{< text bash >}}
$ export INGRESS_HOST=$(kubectl -n "$INGRESS_NS" get service "$INGRESS_NAME" -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
$ export INGRESS_PORT=$(kubectl -n "$INGRESS_NS" get service "$INGRESS_NAME" -o jsonpath='{.spec.ports[?(@.name=="http2")].port}')
$ export SECURE_INGRESS_PORT=$(kubectl -n "$INGRESS_NS" get service "$INGRESS_NAME" -o jsonpath='{.spec.ports[?(@.name=="https")].port}')
$ export TCP_INGRESS_PORT=$(kubectl -n "$INGRESS_NS" get service "$INGRESS_NAME" -o jsonpath='{.spec.ports[?(@.name=="tcp")].port}')
{{< /text >}}

{{< warning >}}
У певних середовищах балансувальник навантаження може бути експонований за допомогою імені хосту, а не IP-адреси. У цьому випадку значенням `EXTERNAL-IP` вхідного шлюзу буде не IP-адреса, а імʼям хосту, і наведена вище команда не зможе встановити змінну оточення `INGRESS_HOST`. Скористайтеся наступною командою, щоб виправити значення `INGRESS_HOST`:

{{< text bash >}}
$ export INGRESS_HOST=$(kubectl -n "$INGRESS_NS" get service "$INGRESS_NAME" -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
{{< /text >}}

{{< /warning >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

Отримайте адресу та порт шлюзу з ресурсу шлюзу httpbin:

{{< text bash >}}
$ export INGRESS_HOST=$(kubectl get gtw httpbin-gateway -o jsonpath='{.status.addresses[0].value}')
$ export INGRESS_PORT=$(kubectl get gtw httpbin-gateway -o jsonpath='{.spec.listeners[?(@.name=="http")].port}')
{{< /text >}}

{{< tip >}}
Ви можете використовувати подібні команди для пошуку інших портів на будь-якому шлюзі. Наприклад, щоб отримати доступ до захищеного HTTP порт з імʼям `https` на шлюзі з імʼям `my-gateway`:

{{< text bash >}}
$ export INGRESS_HOST=$(kubectl get gtw my-gateway -o jsonpath='{.status.addresses[0].value}')
$ export SECURE_INGRESS_PORT=$(kubectl get gtw my-gateway -o jsonpath='{.spec.listeners[?(@.name=="https")].port}')
{{< /text >}}

{{< /tip >}}

{{< /tab >}}

{{< /tabset >}}

## Доступ до сервісів ingress {#accessing-ingress-services}

1.  Доступ до сервісу _httpbin_ за допомогою _curl_:

    {{< text bash >}}
    $ curl -s -I -HHost:httpbin.example.com "http://$INGRESS_HOST:$INGRESS_PORT/status/200"
    ...
    HTTP/1.1 200 OK
    ...
    server: istio-envoy
    ...
    {{< /text >}}

    Зверніть увагу, що ви використовуєте прапорець `-H`, щоб встановити HTTP-заголовок _Host_ на "httpbin.example.com". Це необхідно, оскільки ваш вхідний `Gateway` налаштовано на обробку "httpbin.example.com", але у вашому тестовому середовищі ви не маєте привʼязки DNS для цього хосту і просто надсилаєте запит на вхідний IP.

1.  Доступ до будь-якої іншої URL-адреси, яка не була відкрита явно. Ви побачите помилку HTTP 404:

    {{< text bash >}}
    $ curl -s -I -HHost:httpbin.example.com "http://$INGRESS_HOST:$INGRESS_PORT/headers"
    HTTP/1.1 404 Not Found
    ...
    {{< /text >}}

### Доступ до сервісів ingress за допомогою оглядача {#accessing-ingress-services-using-a-browser}

Введення URL сервісу `httpbin` у оглядачі не працюватиме, оскільки ви не можете передати заголовок _Host_ оглядачу так, як це зробили з `curl`. У реальній ситуації це не є проблемою, тому що ви налаштовуєте запитуваний хост правильно, і він доступний через DNS. Таким чином, ви використовуєте доменне ім’я хосту в URL, наприклад, `https://httpbin.example.com/status/200`.

Ви можете обійти цю проблему для простих тестів і демонстрацій наступним чином:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

Використовуйте значення універсального символу `*` для хосту в конфігураціях `Gateway` та `VirtualService`. Наприклад, змініть вашу конфігурацію для вхідного трафіку на наступну:

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1
kind: Gateway
metadata:
  name: httpbin-gateway
spec:
  # Селектор збігається з мітками podʼів ingress gateway.
  # Якщо ви встановили Istio за допомогою Helm, слідуючи стандартній документації, це буде "istio=ingress"
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "*"
---
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: httpbin
spec:
  hosts:
  - "*"
  gateways:
  - httpbin-gateway
  http:
  - match:
    - uri:
        prefix: /headers
    route:
    - destination:
        port:
          number: 8000
        host: httpbin
EOF
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

Якщо ви видалите імена хостів з конфігурацій `Gateway` і `HTTPRoute`, вони будуть застосовуватися до будь-якого запиту. Наприклад, змініть конфігурацію вхідних даних на наступну:

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: httpbin-gateway
spec:
  gatewayClassName: istio
  listeners:
  - name: http
    port: 80
    protocol: HTTP
    allowedRoutes:
      namespaces:
        from: Same
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: httpbin
spec:
  parentRefs:
  - name: httpbin-gateway
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /headers
    backendRefs:
    - name: httpbin
      port: 8000
EOF
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

Потім ви можете використовувати `$INGRESS_HOST:$INGRESS_PORT` в URL-адресі оглядача. Наприклад, `http://$INGRESS_HOST:$INGRESS_PORT/headers` покаже всі заголовки, які надсилає ваш оглядач.

## Розуміння того, що сталося {#understanding-what-happened}

Ресурси конфігурації `Gateway` дозволяють зовнішньому трафіку потрапляти до сервісної мережі Istio і надають можливість використовувати функції керування трафіком та політики Istio для граничних сервісів.

У попередніх кроках ви створили сервіс всередині сервісної мережі та експонували HTTP-точку доступу цього сервісу для зовнішнього трафіку.

## Використання NodePort сервісу ingress gateway {#using-node-ports-of-the-ingress-gateway-service}

{{< warning >}}
Ви не повинні використовувати ці інструкції, якщо у вашому середовищі Kubernetes є зовнішній навантажувач, який підтримує [сервіси типу LoadBalancer](https://kubernetes.io/docs/tasks/access-application-cluster/create-external-load-balancer/).
{{< /warning >}}

Якщо ваше середовище не підтримує зовнішні навантажувачі, ви все ще можете експериментувати з деякими функціями Istio, використовуючи [NodePort](https://kubernetes.io/docs/concepts/services-networking/service/#type-nodeport) сервісу `istio-ingressgateway`.

Налаштуйте порти для вхідного трафіку:

{{< text bash >}}
$ export INGRESS_PORT=$(kubectl -n "${INGRESS_NS}" get service "${INGRESS_NAME}" -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}')
$ export SECURE_INGRESS_PORT=$(kubectl -n "${INGRESS_NS}" get service "${INGRESS_NAME}" -o jsonpath='{.spec.ports[?(@.name=="https")].nodePort}')
$ export TCP_INGRESS_PORT=$(kubectl -n "${INGRESS_NS}" get service "${INGRESS_NAME}" -o jsonpath='{.spec.ports[?(@.name=="tcp")].nodePort}')
{{< /text >}}

Налаштування IP-адреси для вхідного трафіку залежить від постачальника кластера:

1.  _GKE:_

    {{< text bash >}}
    $ export INGRESS_HOST=worker-node-address
    {{< /text >}}

    Вам потрібно створити правила брандмауера для дозволу TCP-трафіку на порти сервісу _ingressgateway_. Виконайте наступні команди, щоб дозволити трафік для порту HTTP, захищеного порту (HTTPS) або обох:

    {{< text bash >}}
    $ gcloud compute firewall-rules create allow-gateway-http --allow "tcp:$INGRESS_PORT"
    $ gcloud compute firewall-rules create allow-gateway-https --allow "tcp:$SECURE_INGRESS_PORT"
    {{< /text >}}

1.  _IBM Cloud Kubernetes Service:_

    {{< text bash >}}
    $ ibmcloud ks workers --cluster cluster-name-or-id
    $ export INGRESS_HOST=public-IP-of-one-of-the-worker-nodes
    {{< /text >}}

1.  _Docker For Desktop:_

    {{< text bash >}}
    $ export INGRESS_HOST=127.0.0.1
    {{< /text >}}

1.  _Інші середовища:_

    {{< text bash >}}
    $ export INGRESS_HOST=$(kubectl get po -l istio=ingressgateway -n "${INGRESS_NS}" -o jsonpath='{.items[0].status.hostIP}')
    {{< /text >}}

## Розвʼязання проблем {#troubleshooting}

1.  Перевірте значення змінних середовища `INGRESS_HOST` та `INGRESS_PORT`. Переконайтеся, що вони мають дійсні значення відповідно до результатів наступних команд:

    {{< text bash >}}
    $ kubectl get svc -n istio-system
    $ echo "INGRESS_HOST=$INGRESS_HOST, INGRESS_PORT=$INGRESS_PORT"
    {{< /text >}}

1.  Перевірте, що у вас немає інших шлюзів Istio, які визначені на тому ж порту:

    {{< text bash >}}
    $ kubectl get gateway --all-namespaces
    {{< /text >}}

1.  Перевірте, що у вас немає ресурсів Kubernetes Ingress, які визначені на тій самій IP-адресі та порту:

    {{< text bash >}}
    $ kubectl get ingress --all-namespaces
    {{< /text >}}

1.  Якщо у вас є зовнішній навантажувач, і він не працює, спробуйте [отримати доступ до шлюзу, використовуючи його NodePort](/docs/tasks/traffic-management/ingress/ingress-control/#using-node-ports-of-the-ingress-gateway-service).

## Очищення {#cleanup}

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

Видаліть конфігурації `Gateway` та `VirtualService` та вимкніть службу [httpbin]({{< github_tree >}}/samples/httpbin):

{{< text bash >}}
$ kubectl delete gateway httpbin-gateway
$ kubectl delete virtualservice httpbin
$ kubectl delete --ignore-not-found=true -f @samples/httpbin/httpbin.yaml@
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

Видаліть конфігурації `Gateway` і `VirtualService` та вимкніть службу [httpbin]({{< github_tree >}}/samples/httpbin):

{{< text bash >}}
$ kubectl delete httproute httpbin
$ kubectl delete gtw httpbin-gateway
$ kubectl delete --ignore-not-found=true -f @samples/httpbin/httpbin.yaml@
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}
