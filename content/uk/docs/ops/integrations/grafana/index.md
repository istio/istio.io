---
title: Grafana
description: Інформація про інтеграцію з Grafana для налаштування інформаційних панелей Istio.
weight: 27
keywords: [integration,grafana]
owner: istio/wg-environments-maintainers
test: no
---

[Grafana](https://grafana.com/) — це рішення з відкритим вихідним кодом для моніторингу, яке можна використовувати для налаштування інформаційних панелей для Istio. Ви можете використовувати Grafana для моніторингу справності Istio та застосунків у сервісній мережі.

## Конфігурація {#configuration}

Хоча ви можете створити власні дашборди, Istio пропонує набір попередньо налаштованих панелей для всіх найважливіших метрик для мережі та для панелі управління.

* [Інфопанель Mesh](https://grafana.com/grafana/dashboards/7639) надає огляд усіх сервісів у мережі.
* [Інфопанель сервіса](https://grafana.com/grafana/dashboards/7636) надає детальний розподіл метрик для сервісу.
* [Інфопанель навантаження](https://grafana.com/grafana/dashboards/7630) надає детальний розподіл метрик для навантаження.
* [Інфопанель продуктивності](https://grafana.com/grafana/dashboards/11829) моніторить використання ресурсів мережі.
* [Інфопанель панелі управління](https://grafana.com/grafana/dashboards/7645) моніторить справність та продуктивність панелі управління.
* [Інфопанель розширення WASM](https://grafana.com/grafana/dashboards/13277) надає огляд стану виконання та завантаження розширення WebAssembly по всій мережі.

Є кілька способів налаштувати Grafana для використання цих панелей:

### Варіант 1: Швидкий старт {#option-1-quick-start}

Istio надає базове демонстраційне встановлення для швидкого запуску Grafana, з усіма вже встановленими інфопанелями Istio:

{{< text bash >}}
$ kubectl apply -f {{< github_file >}}/samples/addons/grafana.yaml
{{< /text >}}

Це розгорне Grafana у вашому кластері. Це призначено лише для демонстрації
та не оптимізовано для продуктивності або безпеки.

### Варіант 2: Імпорт з `grafana.com` в наявне розгортання {#option-2-import-from-grafana-com-into-an-existing-deployment}

Щоб швидко імплементувати інфопанелі Istio в наявний екземпляр Grafana, ви можете використовувати [кнопку **Імпорт** в UI Grafana](https://grafana.com/docs/grafana/latest/reference/export_import/#importing-a-dashboard) для додавання вище наведених посилань в панелі. При імпорті панелей, зверніть увагу, що ви повинні вибрати джерело даних Prometheus.

Ви також можете використовувати скрипт для імпорту всіх панелей одночасно. Наприклад:

{{< text bash >}}
$ # Адреса Grafana
$ GRAFANA_HOST="http://localhost:3000"
$ # Облікові дані для входу, якщо використовується автентифікація
$ GRAFANA_CRED="USER:PASSWORD"
$ # Назва джерела даних Prometheus, яке потрібно використовувати
$ GRAFANA_DATASOURCE="Prometheus"
$ # Версія Istio для розгортання
$ VERSION={{< istio_full_version >}}
$ # Імпорт усіх інфопанелей Istio
$ for DASHBOARD in 7639 11829 7636 7630 7645 13277; do
$     REVISION="$(curl -s https://grafana.com/api/dashboards/${DASHBOARD}/revisions -s | jq ".items[] | select(.description | contains(\"${VERSION}\")) | .revision" | tail -n 1)"
$     curl -s https://grafana.com/api/dashboards/${DASHBOARD}/revisions/${REVISION}/download > /tmp/dashboard.json
$     echo "Імпорт $(cat /tmp/dashboard.json | jq -r '.title') (revision ${REVISION}, id ${DASHBOARD})..."
$     curl -s -k -u "$GRAFANA_CRED" -XPOST \
$         -H "Accept: application/json" \
$         -H "Content-Type: application/json" \
$         -d "{\"dashboard\":$(cat /tmp/dashboard.json),\"overwrite\":true, \
$             \"inputs\":[{\"name\":\"DS_PROMETHEUS\",\"type\":\"datasource\", \
$             \"pluginId\":\"prometheus\",\"value\":\"$GRAFANA_DATASOURCE\"}]}" \
$         $GRAFANA_HOST/api/dashboards/import
$     echo -e "\nГотово\n"
$ done
{{< /text >}}

{{< tip >}}
Нова ревізія інфопанелей створюється для кожної версії Istio. Щоб забезпечити сумісність, рекомендується вибрати відповідну ревізію для версії Istio, яку ви розгортаєте.
{{< /tip >}}

### Варіант 3: Методи, специфічні для реалізації {#option-3-implementation-specific-methods}

Grafana може бути встановлена та налаштована іншими методами. Для імпорту панелей управління Istio, ознайомтеся з документацією для методу встановлення. Наприклад:

* Офіційна документація [Provisioning Grafana](https://grafana.com/docs/grafana/latest/administration/provisioning/#dashboards).
* [Імпорт інфопанелей](https://github.com/grafana/helm-charts/tree/main/charts/grafana#import-dashboards) для Helm chart `stable/grafana`.
