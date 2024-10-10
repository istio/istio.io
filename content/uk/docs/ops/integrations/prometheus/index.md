---
title: Prometheus
description: Як інтегрувати Prometheus.
weight: 30
keywords: [integration,prometheus]
owner: istio/wg-environments-maintainers
test: n/a
---

[Prometheus](https://prometheus.io/) — це система моніторингу з відкритим вихідним кодом і база даних часових рядів. Ви можете використовувати Prometheus з Istio для запису метрик, що відстежують стан Istio та застосунків у сервісній мережі. Ви можете візуалізувати метрики за допомогою таких інструментів, як [Grafana](/docs/ops/integrations/grafana/) та [Kiali](/docs/tasks/observability/kiali/).

## Встановлення {#installation}

### Варіант 1: Швидкий старт {#option-1-quick-start}

Istio надає базове демонстраційне встановлення для швидкого запуску Prometheus:

{{< text bash >}}
$ kubectl apply -f {{< github_file >}}/samples/addons/prometheus.yaml
{{< /text >}}

Це розгорне Prometheus у вашому кластері. Це призначено лише для демонстрації та не оптимізовано для продуктивності або безпеки.

{{< warning >}}
Хоча конфігурація швидкого старту добре підходить для невеликих кластерів та моніторингу протягом короткого часу, вона не підходить для великих мереж або моніторингу протягом днів або тижнів. Зокрема, введені мітки можуть збільшити кардинальність метрик, що вимагає великого обсягу зберігання. І, коли потрібно визначити тенденції та відмінності в трафіку з часом, доступ до історичних даних може бути критично важливим.
{{< /warning >}}

### Варіант 2: Налаштоване встановлення {#option-2-customizable-install}

Ознайомтесь з [документацією Prometheus](https://www.prometheus.io/), щоб почати розгортати Prometheus у вашому середовищі. Дивіться [Конфігурацію](#configuration) для отримання додаткової інформації про конфігурацію Prometheus для збору даних про розгортання Istio.

## Конфігурація {#configuration}

У мережі Istio кожен компонент надає точку доступу, яка публікує метрики. Prometheus працює шляхом збору даних з цих точок доступу. Це конфігурується через [файл конфігурації Prometheus](https://prometheus.io/docs/prometheus/latest/configuration/configuration/), який контролює налаштування для яких точок доступу запитувати, порт і шлях запиту, налаштування TLS та інше.

Щоб зібрати метрики для всієї мережі, налаштуйте Prometheus для збору:

1. Панель управління (`istiod` розгортання)
2. Ingress та Egress шлюзи
3. Envoy sidecar
4. Застосунки користувача (якщо вони публікують метрики Prometheus)

Щоб спростити конфігурацію метрик, Istio пропонує два режими роботи.

### Варіант 1: Обʼєднання метрик {#option-1-metrics-merging}

Щоб спростити конфігурацію, Istio має можливість повністю контролювати збору даних за допомогою анотацій `prometheus.io`. Це дозволяє збору даних з Istio працювати з готовими конфігураціями, такими як ті, що надаються [Helm `stable/prometheus`](https://github.com/helm/charts/tree/master/stable/prometheus) чартами.

{{< tip >}}
Хоча анотації `prometheus.io` не є основною частиною Prometheus, вони стали де-факто стандартом для конфігурації збору даних.
{{< /tip >}}

Цей варіант увімкнено стандартно, але його можна вимкнути, передавши
`--set meshConfig.enablePrometheusMerge=false` під час [встановлення](/docs/setup/install/istioctl/). Коли увімкнено, відповідні анотації `prometheus.io` будуть додані до всіх контейнерів даних, щоб налаштувати збір даних. Якщо ці анотації вже існують, вони будуть перезаписані. За допомогою цього варіанту sidecar Envoy буде змішувати метрики Istio з метриками застосунків. Обʼєднані метрики будуть зібрані з `:15020/stats/prometheus`.

Цей варіант експонує всі метрики у текстовому вигляді.

Ця функція може не відповідати вашим потребам у наступних ситуаціях:

* Вам потрібно збирати метрики за допомогою TLS.
* Ваш застосунок публікує метрики з такими ж назвами, як і метрики Istio. Наприклад, ваші метрики застосунку надають метрику `istio_requests_total`. Це може статися, якщо застосунок самостійно запускає Envoy.
* Ваша установка Prometheus не налаштована для збору даних на основі стандартних анотацій `prometheus.io`.

Якщо потрібно, цю функцію можна вимкнути для кожного навантаження, додавши анотацію `prometheus.istio.io/merge-metrics: "false"` до podʼа.

### Варіант 2: Налаштовані конфігурації збору {#option-2-customized-scraping-configurations}

Щоб налаштувати наявну установку Prometheus для збору статистики, згенерованої Istio, потрібно додати кілька завдань (job).

* Щоб зібрати статистику `Istiod`, можна додати наступне завдання для збору з його порту `http-monitoring`:

{{< text yaml >}}
- job_name: 'istiod'
  kubernetes_sd_configs:
  - role: endpoints
    namespaces:
      names:
      - istio-system
  relabel_configs:
  - source_labels: [__meta_kubernetes_service_name, __meta_kubernetes_endpoint_port_name]
    action: keep
    regex: istiod;http-monitoring
{{< /text >}}

* Щоб зібрати статистику Envoy, включаючи проксі sidecar та проксі шлюзів,
  можна додати наступне завдання для збору з портів, що закінчуються на `-envoy-prom`:

{{< text yaml >}}
    - job_name: 'envoy-stats'
      metrics_path: /stats/prometheus
      kubernetes_sd_configs:
      - role: pod

      relabel_configs:
      - source_labels: [__meta_kubernetes_pod_container_port_name]
        action: keep
        regex: '.*-envoy-prom'
{{< /text >}}

* Для статистики застосунків, якщо [Strict mTLS](/docs/tasks/security/authentication/authn-policy/#globally-enabling-istio-mutual-tls-in-strict-mode) не увімкнено, ваша наявна конфігурація збору даних повинна продовжити працювати. В іншому випадку, Prometheus потрібно налаштувати для [збору з сертифікатами Istio](#tls-settings).

#### Налаштування TLS {#tls-settings}

Коли Istio налаштовано для використання взаємного TLS, Prometheus повинен бути налаштований для збору даних з використанням сертифікатів Istio.

Метрики панелі управління, шлюзу та sidecar Envoy будуть зібрані через незашифрований текст. Однак метрики застосунків слідуватимуть будь-якій [політиці автентифікації Istio](/docs/tasks/security/authentication/authn-policy), яка була налаштована для навантаження.

* Якщо ви використовуєте режим `STRICT`, то Prometheus потрібно налаштувати для збору даних з використанням сертифікатів Istio, як описано нижче.
* Якщо ви використовуєте режим `PERMISSIVE`, навантаження зазвичай приймає TLS і незашифрований текст. Однак, Prometheus не може надсилати спеціальний варіант TLS, який вимагає Istio для режиму `PERMISSIVE`. Як результат, ви не повинні *налаштовувати* TLS у Prometheus.
* Якщо ви використовуєте режим `DISABLE`, для Prometheus не потрібно налаштовувати TLS.

{{< tip >}}
Зверніть увагу, що це стосується лише TLS з Istio-термінацією. Якщо ваш застосунок безпосередньо працює з TLS:

* Режим `STRICT` не підтримується, оскільки Prometheus повинен надсилати два шари TLS, що він не може зробити.
* Режим `PERMISSIVE` і `DISABLE` слід налаштувати так, ніби Istio не був присутній.

Дивіться [Розуміння конфігурації TLS](/docs/ops/configuration/traffic-management/tls-configuration/) для отримання додаткової інформації.
{{< /tip >}}

Один зі способів надати сертифікати Istio для Prometheus — це впровадження sidecar, який буде ротувати сертифікати SDS і виводити їх у том, який можна розділити з Prometheus. Однак, sidecar не повинен перехоплювати запити для Prometheus, оскільки модель прямого доступу до точок доступу Prometheus несумісна з моделлю проксі sidecar Istio.

Щоб досягти цього, налаштуйте зміну тома сертифікатів в контейнері сервера Prometheus:

{{< text yaml >}}
containers:
  - name: prometheus-server
    ...
    volumeMounts:
      mountPath: /etc/prom-certs/
      name: istio-certs
volumes:
  - emptyDir:
      medium: Memory
    name: istio-certs
{{< /text >}}

Тоді додайте наступні анотації до шаблону podʼа розгортання Prometheus і розгорніть його з [інʼєкцією sidecar](/docs/setup/additional-setup/sidecar-injection/). Це налаштовує sidecar для запису сертифіката у спільний том, але без налаштування перенаправлення трафіку:

{{< text yaml >}}
spec:
  template:
    metadata:
      annotations:
        traffic.sidecar.istio.io/includeInboundPorts: ""   # не перехоплювати жодних вхідних портів
        traffic.sidecar.istio.io/includeOutboundIPRanges: ""  # не перехоплювати жоден вихідний трафік
        proxy.istio.io/config: |  # налаштувати змінну середовища `OUTPUT_CERTS`, щоб записувати сертифікати у вказану теку
          proxyMetadata:
            OUTPUT_CERTS: /etc/istio-output-certs
        sidecar.istio.io/userVolumeMount: '[{"name": "istio-certs", "mountPath": "/etc/istio-output-certs"}]' # змонтувати спільний том у sidecar proxy
{{< /text >}}

Нарешті, налаштуйте контекст TLS для завдання збору:

{{< text yaml >}}
scheme: https
tls_config:
  ca_file: /etc/prom-certs/root-cert.pem
  cert_file: /etc/prom-certs/cert-chain.pem
  key_file: /etc/prom-certs/key.pem
  insecure_skip_verify: true  # Prometheus не підтримує безпеку іменування Istio, тому пропустіть перевірку сертифіката цільового podʼа
{{< /text >}}

## Найкращі практики {#best-practices}

Для більших мереж розширена конфігурація може допомогти Prometheus масштабуватися. Дивіться [Використання Prometheus для моніторингу в промисловому масштабі](/docs/ops/best-practices/observability/#using-prometheus-for-production-scale-monitoring) для отримання додаткової інформації.
