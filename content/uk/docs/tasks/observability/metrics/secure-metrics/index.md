---
title: Захист збору метрик Prometheus для sidecar і шлюзів Istio
description: Це завдання показує, як безпечно збирати метрики робочих навантажень і шлюзів Istio в режимі sidecar за допомогою Prometheus і взаємного TLS (mTLS) Istio.
weight: 50
keywords: [telemetry,metrics,prometheus,istio,mtls,secure-metrics]
owner: istio/wg-policies-and-telemetry-maintainers
test: yes
---

Це завдання демонструє, як **безпечно збирати метрики sidecar і шлюзів Istio** за допомогою Prometheus через **Istio mTLS**. Типово Prometheus збирає метрики з робочих навантажень і шлюзів Istio через звичайний HTTP. У цьому завданні ви налаштовуєте Istio та Prometheus так, щоб метрики збиралися безпечно через взаємно автентифіковані TLS-зʼєднання. Цей документ зосереджується на телеметрії, створеній Envoy та Istio, яку експонують sidecar і шлюзи. Щодо загальної інтеграції Prometheus з Istio, включно з метриками застосунків, дивіться документацію [інтеграції Prometheus](/docs/ops/integrations/prometheus/).

{{< tip >}}
Починаючи з Istio 1.31, захищені порти метрик mTLS можна вмикати рідним способом. Для старіших версій Istio дивіться розділ [застарілий обхідний шлях](#legacy-workaround-istio--131).
{{< /tip >}}

## Розуміння типового збору метрик {#understand-default-metrics-scraping}

Як правило, Istio надає доступ до метрик через точку доступу `/stats/prometheus`:

* Метрики робочих навантажень надаються через порт телеметрії sidecar (`15020`) або порт, призначений виключно для Envoy (`15090`).
* Метрики шлюзу надаються через порт телеметрії пoда шлюзу.
* Ці точки доступу **не захищені взаємним TLS**, тому не рекомендується здійснювати збір даних безпосередньо через HTTPS.

Підхід у цьому завданні додає виділені прослуховувачі, захищені mTLS, щоб Prometheus збирав метрики через зашифроване, взаємно автентифіковане зʼєднання.

## Перед початком {#before-you-begin}

* [Встановіть Istio](/docs/setup) у своєму кластері з використанням **типового профілю**.

## Налаштування Prometheus для збору метрик через mTLS {#configure-prometheus-for-mtls-scraping}

Prometheus має надавати дійсний сертифікат, якому довіряє CA мережі, під час збору даних з захищених портів. Найпростіший спосіб надати ці облікові дані — впровадити sidecar Istio в pod Prometheus і використати `OUTPUT_CERTS`, щоб записати сертифікат робочого навантаження у спільний том.

Приклад `prometheus-secure-metrics` (`samples/addons/extras/prometheus-secure-metrics.yaml`) — це автономна заміна для `samples/addons/prometheus.yaml` з впровадженням sidecar, експортом сертифікатів і попередньо налаштованими завданнями збору через mTLS.

1. Розгорніть Prometheus із попередньо налаштованим збором через mTLS:

    {{< text bash >}}
    $ kubectl apply -n istio-system -f @samples/addons/extras/prometheus-secure-metrics.yaml@
    $ kubectl rollout status deployment/prometheus -n istio-system
    {{< /text >}}

    Приклад налаштовує наступні ключові параметри порівняно зі стандартною надбудовою Prometheus:

    * **мітка** `sidecar.istio.io/inject: "true"` — перевизначає типове значення `"false"` на podʼі Prometheus, увімкнувши інʼєкцію sidecar.
    * `OUTPUT_CERTS: /etc/istio-certs` — вказує sidecar записувати сертифікат робочого навантаження, ключ і кореневий CA у спільний том, щоб Prometheus міг читати їх для збору через mTLS.
    * `INBOUND_CAPTURE_PORTS: ""` — запобігає перехопленню sidecar вхідного трафіку Prometheus; sidecar використовується виключно для надання сертифікатів.
    * `sidecar.istio.io/userVolumeMount` — монтує том сертифікатів у контейнер `istio-proxy`, щоб він міг записувати сертифікати. Той самий том також монтується в `prometheus-server`, щоб він міг їх читати. Обидва монтування є обовʼязковими.
    * **Завдання збору** — ConfigMap містить два попередньо налаштовані завдання збору даних через mTLS (`istio-secure-merged-metrics` на порту `15092`, `istio-secure-envoy-metrics` на порту `15091`), які виявляють podʼи через анотації `prometheus.istio.io/secure-port` і `prometheus.istio.io/secure-envoy-port`.

    {{< tip >}}
    Як альтернативу наданню сертифікатів на основі sidecar, Istio можна інтегрувати з [cert-manager](/docs/ops/integrations/certmanager/) для надання сертифікатів для Prometheus. У цій моделі sidecar Istio не потрібен.
    {{< /tip >}}

1. Перевірте, що pod Prometheus має впроваджений sidecar Istio та працює:

    {{< text bash >}}
    $ kubectl get pod -n istio-system -l app.kubernetes.io/name=prometheus
    NAME                          READY   STATUS    RESTARTS   AGE
    prometheus-6c647c84c8-gpxt4   3/3     Running   0          75s
    {{< /text >}}

## Увімкнення рідних портів метрик mTLS (Istio 1.31+) {#enable-native-mtls-metrics-ports-istio-131}

У версії Istio 1.31 було введено дві змінні середовища, які вбудовують захищені mTLS статичні прослуховувачі завантаження безпосередньо в кожен проксі-сервер Envoy — як проксі sidecar, так і gateway:

| Змінна | Типове значення | Опис |
| -------- | ------- | ----------- |
| `ENVOY_SECURE_METRICS_PORT` | `0` (вимкнено) | Додає прослуховувача mTLS, який проксіює до порту статистики лише Envoy (`15090`) |
| `ENVOY_SECURE_MERGED_METRICS_PORT` | `0` (вимкнено) | Додає прослуховувача mTLS, який проксіює до порту обʼєднаних метрик (`15020`, включає статистику застосунку та агента) |

Коли вони встановлені, Envoy додає налаштовані прослуховувачі під час початкового завантаження. Збирачі мають надавати сертифікат, якому довіряє CA мережі; це може бути сертифікат робочого навантаження Istio (як надано вище) або будь-який сертифікат, виданий довіреним CA, таким як cert-manager.

### Увімкнення на робочому навантаженні sidecar {#enable-on-a-sidecar-workload}

Цей приклад використовує `httpbin` як робоче навантаження. Маніфест нижче базується на прикладі [httpbin]({{< github_tree >}}/samples/httpbin) з доданими анотаціями захищених метрик до Deployment.

1. Розгорніть `httpbin` з увімкненими портами захищених метрик:

    {{< text bash >}}
    $ kubectl label namespace default istio-injection=enabled --overwrite
    $ kubectl apply -f - <<EOF
    apiVersion: v1
    kind: ServiceAccount
    metadata:
      name: httpbin
    ---
    apiVersion: v1
    kind: Service
    metadata:
      name: httpbin
      labels:
        app: httpbin
        service: httpbin
    spec:
      ports:
      - name: http
        port: 8000
        targetPort: 8080
      selector:
        app: httpbin
    ---
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: httpbin
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
          annotations:
            proxy.istio.io/config: |
              proxyMetadata:
                ENVOY_SECURE_METRICS_PORT: "15091"
                ENVOY_SECURE_MERGED_METRICS_PORT: "15092"
            prometheus.io/path: "/stats/prometheus"
        spec:
          serviceAccountName: httpbin
          containers:
          - image: docker.io/mccutchen/go-httpbin:v2.15.0
            imagePullPolicy: IfNotPresent
            name: httpbin
            ports:
            - containerPort: 8080
    EOF
    {{< /text >}}

    * `ENVOY_SECURE_METRICS_PORT` (`15091`) — це порт прослуховувача mTLS для статистики **лише Envoy**.
    * `ENVOY_SECURE_MERGED_METRICS_PORT` (`15092`) — це порт прослуховувача mTLS для **обʼєднаних** метрик (Envoy + застосунок + агент).

1. Встановіть змінні середовища, які використовуються в наступних кроках перевірки:

    {{< text bash >}}
    $ export HTTPBIN_POD=$(kubectl get pod -n default -l app=httpbin -o jsonpath='{.items[0].metadata.name}')
    $ export HTTPBIN_IP=$(kubectl get pod -n default -l app=httpbin -o jsonpath='{.items[0].status.podIP}')
    $ export PROM_POD=$(kubectl get pod -n istio-system -l app.kubernetes.io/name=prometheus -o jsonpath='{.items[0].metadata.name}')
    {{< /text >}}

1. Перевірте, що захищені прослуховувачі налаштовані на sidecar `httpbin`:

    {{< text bash >}}
    $ istioctl proxy-config listeners "$HTTPBIN_POD" -n default | grep -E "15090|15091|15092"
    0.0.0.0       15090 ALL                                                                                     Inline Route: /stats/prometheus*
    0.0.0.0       15091 Trans: tls                                                                              Inline Route: /stats/prometheus*
    0.0.0.0       15092 Trans: tls                                                                              Inline Route: /stats/prometheus*, /metrics*
    {{< /text >}}

    `Trans: tls` на портах `15091` і `15092` підтверджує, що прослуховувачі mTLS активні.

### Увімкнення на шлюзі {#enable-on-a-gateway}

Ті самі змінні працюють однаково на проксі шлюзів, оскільки вони використовують той самий шлях початкового завантаження `pilot-agent`.

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

1. Виправте Deployment вхідного шлюзу:

    {{< text bash >}}
    $ cat <<EOF > /tmp/gateway-secure-metrics-patch.yaml
    spec:
      template:
        metadata:
          annotations:
            prometheus.istio.io/secure-port: "15092"
            prometheus.io/path: "/stats/prometheus"
        spec:
          containers:
          - name: istio-proxy
            env:
            - name: ENVOY_SECURE_METRICS_PORT
              value: "15091"
            - name: ENVOY_SECURE_MERGED_METRICS_PORT
              value: "15092"
    EOF
    $ kubectl patch deployment istio-ingressgateway -n istio-system --type=strategic --patch-file=/tmp/gateway-secure-metrics-patch.yaml
    $ kubectl rollout status deployment/istio-ingressgateway -n istio-system
    {{< /text >}}

1. Перевірте, що захищені прослуховувачі налаштовані на вхідному шлюзі:

    {{< text bash >}}
    $ export GW_POD=$(kubectl get pod -n istio-system -l app=istio-ingressgateway -o jsonpath='{.items[0].metadata.name}')
    $ istioctl proxy-config listeners "$GW_POD" -n istio-system | grep -E "15090|15091|15092"
    0.0.0.0   15090 ALL        Inline Route: /stats/prometheus*
    0.0.0.0   15091 Trans: tls Inline Route: /stats/prometheus*
    0.0.0.0   15092 Trans: tls Inline Route: /stats/prometheus*, /metrics*
    {{< /text >}}

    `Trans: tls` на портах `15091` і `15092` підтверджує, що прослуховувачі mTLS активні на шлюзі.

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

1. Виправте ресурс `Gateway`, щоб увімкнути захищені прослуховувачі:

    {{< text bash >}}
    $ cat <<EOF > /tmp/gateway-api-secure-metrics-patch.yaml
    spec:
      infrastructure:
        annotations:
          proxy.istio.io/config: |
            proxyMetadata:
              ENVOY_SECURE_METRICS_PORT: "15091"
              ENVOY_SECURE_MERGED_METRICS_PORT: "15092"
          prometheus.istio.io/secure-port: "15092"
          prometheus.io/path: "/stats/prometheus"
    EOF
    $ kubectl patch gateway istio-ingressgateway -n istio-system --type=merge --patch-file=/tmp/gateway-api-secure-metrics-patch.yaml
    {{< /text >}}

1. Перевірте, що захищені прослуховувачі налаштовані на podʼі шлюзу:

    {{< text bash >}}
    $ export GW_POD=$(kubectl get pod -n istio-system -l gateway.networking.k8s.io/gateway-name=istio-ingressgateway -o jsonpath='{.items[0].metadata.name}')
    $ istioctl proxy-config listeners "$GW_POD" -n istio-system | grep -E "15090|15091|15092"
    0.0.0.0   15090 ALL        Inline Route: /stats/prometheus*
    0.0.0.0   15091 Trans: tls Inline Route: /stats/prometheus*
    0.0.0.0   15092 Trans: tls Inline Route: /stats/prometheus*, /metrics*
    {{< /text >}}

    `Trans: tls` на портах `15091` і `15092` підтверджує, що прослуховувачі mTLS активні на шлюзі.

{{< /tab >}}

{{< /tabset >}}

### Повністю посилена конфігурація {#fully-hardened-setup}

Для повністю посиленого розгортання поєднайте захищені порти з `METRICS_LOCALHOST_ACCESS_ONLY`. Це обмежує базові порти відкритого тексту (`15090` і `15020`) localhost, роблячи прослуховувачі mTLS **єдиною** зовнішньо доступною поверхнею збору:

{{< text bash >}}
$ cat <<EOF > /tmp/httpbin-hardened-patch.yaml
spec:
  template:
    metadata:
      annotations:
        proxy.istio.io/config: |
          proxyMetadata:
            ENVOY_SECURE_METRICS_PORT: "15091"
            ENVOY_SECURE_MERGED_METRICS_PORT: "15092"
            METRICS_LOCALHOST_ACCESS_ONLY: "true"
        prometheus.io/path: "/stats/prometheus"
EOF
$ kubectl patch deployment httpbin -n default --type=merge --patch-file=/tmp/httpbin-hardened-patch.yaml
{{< /text >}}

{{< warning >}}
Після встановлення `METRICS_LOCALHOST_ACCESS_ONLY` прямий HTTP-доступ до портів `15090` і `15020` ззовні podʼа блокується. Переконайтеся, що Prometheus налаштований на збір через порти mTLS перед застосуванням цього параметра.
{{< /warning >}}

{{< tip >}}
Щоб застосувати ці параметри до всієї мережі без виправлення окремих Deployment, використовуйте `IstioOperator` під час встановлення:

{{< text bash >}}
$ cat <<EOF > ./istio-secure-metrics.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    defaultConfig:
      proxyMetadata:
        ENVOY_SECURE_METRICS_PORT: "15091"
        ENVOY_SECURE_MERGED_METRICS_PORT: "15092"
        METRICS_LOCALHOST_ACCESS_ONLY: "true"
  components:
    ingressGateways:
    - name: istio-ingressgateway
      enabled: true
      k8s:
        podAnnotations:
          prometheus.istio.io/secure-port: "15092"
          prometheus.io/path: "/stats/prometheus"
EOF
$ istioctl install -f ./istio-secure-metrics.yaml
{{< /text >}}

Під час встановлення таким способом `istioctl` відображає Deployment шлюзу зі значеннями `proxyMetadata` безпосередньо як змінні середовища контейнера, активуючи захищені прослуховувачі як на sidecar, так і на шлюзах. Блок `components.ingressGateways.k8s.podAnnotations` додає анотації виявлення Prometheus до podʼів шлюзів. Для робочих навантажень sidecar `prometheus.istio.io/secure-port` автоматично встановлюється інжектором sidecar у значення `ENVOY_SECURE_MERGED_METRICS_PORT` — жодна анотація для окремого Deployment не потрібна.
{{< /tip >}}

## Перевірка {#verification}

### Перевірка захищеного збору метрик за допомогою Prometheus {#verify-secure-metrics-scraping-with-prometheus}

Після завершення конфігурації перевірте, що Prometheus успішно збирає метрики через **взаємний TLS**.

1. Перевірте, що збір через mTLS працює, виконавши curl до захищеного порту з podʼа Prometheus, використовуючи його сертифікат робочого навантаження:

    {{< text bash >}}
    $ kubectl exec -n istio-system "$PROM_POD" -c istio-proxy -- \
        curl -s -o /dev/null -w "%{http_code}" --max-time 5 \
        --cacert /etc/istio-certs/root-cert.pem \
        --cert /etc/istio-certs/cert-chain.pem \
        --key /etc/istio-certs/key.pem \
        --insecure \
        https://"$HTTPBIN_IP":15092/stats/prometheus
    200
    {{< /text >}}

    Відповідь HTTP `200` підтверджує, що pod Prometheus успішно виконав рукостискання mTLS з портом `15092` httpbin і отримав метрики. Прапорець `--insecure` пропускає лише перевірку імені хосту — сертифікати робочих навантажень Istio використовують URI SAN SPIFFE (наприклад, `spiffe://cluster.local/ns/default/sa/httpbin`), а не IP-адреси, тому curl не може зіставити IP podʼа з сертифікатом. Рукостискання взаємного TLS та обмін сертифікатами все одно відбуваються, саме тому `--cacert`, `--cert` і `--key` все ще обовʼязкові. Це також причина, чому завдання збору Prometheus використовує `insecure_skip_verify: true`.

1. Перевірте цілі збору в інтерфейсі Prometheus

    Відкрийте дашборд Prometheus за допомогою `istioctl dashboard prometheus -n istio-system`, потім перейдіть до **Status → Targets**. Перевірте, що завдання `istio-secure-merged-metrics` і `istio-secure-envoy-metrics` перелічують pod `httpbin` зі статусом **UP** і точками доступу у вигляді `https://<pod-ip>:15092/stats/prometheus`.

1. Перевірте, що mTLS застосовується, підтвердивши, що звичайний HTTP-запит до захищеного порту відхиляється:

    {{< text bash >}}
    $ kubectl exec -n default "$HTTPBIN_POD" -c istio-proxy -- curl -s --max-time 3 http://"$HTTPBIN_IP":15091/stats/prometheus
    upstream connect error or disconnect/reset before headers. reset reason: connection termination
    {{< /text >}}

    Помилка завершення зʼєднання підтверджує, що порт приймає лише TLS-зʼєднання — звичайний HTTP-запит відхиляється негайно.

Це підтверджує, що Prometheus збирає метрики за допомогою **HTTPS через Istio mTLS** через рідні захищені порти, а не отримує прямий доступ до портів телеметрії відкритого тексту (`15020` або `15090`).

## Очищення {#cleanup}

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text syntax=bash snip_id=none >}}
$ kubectl delete -n istio-system -f @samples/addons/extras/prometheus-secure-metrics.yaml@
$ kubectl delete -f @samples/httpbin/httpbin.yaml@
$ kubectl label namespace default istio-injection-
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl delete -n istio-system -f @samples/addons/extras/prometheus-secure-metrics.yaml@
$ kubectl delete -f @samples/httpbin/httpbin.yaml@
$ kubectl delete gateway istio-ingressgateway -n istio-system
$ kubectl label namespace default istio-injection-
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

## Застарілий обхідний шлях (Istio < 1.31) {#legacy-workaround-istio--131}

Якщо ви запускаєте Istio старіший за 1.31, рідний підхід на основі змінних середовища недоступний. Кроки нижче демонструють один із способів досягнення захищеного збору метрик за допомогою CRD Istio: захищений TLS-фронтенд створюється на порту `15091` (відкритий для Prometheus), який маршрутизує всередину або на порт `15020` (обʼєднані метрики — Envoy + застосунок + агент), або на `15090` (метрики лише Envoy). Збирачі підключаються до `15091` через TLS `ISTIO_MUTUAL`; `ServiceEntry` і `VirtualService` обробляють внутрішню маршрутизацію до бекенду відкритого тексту.

### Застарілий: захищені метрики для sidecar {#legacy-secure-metrics-for-sidecars}

1. Розгорніть `httpbin` і створіть ресурс `Sidecar` із захищеним вхідним слухачем на порту `15091`:

    {{< text bash >}}
    $ kubectl label namespace default istio-injection=enabled --overwrite
    $ kubectl apply -f @samples/httpbin/httpbin.yaml@
    {{< /text >}}

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -f -
    apiVersion: networking.istio.io/v1
    kind: Sidecar
    metadata:
      name: secure-metrics
      namespace: default
    spec:
      ingress:
      - port:
          number: 15091
          name: https-metrics
          protocol: HTTP
        defaultEndpoint: 127.0.0.1:15020 # Change to 15090 for Envoy-only metrics
    EOF
    {{< /text >}}

1. Додайте анотації до podʼа робочого навантаження для виявлення Prometheus:

    {{< text bash >}}
    $ kubectl annotate pod -n default \
      -l app=httpbin \
      prometheus.io/scrape="true" \
      prometheus.io/path="/stats/prometheus" \
      prometheus.istio.io/secure-port="15091" \
      --overwrite
    {{< /text >}}

### Застарілий: захищені метрики для шлюзів {#legacy-secure-metrics-for-gateways}

1. Створіть `Gateway` із захищеним HTTPS-слухачем на порту `15091`:

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -f -
    apiVersion: networking.istio.io/v1
    kind: Gateway
    metadata:
      name: metrics-gateway
      namespace: istio-system
    spec:
      selector:
        istio: ingressgateway
      servers:
      - port:
          number: 15091
          name: https-metrics
          protocol: HTTPS
        tls:
          mode: ISTIO_MUTUAL
        hosts: ["*"]
    EOF
    {{< /text >}}

1. Створіть `ServiceEntry`, щоб відкрити порт телеметрії шлюзу всередині мережі:

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -f -
    apiVersion: networking.istio.io/v1
    kind: ServiceEntry
    metadata:
      name: gateway-admin
      namespace: istio-system
    spec:
      hosts: [gateway-admin.local]
      location: MESH_INTERNAL
      ports:
      - number: 15020  # Change to 15090 for Envoy-only metrics
        name: http-metrics
        protocol: HTTP
      resolution: STATIC
      endpoints:
      - address: 127.0.0.1
    EOF
    {{< /text >}}

1. Створіть `VirtualService`, щоб маршрутизувати запити від захищеного прослуховувача до порту телеметрії:

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -f -
    apiVersion: networking.istio.io/v1
    kind: VirtualService
    metadata:
      name: gateway-metrics
      namespace: istio-system
    spec:
      hosts: ["*"]
      gateways: [metrics-gateway]
      http:
      - match:
        - uri:
            prefix: /stats/prometheus
        route:
        - destination:
            host: gateway-admin.local
            port:
              number: 15020  # Change to 15090 for Envoy-only metrics
    EOF
    {{< /text >}}

1. Додайте анотації до podʼа шлюзу для виявлення Prometheus:

    {{< text bash >}}
    $ kubectl annotate pod -n istio-system \
      -l app=istio-ingressgateway \
      prometheus.istio.io/secure-port=15091 \
      --overwrite
    {{< /text >}}

### Застарілий: очищення {#legacy-cleanup}

{{< text bash >}}
$ kubectl delete sidecar secure-metrics -n default
$ kubectl delete gateway metrics-gateway -n istio-system
$ kubectl delete serviceentry gateway-admin -n istio-system
$ kubectl delete virtualservice gateway-metrics -n istio-system
$ kubectl delete -n istio-system -f @samples/addons/extras/prometheus-secure-metrics.yaml@
$ kubectl delete -f @samples/httpbin/httpbin.yaml@
$ kubectl label namespace default istio-injection-
{{< /text >}}
