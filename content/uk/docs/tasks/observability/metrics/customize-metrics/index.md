---
title: Налаштування метрик Istio
description: Це завдання показує, як налаштувати метрики Istio.
weight: 25
keywords: [telemetry,metrics,customize]
owner: istio/wg-policies-and-telemetry-maintainers
test: yes
---

Це завдання показує, як налаштувати метрики, які генерує Istio.

Istio генерує телеметрію, яку різні інформаційні панелі використовують для візуалізації вашої мережі. Наприклад, інформаційні панелі, які підтримують Istio, включають:

* [Grafana](/docs/tasks/observability/metrics/using-istio-dashboard/)
* [Kiali](/docs/tasks/observability/kiali/)
* [Prometheus](/docs/tasks/observability/metrics/querying-metrics/)

Стандартно, Istio визначає і генерує набір стандартних метрик (наприклад, `requests_total`), але ви також можете налаштувати їх і створити нові метрики за допомогою [Telemetry API](/docs/tasks/observability/telemetry/).

## Перед початком {#before-you-begin}

[Встановіть Istio](/docs/setup/) у ваш кластер і розгорніть застосунок. Або ж ви можете налаштувати власну статистику як частину установки Istio.

Демонстраційний застосунок [Bookinfo](/docs/examples/bookinfo/) використовується як приклад протягом цього завдання. Для інструкцій з установки дивіться розділ [розгортання застосунку Bookinfo](/docs/examples/bookinfo/#deploying-the-application).

## Увімкнення власних метрик {#enable-custom-metrics}

Щоб налаштувати метрики телеметрії, наприклад, щоб додати виміри `request_host` і `destination_port` до метрики `requests_total`, що надходить як від шлюзів, так і від sidecar у напрямку вхідного та вихідного трафіку, використовуйте наступне:

{{< text bash >}}
$ cat <<EOF > ./custom_metrics.yaml
apiVersion: telemetry.istio.io/v1
kind: Telemetry
metadata:
  name: namespace-metrics
spec:
  metrics:
  - providers:
    - name: prometheus
    overrides:
    - match:
        metric: REQUEST_COUNT
      tagOverrides:
        destination_port:
          value: "string(destination.port)"
        request_host:
          value: "request.host"
EOF
$ kubectl apply -f custom_metrics.yaml
{{< /text >}}

## Перевірка результатів {#verify-the-results}

Надішліть трафік до мережі. Для застосунку Bookinfo, відвідайте `http://$GATEWAY_URL/productpage` у вашому вебоглядачі або виконайте наступну команду:

{{< text bash >}}
$ curl "http://$GATEWAY_URL/productpage"
{{< /text >}}

{{< tip >}}
`$GATEWAY_URL` — це значення, встановлене в застосунку [Bookinfo](/docs/examples/bookinfo/).
{{< /tip >}}

Використовуйте наступну команду, щоб перевірити, що Istio генерує дані для ваших нових або змінених вимірювань:

{{< text bash >}}
$ kubectl exec "$(kubectl get pod -l app=productpage -o jsonpath='{.items[0].metadata.name}')" -c istio-proxy -- curl -sS 'localhost:15000/stats/prometheus' | grep istio_requests_total
{{< /text >}}

Наприклад, вивчіть вихідні дані, знайдіть метрику `istio_requests_total` і перевірте, чи містить вона ваші нові вимірювання.

{{< tip >}}
Може знадобитися деякий час, поки проксі почнуть застосовувати конфігурацію. Якщо метрику не отримано, ви можете повторити запити після короткої паузи та знову перевірити метрику.
{{< /tip >}}

## Використання виразів для значень {#use-expressions-for-values}

Значення в конфігурації метрик є загальними виразами, що означає, що ви повинні використовувати подвійні лапки для рядків у JSON, наприклад, "'string value'". На відміну від мови виразів Mixer, немає підтримки оператора вертикальної риски (`|`), але ви можете емулювати його за допомогою оператора `has` або `in`, наприклад:

{{< text plain >}}
has(request.host) ? request.host : "unknown"
{{< /text >}}

Більше інформації дивіться в [Common Expression Language](https://opensource.google/projects/cel).

Istio відкриває всі стандартні [атрибути Envoy](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/advanced/attributes). Метадані peer доступні як атрибути `upstream_peer` для виходу і `downstream_peer` для входу з наступними полями:

|Поле         | Тип      | Значення                                                          |
|-------------|----------|-------------------------------------------------------------------|
| `app`       | `string` | Назва застосунку.                                                 |
| `version`   | `string` | Версія застосунку.                                                |
| `service`   | `string` | Екземпляр Service.                                                |
| `revision`  | `string` | Версія Service.                                                   |
| `name`      | `string` | Імʼя podʼа.                                                       |
| `namespace` | `string` | Простір імен, в якому запущено pod.                               |
| `type`      | `string` | Тип робочого навантаження.                                        |
| `workload`  | `string` | Назва робочого навантаження.                                      |
| `cluster`   | `string` | Ідентифікатор кластера, до якого належить це робоче навантаження. |

Наприклад, вираз для мітки peer `app`, що використовується у вихідній конфігурації, — це `filter_state.downstream_peer.app` або `filter_state.upstream_peer.app`.

## Очищення {#cleanup}

Щоб видалити демонстраційний застосунок `Bookinfo` і його конфігурацію, дивіться [очищення `Bookinfo`](/docs/examples/bookinfo/#cleanup).
