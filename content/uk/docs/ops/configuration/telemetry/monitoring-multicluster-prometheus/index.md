---
title: Моніторинг мультикластера Istio з Prometheus
description: Налаштування Prometheus для моніторингу мультикластера Istio.
weight: 20
aliases:
  - /uk/help/ops/telemetry/monitoring-multicluster-prometheus
  - /uk/docs/ops/telemetry/monitoring-multicluster-prometheus
owner: istio/wg-policies-and-telemetry-maintainers
test: no
---

## Огляд {#overview}

Цей посібник призначений для надання оперативних вказівок щодо налаштування моніторингу мереж Istio, що складаються з двох або більше окремих кластерів Kubernetes. Він не має на меті встановлення *єдиного* можливого шляху, а скоріше демонструє робочий підхід до мультикластерної телеметрії з Prometheus.

Наша рекомендація щодо мультикластерного моніторингу Istio з Prometheus ґрунтується на основі [ієрархічної федерації](https://prometheus.io/docs/prometheus/latest/federation/#hierarchical-federation) Prometheus. Екземпляри Prometheus, які розгорнуті локально в кожному кластері за допомогою Istio, діють як початкові збирачі, які потім федеративно передають дані до промислового екземпляра Prometheus для всього mesh. Цей промисловий екземпляр Prometheus може знаходитися або зовні mesh (зовнішня), або в одному з кластерів всередині mesh.

## Налаштування мультикластера Istio {#multicluster-istio-setup}

Слідуйте розділу [втсановлення мультикластера](/docs/setup/install/multicluster/) для налаштування ваших кластерів Istio в одній з підтримуваних [моделей розгортання мультикластерів](/docs/ops/deployment/deployment-models/#multiple-clusters). Для цілей цього посібника будь-який з цих підходів підійде, з наступним застереженням:

**Переконайтесь, що локальний екземпляр Istio Prometheus встановлено в кожному кластері.**

Окреме розгортання Prometheus в кожному кластері Istio необхідне для формування основи моніторингу між кластерами за допомогою федерації до промислового екземпляра Prometheus, що працює зовні або в одному з кластерів.

Перевірте, що у вас є екземпляр Prometheus, що працює в кожному кластері:

{{< text bash >}}
$ kubectl -n istio-system get services prometheus
NAME         TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)    AGE
prometheus   ClusterIP   10.8.4.109   <none>        9090/TCP   20h
{{< /text >}}

## Налаштування федерації Prometheus {#configure-prometheus-federation}

### Зовнішній промисловий екземпляр Prometheus {#external-production-prometheus}

Існує кілька причин, чому ви можете захотіти мати екземпляр Prometheus, що працює зовні вашого розгортання Istio. Можливо, ви хочете довгостроковий моніторинг, відокремлений від кластера, що моніториться. Можливо, ви хочете моніторити кілька окремих mesh в одному місці. Або у вас можуть бути інші мотиви. Які б не були ваші причини, вам знадобляться спеціальні конфігурації, щоб все працювало.

{{< image width="80%"
    link="./external-production-prometheus.svg"
    alt="Архітектура зовнішнього промислового екземпляра Prometheus для моніторингу мультикластера Istio."
    caption="Зовнішній промисловий Prometheus для моніторингу мультикластера Istio"
    >}}

{{< warning >}}
Цей посібник демонструє підключення до локальних екземплярів Prometheus в кластері, але не розглядає питання безпеки. Для промислового використання забезпечте безпечний доступ до кожної точки доступу Prometheus за допомогою HTTPS. Крім того, вживайте заходів, таких як використання внутрішнього балансувальника навантаження замість публічної точки доступу та належну конфігурацію правил брандмауера.
{{< /warning >}}

Istio надає спосіб експонування сервісів кластера зовні через [Gateways](/docs/reference/config/networking/gateway/). Ви можете налаштувати ingress gateway для локального Prometheus в кластері, забезпечуючи зовнішню доступність до точки доступу Prometheus всередині кластера.

Для кожного кластера дотримуйтеся відповідних інструкцій з [Віддалений доступ до надбудов телеметрії](/docs/tasks/observability/gateways/#option-1-secure-access-https). Також зверніть увагу, що **ВИ ПОВИННІ** встановити захищений (HTTPS) доступ.

Далі, налаштуйте ваш зовнішній екземпляр Prometheus для доступу до локального екземпляра Prometheus в кластері за допомогою конфігурації, поданої нижче (замініть домен ingress та імʼя кластера):

{{< text yaml >}}
scrape_configs:
- job_name: 'federate-{{CLUSTER_NAME}}'
  scrape_interval: 15s

  honor_labels: true
  metrics_path: '/federate'

  params:
    'match[]':
      - '{job="kubernetes-pods"}'

  static_configs:
    - targets:
      - 'prometheus.{{INGRESS_DOMAIN}}'
      labels:
        cluster: '{{CLUSTER_NAME}}'
{{< /text >}}

Примітки:

* `CLUSTER_NAME` слід встановити те ж значення, яке ви використовували для створення кластера (встановлено через `values.global.multiCluster.clusterName`).

* Не забезпечено автентифікацію до точок доступу Prometheus. Це означає, що будь-хто може запитувати ваші локальні екземпляри Prometheus. Це може бути небажаним.

* Без належної конфігурації HTTPS шлюзу, все передається у відкритому вигляді. Це може бути небажаним.

### Prometheus в кластері всередині mesh {#production-prometheus-on-an-in-mesh-cluster}

Якщо ви віддаєте перевагу промисловому розгортанню Prometheus в одному з кластерів, вам потрібно встановити підключення від нього до інших локальних екземплярів Prometheus в mesh.

Це по суті є варіацією конфігурації для зовнішньої федерації. У цьому випадку конфігурація в кластері, що працює з промисловим екземпляром Prometheus, відрізняється від конфігурації для опитування віддалених кластерів Prometheus.

{{< image width="80%"
    link="./in-mesh-production-prometheus.svg"
    alt="Архітектура промислового розгортання Prometheus всередині mesh для моніторингу мультикластера Istio."
    caption="Промисловий екземпляр Prometheus всередині mesh для моніторингу мультикластера Istio"
    >}}

Налаштуйте ваш промисловий екземпляр Prometheus для доступу як до *локальних*, так і до *віддалених* екземплярів Prometheus.

Спочатку виконайте наступну команду:

{{< text bash >}}
$ kubectl -n istio-system edit cm prometheus -o yaml
{{< /text >}}

Далі додайте конфігурації для *віддалених* кластерів (замініть домен ingress та ім'я кластера для кожного кластера) та додайте одну конфігурацію для *локального* кластера:

{{< text yaml >}}
scrape_configs:
- job_name: 'federate-{{REMOTE_CLUSTER_NAME}}'
  scrape_interval: 15s

  honor_labels: true
  metrics_path: '/federate'

  params:
    'match[]':
      - '{job="kubernetes-pods"}'

  static_configs:
    - targets:
      - 'prometheus.{{REMOTE_INGRESS_DOMAIN}}'
      labels:
        cluster: '{{REMOTE_CLUSTER_NAME}}'

- job_name: 'federate-local'

  honor_labels: true
  metrics_path: '/federate'

  metric_relabel_configs:
  - replacement: '{{CLUSTER_NAME}}'
    target_label: cluster

  kubernetes_sd_configs:
  - role: pod
    namespaces:
      names: ['istio-system']
  params:
    'match[]':
    - '{__name__=~"istio_(.*)"}'
    - '{__name__=~"pilot(.*)"}'
{{< /text >}}
