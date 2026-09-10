---
title: Дашборд Kiali для ambient багатомережевого середовища
description: Налаштування федеративного екземпляра Prometheus і розгортання Kiali в ambient багатомережевому середовищі.
weight: 70
keywords: [kubernetes,multicluster,ambient]
test: yes
owner: istio/wg-environments-maintainers
prev: /docs/ambient/install/multicluster/verify
---
Дотримуйтеся цього посібника, щоб розгорнути Kiali з підтримкою мультикластерів у багатомережевому ambient розгортанні та переглядати,
як трафік протікає між кластерами.

Перед тим як продовжити, обовʼязково виконайте кроки з розділів
[перед початком](/docs/ambient/install/multicluster/before-you-begin), [посібники з мультикластерної установки](/docs/ambient/install/multicluster) та [перевірка вашого розгортання](/docs/ambient/install/multicluster/verify).

У цьому посібнику ми почнемо з розгортання федеративного екземпляра Prometheus для агрегування метрик з
усіх кластерів разом. Потім ми перейдемо до розгортання налаштованого екземпляра Kiali, який підключається до всіх
кластерів і надає єдиний погляд на трафік мережі.

{{< warning >}}
Конфігурація, показана в цьому посібнику, призначена бути простою і не є рекомендованою для виробничого
середовища. Щодо найкращих практик виробничого налаштування Prometheus зверніться до
[Використання Prometheus для моніторингу виробничого масштабу](/docs/ops/best-practices/observability/#using-prometheus-for-production-scale-monitoring).
Деталі щодо розгортань Kiali дивіться в [документації Kiali](https://kiali.io/docs/).
{{< /warning >}}

## Підготовка до розгортання Kiali {#prepare-for-kiali-deployment}

Ми встановимо налаштовані Prometheus і Kiali в окремий простір імен, тож почнемо зі
створення простору імен в обох кластерах:

{{< text bash >}}
$ kubectl --context="${CTX_CLUSTER1}" create namespace kiali
$ kubectl --context="${CTX_CLUSTER2}" create namespace kiali
{{< /text >}}

Ми також використаємо `helm` для розгортання Kiali, тож додамо відповідні репозиторії Helm:

{{< text bash >}}
$ helm repo add kiali https://kiali.org/helm-charts
{{< /text >}}

## Федеративний Prometheus {#federated-prometheus}

Istio надає базовий приклад установки для швидкого запуску Prometheus в однокластерних
розгортаннях: ми використаємо його для встановлення Prometheus у кожному кластері. Потім ми розгорнемо ще один
екземпляр Prometheus, який буде збирати метрики з Prometheus у кожному кластері та агрегувати їх разом.

Щоб мати можливість збирати метрики з Prometheus у віддаленому кластері, ми відкриємо екземпляр Prometheus через вхідний
шлюз.

### Розгортання Prometheus у кожному кластері {#deploy-prometheus-in-each-cluster}

{{< text bash >}}
$ kubectl --context="${CTX_CLUSTER1}" apply -f {{< github_file >}}/samples/addons/prometheus.yaml
$ kubectl --context="${CTX_CLUSTER2}" apply -f {{< github_file >}}/samples/addons/prometheus.yaml
{{< /text >}}

Наведені вище команди встановлять Prometheus, який збирає локальні метрики кластера з waypoint і
ztunnel.

### Відкриття Prometheus {#expose-prometheus}

Наступний крок: відкрити екземпляри Prometheus зовні, щоб їх можна було збирати:

{{< text bash >}}
$ cat <<EOF | kubectl --context="${CTX_CLUSTER1}" apply -f -
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: prometheus-gateway
  namespace: istio-system
spec:
  gatewayClassName: istio
  listeners:
  - name: http
    port: 9090
    protocol: HTTP
    allowedRoutes:
      namespaces:
        from: Same
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: prometheus
  namespace: istio-system
spec:
  parentRefs:
  - name: prometheus-gateway
    port: 9090
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /
    backendRefs:
    - name: prometheus
      port: 9090
EOF
{{< /text >}}

Ми зробимо те саме і в другому кластері:

{{< text bash >}}
$ cat <<EOF | kubectl --context="${CTX_CLUSTER2}" apply -f -
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: prometheus-gateway
  namespace: istio-system
spec:
  gatewayClassName: istio
  listeners:
  - name: http
    port: 9090
    protocol: HTTP
    allowedRoutes:
      namespaces:
        from: Same
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: prometheus
  namespace: istio-system
spec:
  parentRefs:
  - name: prometheus-gateway
    port: 9090
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /
    backendRefs:
    - name: prometheus
      port: 9090
EOF
{{< /text >}}

### Агрегування метрик {#aggregate-metrics}

Коли локальні для кластера екземпляри Prometheus запущені, ми можемо налаштувати ще один екземпляр Prometheus,
який буде збирати метрики з них, щоб отримувати метрики з обох кластерів в одному місці. Почнемо зі створення
конфігурації для нового екземпляра Prometheus, яка вкаже йому, з яких локальних для кластера екземплярів Prometheus
збирати метрики:

{{< text bash >}}
$ TARGET1="$(kubectl --context="${CTX_CLUSTER1}" get gtw prometheus-gateway -n istio-system -o jsonpath='{.status.addresses[0].value}')"
$ TARGET2="$(kubectl --context="${CTX_CLUSTER2}" get gtw prometheus-gateway -n istio-system -o jsonpath='{.status.addresses[0].value}')"
$ cat <<EOF > prometheus.yml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'federate-1'
    honor_labels: true
    metrics_path: '/federate'
    params:
      'match[]':
        - '{job="kubernetes-pods"}'
    static_configs:
      - targets:
        - '${TARGET1}:9090'
        labels:
          cluster: 'cluster1'
  - job_name: 'federate-2'
    honor_labels: true
    metrics_path: '/federate'
    params:
      'match[]':
        - '{job="kubernetes-pods"}'
    static_configs:
      - targets:
        - '${TARGET2}:9090'
        labels:
          cluster: 'cluster2'
EOF
$ kubectl --context="${CTX_CLUSTER1}" create configmap prometheus-config -n kiali --from-file prometheus.yml
{{< /text >}}

Тепер ми можемо використати цю конфігурацію для розгортання нового екземпляра Prometheus:

{{< text bash >}}
$ cat <<EOF | kubectl --context="${CTX_CLUSTER1}" apply -f - -n kiali
apiVersion: apps/v1
kind: Deployment
metadata:
  name: prometheus
spec:
  replicas: 1
  selector:
    matchLabels:
      app: prometheus
  template:
    metadata:
      labels:
        app: prometheus
    spec:
      containers:
        - name: prometheus
          image: prom/prometheus
          ports:
            - containerPort: 9090
          volumeMounts:
            - name: config-volume
              mountPath: /etc/prometheus
      volumes:
        - name: config-volume
          configMap:
            name: prometheus-config
            defaultMode: 420
---
apiVersion: v1
kind: Service
metadata:
  name: prometheus
  labels:
    app: prometheus
    service: prometheus
spec:
  ports:
  - port: 9090
    name: http
  selector:
    app: prometheus
EOF
{{< /text >}}

Після розгортання новий екземпляр Prometheus почне збирати метрики з обох кластерів.

### Перевірка федеративного Prometheus {#verify-federated-prometheus}

Щоб перевірити, ми можемо згенерувати трохи трафіку, запустивши `curl` кілька разів для досягнення бекендів в обох
кластерах:

{{< text bash >}}
$ kubectl exec --context="${CTX_CLUSTER1}" -n sample -c curl \
    "$(kubectl get pod --context="${CTX_CLUSTER1}" -n sample -l \
    app=curl -o jsonpath='{.items[0].metadata.name}')" \
    -- curl -sS helloworld.sample:5000/hello
{{< /text >}}

{{< text plain >}}
Hello version: v2, instance: helloworld-v2-758dd55874-6x4t8
Hello version: v1, instance: helloworld-v1-86f77cd7bd-cpxhv
...
{{< /text >}}

Потім ми можемо надіслати запит до Prometheus за допомогою `curl`, щоб побачити, чи маємо ми метрики з усіх кластерів:

{{< text bash >}}
$ kubectl exec --context="${CTX_CLUSTER1}" -n sample -c curl \
    "$(kubectl get pods ---context="${CTX_CLUSTER1}" -n sample -l \
    app=curl -o jsonpath='{.items[0].metadata.name}')" \
    -- curl -s prometheus.kiali:9090/api/v1/query?query=istio_tcp_received_bytes_total | jq '.'
{{< /text >}}

Якщо запит `curl` досяг бекендів в обох кластерах, для метрики `istio_tcp_received_bytes_total`,
яку повідомляє `ztunnel`, ви маєте побачити значення з обох кластерів у виводі:

{{< text plain >}}
{
  "status": "success",
  "data": {
    "resultType": "vector",
    "result": [
      {
        "metric": {
          "__name__": "istio_tcp_received_bytes_total",
          ...
          "app": "ztunnel",
          ...
          "cluster": "cluster2",
          ...
          "destination_canonical_revision": "v2",
          ...
          "destination_canonical_service": "helloworld",
          ...
        },
        "value": [
          1770660628.007,
          "5040"
        ]
      },
      ...
      {
        "metric": {
          "__name__": "istio_tcp_received_bytes_total",
          ...
          "app": "ztunnel",
          ...
          "cluster": "cluster1",
          ...
          "destination_canonical_revision": "v1",
          ...
          "destination_canonical_service": "helloworld",
          ...
        },
        "value": [
          1770660628.007,
          "4704"
        ]
      },
      ...
    ]
  }
}
{{< /text >}}

## Розгортання мультикластерного Kiali {#deploy-multicluster-kiali}

### Підготовка віддаленого кластера {#prepare-remote-cluster}

Ми розгорнемо Kiali належним чином лише в одному кластері, `cluster1`, однак нам все одно потрібно підготувати
`cluster2`, щоб Kiali міг отримувати доступ до ресурсів там. Для цього ми почнемо з
розгортання Kiali Operator:

{{< text bash >}}
$ helm --kube-context="${CTX_CLUSTER2}" install --namespace kiali kiali-operator kiali/kiali-operator --wait
{{< /text >}}

Після розгортання Kiali Operator ми можемо підготувати всі необхідні облікові записи служб, привʼязки ролей і токени. Kiali Operator створить обліковий запис служби та привʼязки ролей, але токен для облікового запису служби нам доведеться створити вручну:

{{< text bash >}}
$ cat <<EOF | kubectl --context="${CTX_CLUSTER2}" apply -f - -n kiali
apiVersion: kiali.io/v1alpha1
kind: Kiali
metadata:
  name: kiali
spec:
  auth:
    strategy: "anonymous"
  deployment:
    remote_cluster_resources_only: true
EOF
$ kubectl --context="${CTX_CLUSTER2}" wait --timeout=5m --for=condition=Successful kiali kiali -n kiali
$ cat <<EOF | kubectl --context="${CTX_CLUSTER2}" apply -f - -n kiali
apiVersion: v1
kind: Secret
metadata:
  name: kiali
  namespace: kiali
  annotations:
    kubernetes.io/service-account.name: kiali-service-account
type: kubernetes.io/service-account-token
EOF
{{< /text >}}

### Розгортання Kiali {#deploy-kiali}

Коли віддалений кластер готовий, ми можемо розгорнути сервер Kiali. Нам потрібно буде налаштувати Kiali з
адресою кінцевої точки Prometheus і секретом для доступу до віддаленого кластера. Як і раніше,
ми почнемо з розгортання Kiali Operator:

{{< text bash >}}
$ helm --kube-context="${CTX_CLUSTER1}" install --namespace kiali kiali-operator kiali/kiali-operator --wait
{{< /text >}}

Проєкт Kiali надає скрипт, який ми можемо використати для створення секрету, необхідного для доступу до ресурсів віддаленого
кластера:

{{< text bash >}}
$ curl -L -o kiali-prepare-remote-cluster.sh https://raw.githubusercontent.com/kiali/kiali/master/hack/istio/multicluster/kiali-prepare-remote-cluster.sh
$ chmod +x kiali-prepare-remote-cluster.sh
$ ./kiali-prepare-remote-cluster.sh \
    --kiali-cluster-context "${CTX_CLUSTER1}" \
    --remote-cluster-context "${CTX_CLUSTER2}" \
    --view-only false \
    --process-kiali-secret true \
    --process-remote-resources false \
    --kiali-cluster-namespace kiali \
    --remote-cluster-namespace kiali \
    --kiali-resource-name kiali \
    --remote-cluster-name cluster2
{{< /text >}}

Коли віддалений секрет готовий, ми можемо розгорнути сервер Kiali:

{{< text bash >}}
$ cat <<EOF | kubectl --context="${CTX_CLUSTER1}" apply -f - -n kiali
apiVersion: kiali.io/v1alpha1
kind: Kiali
metadata:
  name: kiali
spec:
  auth:
    strategy: "anonymous"
  external_services:
    prometheus:
      url: http://prometheus.kiali:9090
    grafana:
      enabled: false
  server:
    web_root: "/kiali"
EOF
$ kubectl --context="${CTX_CLUSTER1}" wait --timeout=5m --for=condition=Successful kiali kiali -n kiali
{{< /text >}}

Коли сервер Kiali запущено, ми можемо перенаправити локальний порт на розгортання Kiali, щоб отримати до нього доступ
локально:

{{< text syntax=bash snip_id=none >}}
$ kubectl --context="${CTX_CLUSTER1}" port-forward svc/kiali 20001:20001 -n kiali
{{< /text >}}

Відкрийте дашборд Kiali у браузері, перейдіть до графа трафіку та виберіть простір імен
"sample" зі спадного списку "Select Namespaces". Ви маєте побачити, як трафік протікає між
кластерами:

{{< image link="./kiali-traffic-graph.png" caption="Дашборд графа трафіку Kiali" >}}

{{< tip >}}
Якщо ви не бачите граф трафіку, спробуйте згенерувати більше трафіку та/або розширити часове вікно, яке
розглядає Kiali.
{{</ tip >}}

**Вітаємо!** Ви успішно встановили Kiali для мультикластерного ambient розгортання.

## Очищення Kiali та Prometheus {#cleanup-kiali-and-prometheus}

Щоб видалити Kiali, почніть з видалення користувацького ресурсу Kiali:

{{< text bash >}}
$ kubectl --context="${CTX_CLUSTER1}" delete kiali kiali -n kiali
$ kubectl --context="${CTX_CLUSTER2}" delete kiali kiali -n kiali
{{< /text >}}

Kiali Operator зупинить сервер Kiali після видалення користувацького ресурсу. Якщо ви хочете
додатково видалити Kiali Operator, ви можете зробити це також:

{{< text bash >}}
$ helm --kube-context="${CTX_CLUSTER1}" uninstall --namespace kiali kiali-operator
$ helm --kube-context="${CTX_CLUSTER2}" uninstall --namespace kiali kiali-operator
{{< /text >}}

Нарешті, ви можете видалити визначення користувацьких ресурсів:

{{< text bash >}}
$ kubectl --context="${CTX_CLUSTER1}" delete crd kialis.kiali.io
{{< /text >}}

Якщо вам не потрібні локальні для кластера екземпляри Prometheus, ви можете видалити їх також:

{{< text bash >}}
$ kubectl --context="${CTX_CLUSTER1}" delete -f {{< github_file >}}/samples/addons/prometheus.yaml
$ kubectl --context="${CTX_CLUSTER2}" delete -f {{< github_file >}}/samples/addons/prometheus.yaml
{{< /text >}}
