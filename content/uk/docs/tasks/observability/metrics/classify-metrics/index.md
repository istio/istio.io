---
title: Класифікація метрик на основі запиту або відповіді
description: Це завдання показує, як покращити телеметрію, групуючи запити та відповіді за їхніми типами.
weight: 27
keywords: [telemetry,metrics,classify,request-based,openapispec,swagger]
owner: istio/wg-policies-and-telemetry-maintainers
test: no
---

Корисно візуалізувати телеметрію на основі типу запитів і відповідей, які обробляють служби у вашій мережі. Наприклад, книготорговець відстежує кількість запитів на перегляд книг. Запит на перегляд книги має таку структуру:

{{< text plain >}}
GET /reviews/{review_id}
{{< /text >}}

Підрахунок кількості запитів на перегляд повинен враховувати невизначений елемент `review_id`. `GET /reviews/1`, з наступним `GET /reviews/2` слід рахувати як два запити на перегляд.

Istio дозволяє створювати правила класифікації за допомогою втулку AttributeGen, який групує запити в фіксовану кількість логічних операцій. Наприклад, ви можете створити операцію з назвою `GetReviews`, що є поширеним способом ідентифікації операцій за допомогою [`Open API Spec operationId`](https://swagger.io/docs/specification/paths-and-operations/). Ця інформація вставляється в обробку запитів як атрибут `istio_operationId` зі значенням, що дорівнює `GetReviews`. Ви можете використовувати цей атрибут як вимір у стандартних метриках Istio. Аналогічно, ви можете відстежувати метрики на основі інших операцій, таких як `ListReviews` і `CreateReviews`.

## Класифікація метрик за запитом {#classify-metrics-by-request}

Ви можете класифікувати запити на основі їх типу, наприклад, `ListReview`, `GetReview`, `CreateReview`.

1. Створіть файл, наприклад `attribute_gen_service.yaml`, і збережіть його з таким вмістом. Це додає втулок `istio.attributegen`. Також створюється атрибут `istio_operationId` і заповнюється значеннями для категорій, які слід рахувати як метрики.

    Ця конфігурація є специфічною для конкретного сервісу, оскільки шляхи запитів зазвичай залежать від сервісу.

    {{< text yaml >}}
apiVersion: extensions.istio.io/v1alpha1
kind: WasmPlugin
metadata:
  name: istio-attributegen-filter
spec:
  selector:
    matchLabels:
      app: reviews
  url: https://storage.googleapis.com/istio-build/proxy/attributegen-359dcd3a19f109c50e97517fe6b1e2676e870c4d.wasm
  imagePullPolicy: Always
  phase: AUTHN
  pluginConfig:
    attributes:
    - output_attribute: "istio_operationId"
      match:
        - value: "ListReviews"
          condition: "request.url_path == '/reviews' && request.method == 'GET'"
        - value: "GetReview"
          condition: "request.url_path.matches('^/reviews/[[:alnum:]]*$') && request.method == 'GET'"
        - value: "CreateReview"
          condition: "request.url_path == '/reviews/' && request.method == 'POST'"
---
apiVersion: telemetry.istio.io/v1
kind: Telemetry
metadata:
  name: custom-tags
spec:
  metrics:
    - overrides:
        - match:
            metric: REQUEST_COUNT
            mode: CLIENT_AND_SERVER
          tagOverrides:
            request_operation:
              value: istio_operationId
      providers:
        - name: prometheus
    {{< /text >}}

1. Застосуйте ваші зміни за допомогою наступної команди:

    {{< text bash >}}
    $ kubectl -n istio-system apply -f attribute_gen_service.yaml
    {{< /text >}}

1. Після того, як зміни наберуть чинності, відвідайте Prometheus і знайдіть нові або змінені вимірювання, наприклад, `istio_requests_total` у podʼах `reviews`.

## Класифікація метрик за відповіддю {#classify-metrics-by-response}

Ви можете класифікувати відповіді, використовуючи подібний процес до запитів. Зверніть увагу, що вимір `response_code` вже стандартно існує. У прикладі нижче змінюється спосіб його заповнення.

1. Створіть файл, наприклад `attribute_gen_service.yaml`, і збережіть його з таким вмістом. Це додає втулок `istio.attributegen` і генерує атрибут `istio_responseClass`, який використовується втулком статистики.

    У цьому прикладі класифікуються різні відповіді, наприклад, групування всіх кодів відповіді в діапазоні `200` як вимір `2xx`.

    {{< text yaml >}}
apiVersion: extensions.istio.io/v1alpha1
kind: WasmPlugin
metadata:
  name: istio-attributegen-filter
spec:
  selector:
    matchLabels:
      app: productpage
  url: https://storage.googleapis.com/istio-build/proxy/attributegen-359dcd3a19f109c50e97517fe6b1e2676e870c4d.wasm
  imagePullPolicy: Always
  phase: AUTHN
  pluginConfig:
    attributes:
      - output_attribute: istio_responseClass
        match:
          - value: 2xx
            condition: response.code >= 200 && response.code <= 299
          - value: 3xx
            condition: response.code >= 300 && response.code <= 399
          - value: "404"
            condition: response.code == 404
          - value: "429"
            condition: response.code == 429
          - value: "503"
            condition: response.code == 503
          - value: 5xx
            condition: response.code >= 500 && response.code <= 599
          - value: 4xx
            condition: response.code >= 400 && response.code <= 499
---
apiVersion: telemetry.istio.io/v1
kind: Telemetry
metadata:
  name: custom-tags
spec:
  metrics:
    - overrides:
        - match:
            metric: REQUEST_COUNT
            mode: CLIENT_AND_SERVER
          tagOverrides:
            response_code:
              value: istio_responseClass
      providers:
        - name: prometheus
    {{< /text >}}

1. Застосуйте ваші зміни за допомогою наступної команди:

    {{< text bash >}}
    $ kubectl -n istio-system apply -f attribute_gen_service.yaml
    {{< /text >}}

## Перевірка результатів {#verify-the-results}

1. Генеруйте метрики, надсилаючи трафік до вашого застосунку.

1. Відвідайте Prometheus і знайдіть нові або змінені вимірювання, наприклад, `2xx`. Альтернативно, використовуйте наступну команду, щоб перевірити, що Istio генерує дані для вашого нового вимірювання:

    {{< text bash >}}
    $ kubectl exec pod-name -c istio-proxy -- curl -sS 'localhost:15000/stats/prometheus' | grep istio_
    {{< /text >}}

    У виході знайдіть метрику (наприклад, `istio_requests_total`) і перевірте наявність нового або зміненого вимірювання.

## Усунення неполадок {#troubleshooting}

Якщо класифікація не відбувається, як очікувалося, перевірте наступні потенційні причини та рішення.

Перегляньте журнали проксі Envoy для podʼа, на якому застосовано зміни конфігурації служби. Переконайтеся, що немає помилок, про які повідомляє служба в журналах проксі Envoy у pod (`pod-name`), де ви налаштували класифікацію, використовуючи наступну команду:

{{< text bash >}}
$ kubectl logs pod-name -c istio-proxy | grep -e "Config Error" -e "envoy wasm"
{{< /text >}}

Крім того, переконайтеся, що немає крахів проксі Envoy, шукаючи ознаки перезапусків у виході наступної команди:

{{< text bash >}}
$ kubectl get pods pod-name
{{< /text >}}

## Очищення {#cleanup}

Видаліть файл конфігурації YAML.

{{< text bash >}}
$ kubectl -n istio-system delete -f attribute_gen_service.yaml
{{< /text >}}
