---
title: Дзеркалювання
description: Це завдання демонструє можливості дзеркалювання/відтінювання трафіку в Istio.
weight: 60
keywords: [traffic-management,mirroring]
owner: istio/wg-networking-maintainers
test: yes
---
<!--
Please don't attempt to edit this page to change the indentation to fix the
examples. The indentation is correct, but the template rendering is wrong.
See the callout below.
-->

{{< warning >}}
Через [помилку в шаблоні коду веб-сайту Istio](https://github.com/istio/istio.io/issues/15689) приклади на цій сторінці не відображаються належним чином. Ви можете [переглянути джерело сторінки](https://raw.githubusercontent.com/istio/istio.io/master/content/en/docs/tasks/traffic-management/mirroring/index.md), щоб побачити правильні маніфести.
{{< /warning >}}

Це завдання демонструє можливості дзеркалювання трафіку в Istio.

Дзеркалювання трафіку, яке також називають тінізацією, - це потужна концепція, яка дозволяє командам розробників вносити зміни у операційну діяльність з якомога меншим ризиком. Дзеркалювання надсилає копію реального трафіку на дзеркальний сервіс. Віддзеркалений трафік потрапляє за межі діапазону критичного шляху запиту для основного сервісу.

У цьому завданні ви спочатку примусово перенаправите весь трафік на `v1` тестового сервісу. Потім ви застосуєте правило для дзеркалювання частини трафіку на `v2`.

{{< boilerplate gateway-api-support >}}

## Перш ніж почати {#before-you-begin}

1. Налаштуйте Istio, дотримуючись інструкцій у [керівництві з встановлення](/docs/setup/).
1. Почніть з розгортання двох версій сервісу [httpbin]({{< github_tree >}}/samples/httpbin) з увімкненим журналюванням доступу:

    1. Розгортання `httpbin-v1`:

        {{< text bash >}}
        $ kubectl create -f - <<EOF
        apiVersion: apps/v1
        kind: Deployment
        metadata:
          name: httpbin-v1
        spec:
          replicas: 1
          selector:
            matchLabels:
              app: httpbin
              version: v1
          template:
            metadata:
              labels:
                app: httpbin
                version: v1
            spec:
              containers:
              - image: docker.io/kennethreitz/httpbin
                imagePullPolicy: IfNotPresent
                name: httpbin
                command: ["gunicorn", "--access-logfile", "-", "-b", "0.0.0.0:80", "httpbin:app"]
                ports:
                - containerPort: 80
        EOF
        {{< /text >}}

    1. Розгортання `httpbin-v2`:

        {{< text bash >}}
        $ kubectl create -f - <<EOF
        apiVersion: apps/v1
        kind: Deployment
        metadata:
          name: httpbin-v2
        spec:
          replicas: 1
          selector:
            matchLabels:
              app: httpbin
              version: v2
          template:
            metadata:
              labels:
                app: httpbin
                version: v2
            spec:
              containers:
              - image: docker.io/kennethreitz/httpbin
                imagePullPolicy: IfNotPresent
                name: httpbin
                command: ["gunicorn", "--access-logfile", "-", "-b", "0.0.0.0:80", "httpbin:app"]
                ports:
                - containerPort: 80
        EOF
        {{< /text >}}

    2. Розгорніть `httpbin` сервіс Kubernetes:

        {{< text bash >}}
        $ kubectl create -f - <<EOF
        apiVersion: v1
        kind: Service
        metadata:
          name: httpbin
          labels:
            app: httpbin
        spec:
          ports:
          - name: http
            port: 8000
            targetPort: 80
          selector:
            app: httpbin
        EOF
        {{< /text >}}

2. Розгорніть `curl` навантаження, яке ви будете використовувати для надсилання запитів до сервісу `httpbin`:

    {{< text bash >}}
    $ cat <<EOF | kubectl create -f -
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: curl
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: curl
      template:
        metadata:
          labels:
            app: curl
        spec:
          containers:
          - name: curl
            image: curlimages/curl
            command: ["/bin/sleep","3650d"]
            imagePullPolicy: IfNotPresent
    EOF
    {{< /text >}}

## Створення стандартної політики маршрутизації {#creating-a-default-routing-policy}

Стандартно Kubernetes балансує навантаження між обома версіями служби `httpbin`. У цьому кроці ви зміните цю поведінку так, щоб весь трафік йшов до `v1`.

1. Створіть стандартне правило маршрутизації, щоб спрямовувати весь трафік до `v1` сервісу:

    {{< tabset category-name="config-api" >}}

    {{< tab name="Istio APIs" category-value="istio-apis" >}}

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1
    kind: VirtualService
    metadata:
      name: httpbin
    spec:
      hosts:
        - httpbin
      http:
      - route:
        - destination:
            host: httpbin
            subset: v1
          weight: 100
    ---
    apiVersion: networking.istio.io/v1
    kind: DestinationRule
    metadata:
      name: httpbin
    spec:
      host: httpbin
      subsets:
      - name: v1
        labels:
          version: v1
      - name: v2
        labels:
          version: v2
    EOF
    {{< /text >}}

    {{< /tab >}}

    {{< tab name="Gateway API" category-value="gateway-api" >}}

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: v1
    kind: Service
    metadata:
      name: httpbin-v1
    spec:
      ports:
      - port: 80
        name: http
      selector:
        app: httpbin
        version: v1
    ---
    apiVersion: v1
    kind: Service
    metadata:
      name: httpbin-v2
    spec:
      ports:
      - port: 80
        name: http
      selector:
        app: httpbin
        version: v2
    ---
    apiVersion: gateway.networking.k8s.io/v1
    kind: HTTPRoute
    metadata:
      name: httpbin
    spec:
      parentRefs:
      - group: ""
        kind: Service
        name: httpbin
        port: 8000
      rules:
      - backendRefs:
        - name: httpbin-v1
          port: 80
    EOF
    {{< /text >}}

    {{< /tab >}}

    {{< /tabset >}}

1. Тепер, спрямувавши весь трафік на `httpbin:v1`, надішліть запит до сервісу:

    {{< text bash json >}}
    $ kubectl exec deploy/curl -c curl -- curl -sS http://httpbin:8000/headers
    {
      "headers": {
        "Accept": "*/*",
        "Content-Length": "0",
        "Host": "httpbin:8000",
        "User-Agent": "curl/7.35.0",
        "X-B3-Parentspanid": "57784f8bff90ae0b",
        "X-B3-Sampled": "1",
        "X-B3-Spanid": "3289ae7257c3f159",
        "X-B3-Traceid": "b56eebd279a76f0b57784f8bff90ae0b",
        "X-Envoy-Attempt-Count": "1",
        "X-Forwarded-Client-Cert": "By=spiffe://cluster.local/ns/default/sa/default;Hash=20afebed6da091c850264cc751b8c9306abac02993f80bdb76282237422bd098;Subject=\"\";URI=spiffe://cluster.local/ns/default/sa/default"
      }
    }
    {{< /text >}}

1. Перевірте логи podʼів `httpbin-v1` і `httpbin-v2`. Ви повинні побачити записи журналу доступу для `v1` і жодного для `v2`:

    {{< text bash >}}
    $ kubectl logs deploy/httpbin-v1 -c httpbin
    127.0.0.1 - - [07/Mar/2018:19:02:43 +0000] "GET /headers HTTP/1.1" 200 321 "-" "curl/7.35.0"
    {{< /text >}}

    {{< text bash >}}
    $ kubectl logs deploy/httpbin-v2 -c httpbin
    <none>
    {{< /text >}}

## Дзеркалювання трафіку до `httpbin-v2` {#mirroring-traffic-to-httpbin-v2}

1. Змініть правило маршруту для дзеркалювання трафіку до `httpbin-v2`:

    {{< tabset category-name="config-api" >}}

    {{< tab name="Istio APIs" category-value="istio-apis" >}}

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1
    kind: VirtualService
    metadata:
      name: httpbin
    spec:
      hosts:
        - httpbin
      http:
      - route:
        - destination:
            host: httpbin
            subset: v1
          weight: 100
        mirror:
          host: httpbin
          subset: v2
        mirrorPercentage:
          value: 100.0
    EOF
    {{< /text >}}

    Це правило маршрутизації надсилає 100\% трафіку до `v1`. Останній блок вказує, що ви хочете дзеркалювати (тобто, також надсилати) 100\% того ж трафіку до сервісу `httpbin:v2`. Коли трафік дзеркалюється, запити надсилаються до дзеркального сервісу з їх заголовками Host/Authority, доповненими суфіксом `-shadow`. Наприклад, `cluster-1` стає `cluster-1-shadow`.

    Також важливо зазначити, що ці запити показуються як "запустити та забути", що означає, що відповіді скидаються.

    Ви можете використовувати поле `value` в полі `mirrorPercentage` для віддзеркалення частини трафіку замість віддзеркалення всіх запитів. Якщо це поле відсутнє, весь трафік буде віддзеркалюватись.

    {{< /tab >}}

    {{< tab name="Gateway API" category-value="gateway-api" >}}

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: gateway.networking.k8s.io/v1
    kind: HTTPRoute
    metadata:
      name: httpbin
    spec:
      parentRefs:
      - group: ""
        kind: Service
        name: httpbin
        port: 8000
      rules:
      - filters:
        - type: RequestMirror
          requestMirror:
            backendRef:
              name: httpbin-v2
              port: 80
        backendRefs:
        - name: httpbin-v1
          port: 80
    EOF
    {{< /text >}}

    Це правило маршрутизації надсилає 100% трафіку до `v1`. Фільтр `RequestMirror` вказує, що ви хочете віддзеркалювати (тобто, також надсилати) 100% того ж трафіку до сервісу `httpbin:v2`. Коли трафік віддзеркалюється, запити надсилаються до дзеркального сервісу з їх заголовками Host/Authority, доповненими суфіксом `-shadow`. Наприклад, `cluster-1` стає `cluster-1-shadow`.

    Також важливо зазначити, що ці запити віддзеркалюються як "запустити та забути", що означає, що відповіді скидаються.

    {{< /tab >}}

    {{< /tabset >}}

1. Надішліть трафік:

    {{< text bash >}}
    $ kubectl exec deploy/curl -c curl -- curl -sS http://httpbin:8000/headers
    {{< /text >}}

    Тепер ви повинні побачити журнали доступу як для `v1`, так і для `v2`. Журнали доступу, створені в `v2`, є віддзеркаленням запитів, які насправді надходять до `v1`.

    {{< text bash >}}
    $ kubectl logs deploy/httpbin-v1 -c httpbin
    127.0.0.1 - - [07/Mar/2018:19:02:43 +0000] "GET /headers HTTP/1.1" 200 321 "-" "curl/7.35.0"
    127.0.0.1 - - [07/Mar/2018:19:26:44 +0000] "GET /headers HTTP/1.1" 200 321 "-" "curl/7.35.0"
    {{< /text >}}

    {{< text bash >}}
    $ kubectl logs deploy/httpbin-v2 -c httpbin
    127.0.0.1 - - [07/Mar/2018:19:26:44 +0000] "GET /headers HTTP/1.1" 200 361 "-" "curl/7.35.0"
    {{< /text >}}

## Очищення {#cleaning-up}

1. Вилучіть правило:

    {{< tabset category-name="config-api" >}}

    {{< tab name="Istio APIs" category-value="istio-apis" >}}

    {{< text bash >}}
    $ kubectl delete virtualservice httpbin
    $ kubectl delete destinationrule httpbin
    {{< /text >}}

    {{< /tab >}}

    {{< tab name="Gateway API" category-value="gateway-api" >}}

    {{< text bash >}}
    $ kubectl delete httproute httpbin
    $ kubectl delete svc httpbin-v1 httpbin-v2
    {{< /text >}}

    {{< /tab >}}

    {{< /tabset >}}

1. Вилучіть розгортання `httpbin` та `curl` та сервіс `httpbin` service:

    {{< text bash >}}
    $ kubectl delete deploy httpbin-v1 httpbin-v2 curl
    $ kubectl delete svc httpbin
    {{< /text >}}
